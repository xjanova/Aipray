"""Audio preprocessing utilities for Thai chanting recognition."""

import io
import logging
from pathlib import Path
from typing import Optional

import librosa
import numpy as np
import soundfile as sf
import torch
import torchaudio
from pydub import AudioSegment

from .config import DEFAULT_SAMPLE_RATE, MAX_AUDIO_LENGTH_SEC

logger = logging.getLogger(__name__)


def load_audio(file_path: str | Path, target_sr: int = DEFAULT_SAMPLE_RATE) -> np.ndarray:
    """Load audio file and resample to target sample rate."""
    file_path = Path(file_path)

    if not file_path.exists():
        raise FileNotFoundError(f"Audio file not found: {file_path}")

    try:
        waveform, sr = torchaudio.load(str(file_path))
        if waveform.shape[0] > 1:
            waveform = torch.mean(waveform, dim=0, keepdim=True)
        if sr != target_sr:
            resampler = torchaudio.transforms.Resample(sr, target_sr)
            waveform = resampler(waveform)
        return waveform.squeeze().numpy()
    except Exception:
        # Fallback to librosa
        audio, _ = librosa.load(str(file_path), sr=target_sr, mono=True)
        return audio


def load_audio_from_bytes(audio_bytes: bytes, target_sr: int = DEFAULT_SAMPLE_RATE) -> np.ndarray:
    """Load audio from bytes (for API uploads)."""
    try:
        audio_segment = AudioSegment.from_file(io.BytesIO(audio_bytes))
        audio_segment = audio_segment.set_channels(1).set_frame_rate(target_sr)
        samples = np.array(audio_segment.get_array_of_samples(), dtype=np.float32)
        samples = samples / np.iinfo(np.int16).max
        return samples
    except Exception:
        buf = io.BytesIO(audio_bytes)
        audio, _ = librosa.load(buf, sr=target_sr, mono=True)
        return audio


def preprocess_audio(audio: np.ndarray, sr: int = DEFAULT_SAMPLE_RATE) -> np.ndarray:
    """Preprocess audio for Whisper: normalize, trim silence, limit length."""
    # Trim silence
    audio_trimmed, _ = librosa.effects.trim(audio, top_db=30)

    # Limit length
    max_samples = MAX_AUDIO_LENGTH_SEC * sr
    if len(audio_trimmed) > max_samples:
        audio_trimmed = audio_trimmed[:max_samples]

    # Normalize
    max_val = np.abs(audio_trimmed).max()
    if max_val > 0:
        audio_trimmed = audio_trimmed / max_val

    return audio_trimmed


def augment_audio(
    audio: np.ndarray,
    sr: int = DEFAULT_SAMPLE_RATE,
    noise: bool = False,
    speed: bool = False,
    pitch: bool = False,
) -> np.ndarray:
    """Apply data augmentation to audio."""
    augmented = audio.copy()

    if noise:
        noise_level = np.random.uniform(0.001, 0.01)
        augmented = augmented + noise_level * np.random.randn(len(augmented)).astype(np.float32)

    if speed:
        rate = np.random.uniform(0.9, 1.1)
        augmented = librosa.effects.time_stretch(augmented, rate=rate)

    if pitch:
        n_steps = np.random.uniform(-2, 2)
        augmented = librosa.effects.pitch_shift(augmented, sr=sr, n_steps=n_steps)

    return augmented


def compute_mel_spectrogram(
    audio: np.ndarray,
    sr: int = DEFAULT_SAMPLE_RATE,
    n_mels: int = 80,
    n_fft: int = 400,
    hop_length: int = 160,
) -> np.ndarray:
    """Compute log-mel spectrogram (Whisper-compatible)."""
    mel = librosa.feature.melspectrogram(
        y=audio, sr=sr, n_mels=n_mels, n_fft=n_fft, hop_length=hop_length
    )
    log_mel = librosa.power_to_db(mel, ref=np.max)
    return log_mel


def get_audio_info(file_path: str | Path) -> dict:
    """Get audio file metadata."""
    file_path = Path(file_path)
    info = sf.info(str(file_path))
    return {
        "duration": info.duration,
        "sample_rate": info.samplerate,
        "channels": info.channels,
        "format": info.format,
        "subtype": info.subtype,
        "frames": info.frames,
    }


def split_audio_segments(
    audio: np.ndarray,
    sr: int = DEFAULT_SAMPLE_RATE,
    min_silence_len: int = 500,
    silence_thresh: int = -40,
) -> list[np.ndarray]:
    """Split audio into segments at silence points."""
    # Convert to pydub format for silence detection
    audio_int16 = (audio * np.iinfo(np.int16).max).astype(np.int16)
    audio_segment = AudioSegment(
        audio_int16.tobytes(),
        frame_rate=sr,
        sample_width=2,
        channels=1,
    )

    from pydub.silence import split_on_silence
    chunks = split_on_silence(
        audio_segment,
        min_silence_len=min_silence_len,
        silence_thresh=silence_thresh,
        keep_silence=200,
    )

    segments = []
    for chunk in chunks:
        samples = np.array(chunk.get_array_of_samples(), dtype=np.float32)
        samples = samples / np.iinfo(np.int16).max
        segments.append(samples)

    return segments
