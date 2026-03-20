"""Configuration for ML service."""

import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

# Paths
BASE_DIR = Path(__file__).resolve().parent.parent
MODELS_DIR = BASE_DIR / "models"
DATA_DIR = BASE_DIR / "data"
CACHE_DIR = BASE_DIR / ".cache"

MODELS_DIR.mkdir(exist_ok=True)
DATA_DIR.mkdir(exist_ok=True)
CACHE_DIR.mkdir(exist_ok=True)

# Laravel storage path for audio samples
LARAVEL_STORAGE_PATH = Path(os.getenv(
    "LARAVEL_STORAGE_PATH",
    str(BASE_DIR.parent / "storage" / "app" / "public" / "audio_samples")
))

# ML settings
WHISPER_MODELS = {
    "whisper-tiny": "openai/whisper-tiny",
    "whisper-base": "openai/whisper-base",
    "whisper-small": "openai/whisper-small",
    "whisper-medium": "openai/whisper-medium",
}

DEFAULT_SAMPLE_RATE = 16000
MAX_AUDIO_LENGTH_SEC = 30

# Training defaults
DEFAULT_LEARNING_RATE = 1e-5
DEFAULT_BATCH_SIZE = 8
DEFAULT_EPOCHS = 10
DEFAULT_WARMUP_STEPS = 500

# API settings
API_HOST = os.getenv("ML_API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("ML_API_PORT", "8100"))

# Laravel callback
LARAVEL_BASE_URL = os.getenv("LARAVEL_BASE_URL", "http://localhost:8000")
LARAVEL_API_SECRET = os.getenv("LARAVEL_API_SECRET", "ml-service-secret-key")

# Redis/Celery
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# Device
DEVICE = os.getenv("ML_DEVICE", "auto")  # auto, cpu, cuda
