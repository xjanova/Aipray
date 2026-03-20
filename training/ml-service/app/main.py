"""FastAPI ML Service for Aipray Thai Chanting AI Training."""

import logging
import os
import threading
import traceback
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, File, Form, HTTPException, Header, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from .config import (
    API_HOST,
    API_PORT,
    LARAVEL_API_SECRET,
    LARAVEL_STORAGE_PATH,
    MODELS_DIR,
)
from .inference import InferenceEngine
from .trainer import WhisperTrainer, get_device

# Thread-safe lock for active_trainers dict
_trainers_lock = threading.Lock()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Aipray ML Service",
    description="AI Audio Training & Inference for Thai Buddhist Chanting",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global state
inference_engine = InferenceEngine()
active_trainers: dict[int, WhisperTrainer] = {}


def verify_secret(authorization: Optional[str] = None) -> bool:
    if not authorization:
        return False
    token = authorization.replace("Bearer ", "")
    return token == LARAVEL_API_SECRET


def _safe_resolve_path(file_path: str, allowed_bases: list[Path]) -> Path:
    """Resolve a file path and ensure it's within allowed directories (prevent path traversal)."""
    resolved = Path(file_path).resolve()
    for base in allowed_bases:
        try:
            resolved.relative_to(base.resolve())
            return resolved
        except ValueError:
            continue
    raise HTTPException(403, f"Access denied: path outside allowed directories")


# --- Pydantic Models ---

class TrainRequest(BaseModel):
    job_id: int
    base_model: str = "whisper-base"
    learning_rate: float = 1e-5
    batch_size: int = 8
    epochs: int = 10
    optimizer: str = "adamw"
    train_split: float = 0.8
    augmentation: dict = {}
    samples: list[dict] = []


class TranscribeResponse(BaseModel):
    text: str
    language: str
    model_id: str
    latency_ms: float
    audio_duration: float


class HealthResponse(BaseModel):
    status: str
    device: str
    models_loaded: int
    active_training_jobs: int


# --- Health & Info ---

@app.get("/health", response_model=HealthResponse)
async def health_check():
    device = str(get_device())
    return HealthResponse(
        status="ok",
        device=device,
        models_loaded=len(inference_engine.get_loaded_models()),
        active_training_jobs=len(active_trainers),
    )


@app.get("/models")
async def list_models():
    """List all available models (loaded + saved on disk)."""
    loaded = inference_engine.get_loaded_models()

    saved = []
    if MODELS_DIR.exists():
        for p in MODELS_DIR.iterdir():
            if p.is_dir() and (p / "config.json").exists():
                config_file = p / "training_config.json"
                config = {}
                if config_file.exists():
                    import json
                    config = json.loads(config_file.read_text())
                saved.append({
                    "name": p.name,
                    "path": str(p),
                    "config": config,
                    "size_mb": round(sum(f.stat().st_size for f in p.rglob("*") if f.is_file()) / 1048576, 1),
                })

    return {"loaded": loaded, "saved": saved}


# --- Training ---

@app.post("/train/start")
async def start_training(
    request: TrainRequest,
    authorization: str = Header(None),
):
    """Start a real training job in the background."""
    if not verify_secret(authorization):
        raise HTTPException(401, "Unauthorized")

    with _trainers_lock:
        if request.job_id in active_trainers:
            raise HTTPException(409, f"Training job {request.job_id} is already running")

    if not request.samples:
        raise HTTPException(400, "No training samples provided")

    def run_training():
        try:
            from .dataset import prepare_dataset_from_db

            trainer = WhisperTrainer(
                base_model=request.base_model,
                learning_rate=request.learning_rate,
                batch_size=request.batch_size,
                epochs=request.epochs,
                optimizer_name=request.optimizer,
                job_id=request.job_id,
            )
            with _trainers_lock:
                active_trainers[request.job_id] = trainer

            train_dataset, val_dataset = prepare_dataset_from_db(
                samples_data=request.samples,
                audio_base_path=str(LARAVEL_STORAGE_PATH),
                processor=trainer.processor,
                train_split=request.train_split,
                augmentation=request.augmentation,
            )

            result = trainer.train(train_dataset, val_dataset)
            logger.info(f"Training job {request.job_id} completed: {result['status']}")

        except Exception as e:
            logger.error(f"Training job {request.job_id} failed: {e}\n{traceback.format_exc()}")
            from .trainer import notify_laravel
            notify_laravel(request.job_id, {
                "status": "failed",
                "log": f"Training failed: {str(e)}\n{traceback.format_exc()}",
            })
        finally:
            with _trainers_lock:
                active_trainers.pop(request.job_id, None)

    thread = threading.Thread(target=run_training, daemon=True)
    thread.start()

    return {"message": "Training started", "job_id": request.job_id}


@app.post("/train/{job_id}/pause")
async def pause_training(job_id: int, authorization: str = Header(None)):
    if not verify_secret(authorization):
        raise HTTPException(401, "Unauthorized")
    with _trainers_lock:
        trainer = active_trainers.get(job_id)
    if not trainer:
        raise HTTPException(404, "Training job not found")
    trainer.pause()
    return {"message": "Training paused"}


@app.post("/train/{job_id}/resume")
async def resume_training(job_id: int, authorization: str = Header(None)):
    if not verify_secret(authorization):
        raise HTTPException(401, "Unauthorized")
    with _trainers_lock:
        trainer = active_trainers.get(job_id)
    if not trainer:
        raise HTTPException(404, "Training job not found")
    trainer.resume()
    return {"message": "Training resumed"}


