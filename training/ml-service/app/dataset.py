"""Dataset management for Thai chanting audio training."""

import json
import logging
from pathlib import Path
from typing import Optional

import numpy as np
import torch
from torch.utils.data import Dataset
from transformers import WhisperProcessor

from .audio_utils import load_audio, preprocess_audio, augment_audio
from .config import DEFAULT_SAMPLE_RATE

logger = logging.getLogger(__name__)


class ChantingDataset(Dataset):
    """Dataset for Thai Buddhist chanting audio samples."""

    def __init__(
        self,
        samples: list[dict],
        processor: WhisperProcessor,
        sr: int = DEFAULT_SAMPLE_RATE,
        augmentation: Optional[dict] = None,
    ):
        self.samples = [s for s in samples if s.get("transcript") or s.get("label")]
        self.processor = processor
        self.sr = sr
        self.augmentation = augmentation or {}
        logger.info(f"ChantingDataset initialized with {len(self.samples)} samples")

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> dict:
        sample = self.samples[idx]
        file_path = sample["file_path"]
        transcript = sample.get("transcript") or sample.get("label", "")

        try:
            audio = load_audio(file_path, self.sr)
            audio = preprocess_audio(audio, self.sr)

            # Apply augmentation
            if self.augmentation:
                audio = augment_audio(
                    audio,
                    sr=self.sr,
                    noise=self.augmentation.get("noise", False),
                    speed=self.augmentation.get("speed", False),
                    pitch=self.augmentation.get("pitch", False),
                )

            # Process for Whisper
            input_features = self.processor(
                audio, sampling_rate=self.sr, return_tensors="pt"
            ).input_features.squeeze(0)

            # Tokenize transcript
            labels = self.processor.tokenizer(
                transcript,
                return_tensors="pt",
                padding=False,
            ).input_ids.squeeze(0)

            return {
                "input_features": input_features,
                "labels": labels,
            }

        except Exception as e:
            logger.warning(f"Error loading sample {file_path}: {e}")
            # Return a dummy sample on error
            dummy_audio = np.zeros(self.sr, dtype=np.float32)
            input_features = self.processor(
                dummy_audio, sampling_rate=self.sr, return_tensors="pt"
            ).input_features.squeeze(0)
            labels = self.processor.tokenizer(
                "", return_tensors="pt", padding=False
            ).input_ids.squeeze(0)
            return {"input_features": input_features, "labels": labels}


class DataCollatorSpeechSeq2Seq:
    """Data collator for Whisper fine-tuning with padding."""

    def __init__(self, processor: WhisperProcessor, decoder_start_token_id: int):
        self.processor = processor
        self.decoder_start_token_id = decoder_start_token_id

    def __call__(self, features: list[dict]) -> dict:
        input_features = [f["input_features"] for f in features]
        label_features = [f["labels"] for f in features]

        # Pad input features
        batch = self.processor.feature_extractor.pad(
            [{"input_features": f} for f in input_features],
            return_tensors="pt",
        )

        # Pad labels
        labels_batch = self.processor.tokenizer.pad(
            [{"input_ids": l} for l in label_features],
            return_tensors="pt",
        )

        # Replace padding token id with -100 for loss computation
        labels = labels_batch["input_ids"].masked_fill(
            labels_batch.attention_mask.ne(1), -100
        )

        # Remove BOS token if present
        if (labels[:, 0] == self.decoder_start_token_id).all().cpu().item():
            labels = labels[:, 1:]

        batch["labels"] = labels
        return batch


def prepare_dataset_from_db(
    samples_data: list[dict],
    audio_base_path: str | Path,
    processor: WhisperProcessor,
    train_split: float = 0.8,
    augmentation: Optional[dict] = None,
) -> tuple["ChantingDataset", "ChantingDataset"]:
    """Prepare train/val datasets from database records."""
    audio_base_path = Path(audio_base_path)

    # Resolve file paths
    resolved_samples = []
    for s in samples_data:
        file_path = audio_base_path / s.get("filename", "")
        if not file_path.exists():
            file_path = Path(s.get("file_path", ""))
        if file_path.exists() and (s.get("transcript") or s.get("label")):
            resolved_samples.append({**s, "file_path": str(file_path)})

    if not resolved_samples:
        raise ValueError("No valid audio samples with transcripts found")

    # Shuffle and split
    np.random.shuffle(resolved_samples)
    split_idx = int(len(resolved_samples) * train_split)
    train_samples = resolved_samples[:split_idx]
    val_samples = resolved_samples[split_idx:]

    logger.info(f"Dataset split: {len(train_samples)} train, {len(val_samples)} val")

    train_dataset = ChantingDataset(train_samples, processor, augmentation=augmentation)
    val_dataset = ChantingDataset(val_samples, processor)

    return train_dataset, val_dataset
