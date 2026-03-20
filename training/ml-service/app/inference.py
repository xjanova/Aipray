"""Real inference engine for Thai chanting speech recognition."""

import logging
import threading
import time
from pathlib import Path
from typing import Optional

import numpy as np
import torch

from .audio_utils import load_audio, load_audio_from_bytes, preprocess_audio
from .config import CACHE_DIR, DEFAULT_SAMPLE_RATE, MODELS_DIR, WHISPER_MODELS

logger = logging.getLogger(__name__)


class InferenceEngine:
    """Speech recognition inference using fine-tuned Whisper."""

    def __init__(self):
        self._models: dict[str, dict] = {}
        self._lock = threading.Lock()
        self._device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        logger.info(f"InferenceEngine initialized on {self._device}")

    def load_model(self, model_path: str, model_id: str = "default") -> None:
        """Load a fine-tuned model for inference."""
        from transformers import WhisperForConditionalGeneration, WhisperProcessor

        model_path = Path(model_path)
        if not model_path.exists():
            raise FileNotFoundError(f"Model not found: {model_path}")

        logger.info(f"Loading model from {model_path}")
        processor = WhisperProcessor.from_pretrained(str(model_path))
        model = WhisperForConditionalGeneration.from_pretrained(str(model_path))
        model.to(self._device)
        model.eval()

        with self._lock:
            if model_id in self._models:
                del self._models[model_id]
                if self._device.type == "cuda":
                    torch.cuda.empty_cache()

            self._models[model_id] = {
                "model": model,
                "processor": processor,
                "path": str(model_path),
            }
        logger.info(f"Model '{model_id}' loaded successfully")

    def load_base_model(self, base_model: str = "whisper-base") -> None:
        """Load a base Whisper model (not fine-tuned)."""
        from transformers import WhisperForConditionalGeneration, WhisperProcessor

        model_name = WHISPER_MODELS.get(base_model, WHISPER_MODELS["whisper-base"])
        logger.info(f"Loading base model: {model_name}")

        processor = WhisperProcessor.from_pretrained(model_name, cache_dir=str(CACHE_DIR))
        model = WhisperForConditionalGeneration.from_pretrained(model_name, cache_dir=str(CACHE_DIR))
        model.to(self._device)
        model.eval()

        with self._lock:
            if base_model in self._models:
                del self._models[base_model]
                if self._device.type == "cuda":
                    torch.cuda.empty_cache()

            self._models[base_model] = {
                "model": model,
                "processor": processor,
                "path": model_name,
            }

    def load_onnx_model(self, model_path: str, model_id: str = "onnx") -> None:
        """Load an ONNX model for faster inference."""
        try:
            from optimum.onnxruntime import ORTModelForSpeechSeq2Seq
            from transformers import WhisperProcessor

            model_path = Path(model_path)
            processor = WhisperProcessor.from_pretrained(str(model_path))
            model = ORTModelForSpeechSeq2Seq.from_pretrained(str(model_path))

            with self._lock:
                self._models[model_id] = {
                    "model": model,
                    "processor": processor,
                    "path": str(model_path),
                    "is_onnx": True,
                }
            logger.info(f"ONNX model '{model_id}' loaded")
        except Exception as e:
            logger.error(f"Failed to load ONNX model: {e}")
            raise

    def transcribe_file(
        self,
        file_path: str,
        model_id: str = "default",
        language: str = "th",
    ) -> dict:
        """Transcribe an audio file."""
        audio = load_audio(file_path)
        audio = preprocess_audio(audio)
        return self._transcribe(audio, model_id, language)

    def transcribe_bytes(
        self,
        audio_bytes: bytes,
        model_id: str = "default",
        language: str = "th",
    ) -> dict:
        """Transcribe audio from bytes."""
        audio = load_audio_from_bytes(audio_bytes)
        audio = preprocess_audio(audio)
        return self._transcribe(audio, model_id, language)

    def _transcribe(
        self,
        audio: np.ndarray,
        model_id: str = "default",
        language: str = "th",
    ) -> dict:
        """Internal transcription method."""
        with self._lock:
            model_info = self._models.get(model_id)
            if model_info is None:
                available = list(self._models.keys())
                raise ValueError(f"Model '{model_id}' not loaded. Available: {available}")
            # Hold references so model can't be unloaded during inference
            model = model_info["model"]
            processor = model_info["processor"]
            is_onnx = model_info.get("is_onnx", False)

        start_time = time.time()

        # Process audio
        input_features = processor(
            audio, sampling_rate=DEFAULT_SAMPLE_RATE, return_tensors="pt"
        ).input_features

        if not is_onnx:
            input_features = input_features.to(self._device)

        # Generate transcription
        with torch.no_grad():
            predicted_ids = model.generate(
                input_features,
                max_new_tokens=225,
                language=language,
                task="transcribe",
            )

        transcription = processor.batch_decode(predicted_ids, skip_special_tokens=True)[0]
        latency_ms = (time.time() - start_time) * 1000

        return {
            "text": transcription.strip(),
            "language": language,
            "model_id": model_id,
            "latency_ms": round(latency_ms, 1),
            "audio_duration": len(audio) / DEFAULT_SAMPLE_RATE,
        }

    def transcribe_segments(
        self,
        file_path: str,
        model_id: str = "default",
        language: str = "th",
    ) -> dict:
        """Transcribe audio file with segment-level timestamps."""
        from .audio_utils import split_audio_segments

        audio = load_audio(file_path)
        audio = preprocess_audio(audio)
        segments_audio = split_audio_segments(audio)

        segments = []
        full_text_parts = []
        offset = 0.0

        for i, seg_audio in enumerate(segments_audio):
            result = self._transcribe(seg_audio, model_id, language)
            duration = len(seg_audio) / DEFAULT_SAMPLE_RATE
            segments.append({
                "id": i,
                "start": round(offset, 2),
                "end": round(offset + duration, 2),
                "text": result["text"],
            })
            full_text_parts.append(result["text"])
            offset += duration

        return {
            "text": " ".join(full_text_parts),
            "segments": segments,
            "model_id": model_id,
            "language": language,
        }

    def get_loaded_models(self) -> list[dict]:
        """List all loaded models."""
        with self._lock:
            return [
                {"id": mid, "path": info["path"], "onnx": info.get("is_onnx", False)}
                for mid, info in self._models.items()
            ]

    def unload_model(self, model_id: str) -> None:
        """Unload a model to free memory."""
        with self._lock:
            if model_id in self._models:
                del self._models[model_id]
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        logger.info(f"Model '{model_id}' unloaded")