@app.post("/train/{job_id}/cancel")
async def cancel_training(job_id: int, authorization: str = Header(None)):
    if not verify_secret(authorization):
        raise HTTPException(401, "Unauthorized")
    with _trainers_lock:
        trainer = active_trainers.get(job_id)
    if not trainer:
        raise HTTPException(404, "Training job not found")
    trainer.cancel()
    return {"message": "Training cancellation requested"}


@app.get("/train/status")
async def training_status():
    """Get status of all active training jobs."""
    return {
        "active_jobs": list(active_trainers.keys()),
        "count": len(active_trainers),
    }


# --- Inference ---

@app.post("/transcribe/file", response_model=TranscribeResponse)
async def transcribe_file(
    audio: UploadFile = File(...),
    model_id: str = Form("default"),
    language: str = Form("th"),
):
    """Transcribe an uploaded audio file."""
    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(400, "Empty audio file")

    try:
        # Auto-load base model if no model loaded
        if not inference_engine.get_loaded_models():
            inference_engine.load_base_model("whisper-base")
            model_id = "whisper-base"

        result = inference_engine.transcribe_bytes(audio_bytes, model_id, language)
        return TranscribeResponse(**result)
    except ValueError as e:
        raise HTTPException(400, str(e))
    except Exception as e:
        logger.error(f"Transcription failed: {e}")
        raise HTTPException(500, f"Transcription failed: {str(e)}")


@app.post("/transcribe/path")
async def transcribe_path(
    file_path: str = Form(...),
    model_id: str = Form("default"),
    language: str = Form("th"),
    authorization: str = Header(None),
):
    """Transcribe audio from a file path on the server."""
    if not verify_secret(authorization):
        raise HTTPException(401, "Unauthorized")

    # Validate path is within allowed directories
    safe_path = _safe_resolve_path(file_path, [LARAVEL_STORAGE_PATH, MODELS_DIR])

    if not safe_path.exists():
        raise HTTPException(404, f"File not found")

    try:
        if not inference_engine.get_loaded_models():
            inference_engine.load_base_model("whisper-base")
            model_id = "whisper-base"

        result = inference_engine.transcribe_file(str(safe_path), model_id, language)
        return result
    except Exception as e:
        logger.error(f"Transcription failed: {e}")
        raise HTTPException(500, f"Transcription failed: {str(e)}")


# --- Model Management ---

@app.post("/models/load")
async def load_model(
    model_path: str = Form(...),
    model_id: str = Form("default"),
    authorization: str = Header(None),
):
    """Load a trained model for inference."""
    if not verify_secret(authorization):
        raise HTTPException(401, "Unauthorized")

    try:
        inference_engine.load_model(model_path, model_id)
        return {"message": f"Model '{model_id}' loaded from {model_path}"}
    except Exception as e:
        raise HTTPException(500, f"Failed to load model: {str(e)}")


@app.post("/models/load-base")
async def load_base_model(
    base_model: str = Form("whisper-base"),
    authorization: str = Header(None),
):
    """Load a base Whisper model."""
    if not verify_secret(authorization):
        raise HTTPException(401, "Unauthorized")

    try:
        inference_engine.load_base_model(base_model)
        return {"message": f"Base model '{base_model}' loaded"}
    except Exception as e:
        raise HTTPException(500, f"Failed to load model: {str(e)}")


@app.post("/models/{model_id}/unload")
async def unload_model(model_id: str, authorization: str = Header(None)):
    if not verify_secret(authorization):
        raise HTTPException(401, "Unauthorized")
    inference_engine.unload_model(model_id)
    return {"message": f"Model '{model_id}' unloaded"}


@app.post("/models/export-onnx")
async def export_onnx(
    model_path: str = Form(...),
    output_path: str = Form(None),
    authorization: str = Header(None),
):
    """Export a model to ONNX format."""
    if not verify_secret(authorization):
        raise HTTPException(401, "Unauthorized")

    try:
        from .trainer import WhisperTrainer
        # Determine base model from config
        import json
        config_file = Path(model_path) / "training_config.json"
        base_model = "whisper-base"
        if config_file.exists():
            config = json.loads(config_file.read_text())
            base_model = config.get("base_model", base_model)

        trainer = WhisperTrainer(base_model=base_model)
        onnx_path = trainer.export_onnx(output_path)
        return {"message": "ONNX export successful", "path": str(onnx_path)}
    except Exception as e:
        raise HTTPException(500, f"ONNX export failed: {str(e)}")


# --- Evaluation ---

@app.post("/evaluate")
async def evaluate_audio(
    audio: UploadFile = File(...),
    reference_text: str = Form(""),
    model_id: str = Form("default"),
    authorization: str = Header(None),
):
    """Evaluate model accuracy against reference text."""
    if not verify_secret(authorization):
        raise HTTPException(401, "Unauthorized")

    audio_bytes = await audio.read()
    try:
        if not inference_engine.get_loaded_models():
            inference_engine.load_base_model("whisper-base")
            model_id = "whisper-base"

        result = inference_engine.transcribe_bytes(audio_bytes, model_id)

        # Compute WER/CER
        from jiwer import wer as compute_wer, cer as compute_cer

        recognized = result["text"]
        if reference_text.strip():
            wer_score = compute_wer(reference_text, recognized) * 100
            cer_score = compute_cer(reference_text, recognized) * 100
        else:
            wer_score = 0.0
            cer_score = 0.0

        return {
            "recognized_text": recognized,
            "reference_text": reference_text,
            "wer": round(wer_score, 2),
            "cer": round(cer_score, 2),
            "accuracy": round(max(0, 100 - wer_score), 2),
            "latency_ms": result["latency_ms"],
        }
    except Exception as e:
        raise HTTPException(500, f"Evaluation failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=API_HOST, port=API_PORT)
