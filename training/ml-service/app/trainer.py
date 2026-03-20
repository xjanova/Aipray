"""Real Whisper fine-tuning trainer for Thai chanting recognition."""

import json
import logging
import time
import traceback
from pathlib import Path
from typing import Optional

import httpx
import numpy as np
import torch
from torch.utils.data import DataLoader
from transformers import (
    WhisperForConditionalGeneration,
    WhisperProcessor,
    get_linear_schedule_with_warmup,
)

from .config import (
    CACHE_DIR,
    DEVICE,
    LARAVEL_API_SECRET,
    LARAVEL_BASE_URL,
    MODELS_DIR,
    WHISPER_MODELS,
    DEFAULT_WARMUP_STEPS,
)
from .dataset import ChantingDataset, DataCollatorSpeechSeq2Seq

logger = logging.getLogger(__name__)


def get_device() -> torch.device:
    """Determine the best available device."""
    if DEVICE == "auto":
        if torch.cuda.is_available():
            return torch.device("cuda")
        return torch.device("cpu")
    return torch.device(DEVICE)


def notify_laravel(job_id: int, data: dict) -> None:
    """Send training progress update to Laravel."""
    try:
        httpx.post(
            f"{LARAVEL_BASE_URL}/api/ml/training-callback",
            json={"job_id": job_id, **data},
            headers={"Authorization": f"Bearer {LARAVEL_API_SECRET}"},
            timeout=10,
        )
    except Exception as e:
        logger.warning(f"Failed to notify Laravel: {e}")


class WhisperTrainer:
    """Fine-tune Whisper model for Thai Buddhist chanting."""

    def __init__(
        self,
        base_model: str,
        learning_rate: float = 1e-5,
        batch_size: int = 8,
        epochs: int = 10,
        optimizer_name: str = "adamw",
        warmup_steps: int = DEFAULT_WARMUP_STEPS,
        job_id: Optional[int] = None,
    ):
        self.device = get_device()
        self.base_model = base_model
        self.model_name = WHISPER_MODELS.get(base_model, WHISPER_MODELS["whisper-base"])
        self.learning_rate = learning_rate
        self.batch_size = batch_size
        self.epochs = epochs
        self.optimizer_name = optimizer_name
        self.warmup_steps = warmup_steps
        self.job_id = job_id

        self._cancelled = False
        self._paused = False

        logger.info(f"Initializing trainer: model={self.model_name}, device={self.device}")

        # Load model and processor
        self.processor = WhisperProcessor.from_pretrained(
            self.model_name, cache_dir=str(CACHE_DIR)
        )
        self.model = WhisperForConditionalGeneration.from_pretrained(
            self.model_name, cache_dir=str(CACHE_DIR)
        )

        # Configure for Thai language
        self.model.config.forced_decoder_ids = self.processor.get_decoder_prompt_ids(
            language="th", task="transcribe"
        )
        self.model.config.suppress_tokens = []

        self.model.to(self.device)

    def cancel(self):
        self._cancelled = True

    def pause(self):
        self._paused = True

    def resume(self):
        self._paused = False

    def train(
        self,
        train_dataset: ChantingDataset,
        val_dataset: ChantingDataset,
    ) -> dict:
        """Run the full training loop."""
        logger.info(f"Starting training: {len(train_dataset)} train, {len(val_dataset)} val")

        data_collator = DataCollatorSpeechSeq2Seq(
            self.processor,
            decoder_start_token_id=self.model.config.decoder_start_token_id,
        )

        train_loader = DataLoader(
            train_dataset,
            batch_size=self.batch_size,
            shuffle=True,
            collate_fn=data_collator,
            num_workers=0,
            pin_memory=self.device.type == "cuda",
        )

        val_loader = DataLoader(
            val_dataset,
            batch_size=self.batch_size,
            shuffle=False,
            collate_fn=data_collator,
            num_workers=0,
        )

        # Setup optimizer
        optimizer = self._create_optimizer()
        total_steps = len(train_loader) * self.epochs
        scheduler = get_linear_schedule_with_warmup(
            optimizer,
            num_warmup_steps=min(self.warmup_steps, total_steps // 5),
            num_training_steps=total_steps,
        )

        # Training state
        loss_history = []
        metrics_history = []
        best_val_loss = float("inf")
        best_model_path = None
        log_lines = [f"=== Training Started ===", f"Model: {self.model_name}", f"Device: {self.device}"]

        start_time = time.time()

        for epoch in range(1, self.epochs + 1):
            if self._cancelled:
                log_lines.append(f"\n=== Training Cancelled at epoch {epoch} ===")
                break

            while self._paused:
                time.sleep(1)
                if self._cancelled:
                    break

            # Training phase
            self.model.train()
            train_losses = []

            for step, batch in enumerate(train_loader):
                if self._cancelled:
                    break

                batch = {k: v.to(self.device) for k, v in batch.items()}

                outputs = self.model(**batch)
                loss = outputs.loss

                loss.backward()
                torch.nn.utils.clip_grad_norm_(self.model.parameters(), max_norm=1.0)
                optimizer.step()
                scheduler.step()
                optimizer.zero_grad()

                train_losses.append(loss.item())

                # Log every 10 steps
                if (step + 1) % 10 == 0:
                    avg_loss = np.mean(train_losses[-10:])
                    logger.info(f"Epoch {epoch}, Step {step+1}/{len(train_loader)}, Loss: {avg_loss:.4f}")

            if self._cancelled:
                break

            # Validation phase
            avg_train_loss = float(np.mean(train_losses)) if train_losses else 0.0
            val_loss, val_metrics = self._validate(val_loader)

            loss_history.append({
                "epoch": epoch,
                "train": round(avg_train_loss, 4),
                "val": round(val_loss, 4),
            })
            metrics_history.append({
                "epoch": epoch,
                "wer": round(val_metrics["wer"], 2),
                "cer": round(val_metrics["cer"], 2),
                "accuracy": round(val_metrics["accuracy"], 2),
            })

            elapsed = time.time() - start_time
            log_line = (
                f"\n[Epoch {epoch}/{self.epochs}] "
                f"loss={avg_train_loss:.4f} val_loss={val_loss:.4f} "
                f"WER={val_metrics['wer']:.2f}% CER={val_metrics['cer']:.2f}% "
                f"acc={val_metrics['accuracy']:.2f}% "
                f"time={elapsed:.0f}s"
            )
            log_lines.append(log_line)
            logger.info(log_line)

            # Save best model
            if val_loss < best_val_loss:
                best_val_loss = val_loss
                best_model_path = self._save_checkpoint(epoch, val_loss)
                log_lines.append(f"  -> Best model saved: {best_model_path}")

            # Notify Laravel of progress
            if self.job_id:
                notify_laravel(self.job_id, {
                    "status": "running",
                    "current_epoch": epoch,
                    "training_loss": round(avg_train_loss, 4),
                    "validation_loss": round(val_loss, 4),
                    "wer": round(val_metrics["wer"], 2),
                    "cer": round(val_metrics["cer"], 2),
                    "accuracy": round(val_metrics["accuracy"], 2),
                    "loss_history": loss_history,
                    "metrics_history": metrics_history,
                    "log": "\n".join(log_lines),
                    "elapsed": round(elapsed),
                })

        # Save final model
        final_path = self._save_final_model()
        total_time = time.time() - start_time
        log_lines.append(f"\n=== Training Complete ===")
        log_lines.append(f"Total time: {total_time:.0f}s")
        log_lines.append(f"Best val loss: {best_val_loss:.4f}")
        log_lines.append(f"Model saved: {final_path}")

        result = {
            "status": "cancelled" if self._cancelled else "completed",
            "model_path": str(final_path),
            "best_model_path": str(best_model_path) if best_model_path else str(final_path),
            "loss_history": loss_history,
            "metrics_history": metrics_history,
            "final_metrics": metrics_history[-1] if metrics_history else {},
            "total_time": round(total_time),
            "log": "\n".join(log_lines),
        }

        # Final notification to Laravel
        if self.job_id:
            notify_laravel(self.job_id, {
                **result,
                "current_epoch": self.epochs,
            })

        return result

    def _validate(self, val_loader: DataLoader) -> tuple[float, dict]:
        """Run validation and compute metrics."""
        self.model.eval()
        val_losses = []
        all_predictions = []
        all_references = []

        with torch.no_grad():
            for batch in val_loader:
                batch_device = {k: v.to(self.device) for k, v in batch.items()}

                outputs = self.model(**batch_device)
                val_losses.append(outputs.loss.item())

                # Generate predictions for WER/CER
                predicted_ids = self.model.generate(
                    batch_device["input_features"],
                    max_new_tokens=225,
                    language="th",
                    task="transcribe",
                )

                predictions = self.processor.batch_decode(predicted_ids, skip_special_tokens=True)
                all_predictions.extend(predictions)

                # Decode reference labels
                labels = batch["labels"]
                labels[labels == -100] = self.processor.tokenizer.pad_token_id
                references = self.processor.batch_decode(labels, skip_special_tokens=True)
                all_references.extend(references)

        avg_val_loss = float(np.mean(val_losses)) if val_losses else 0.0
        metrics = self._compute_metrics(all_predictions, all_references)

        return avg_val_loss, metrics

    def _compute_metrics(self, predictions: list[str], references: list[str]) -> dict:
        """Compute WER, CER, and accuracy."""
        try:
            from jiwer import wer as compute_wer, cer as compute_cer

            # Filter out empty pairs
            valid_pairs = [
                (p, r) for p, r in zip(predictions, references) if r.strip()
            ]
            if not valid_pairs:
                return {"wer": 100.0, "cer": 100.0, "accuracy": 0.0}

            preds, refs = zip(*valid_pairs)
            preds, refs = list(preds), list(refs)

            wer_score = compute_wer(refs, preds) * 100
            cer_score = compute_cer(refs, preds) * 100
            accuracy = max(0, 100 - wer_score)

            return {
                "wer": min(wer_score, 100.0),
                "cer": min(cer_score, 100.0),
                "accuracy": accuracy,
            }
        except Exception as e:
            logger.warning(f"Metrics computation failed: {e}")
            return {"wer": 100.0, "cer": 100.0, "accuracy": 0.0}

    def _create_optimizer(self):
        """Create optimizer based on config."""
        params = self.model.parameters()
        if self.optimizer_name == "adamw":
            return torch.optim.AdamW(params, lr=self.learning_rate, weight_decay=0.01)
        elif self.optimizer_name == "adam":
            return torch.optim.Adam(params, lr=self.learning_rate)
        elif self.optimizer_name == "sgd":
            return torch.optim.SGD(params, lr=self.learning_rate, momentum=0.9)
        return torch.optim.AdamW(params, lr=self.learning_rate)

    def _save_checkpoint(self, epoch: int, val_loss: float) -> Path:
        """Save model checkpoint."""
        checkpoint_dir = MODELS_DIR / f"checkpoint-epoch{epoch}-loss{val_loss:.4f}"
        checkpoint_dir.mkdir(parents=True, exist_ok=True)
        self.model.save_pretrained(str(checkpoint_dir))
        self.processor.save_pretrained(str(checkpoint_dir))
        return checkpoint_dir

    def _save_final_model(self) -> Path:
        """Save the final trained model."""
        job_suffix = f"-job{self.job_id}" if self.job_id else ""
        model_dir = MODELS_DIR / f"aipray-{self.base_model}{job_suffix}-final"
        model_dir.mkdir(parents=True, exist_ok=True)
        self.model.save_pretrained(str(model_dir))
        self.processor.save_pretrained(str(model_dir))

        # Save training config
        config = {
            "base_model": self.base_model,
            "model_name": self.model_name,
            "learning_rate": self.learning_rate,
            "batch_size": self.batch_size,
            "epochs": self.epochs,
            "optimizer": self.optimizer_name,
        }
        (model_dir / "training_config.json").write_text(json.dumps(config, indent=2))

        return model_dir

    def export_onnx(self, output_path: Optional[str] = None) -> Path:
        """Export model to ONNX format for deployment."""
        if output_path is None:
            output_path = MODELS_DIR / f"aipray-{self.base_model}-onnx"

        output_path = Path(output_path)
        output_path.mkdir(parents=True, exist_ok=True)

        try:
            from optimum.onnxruntime import ORTModelForSpeechSeq2Seq

            ort_model = ORTModelForSpeechSeq2Seq.from_pretrained(
                self.model.name_or_path if hasattr(self.model, 'name_or_path') else str(MODELS_DIR / f"aipray-{self.base_model}-final"),
                export=True,
            )
            ort_model.save_pretrained(str(output_path))
            self.processor.save_pretrained(str(output_path))
            logger.info(f"ONNX model exported to {output_path}")
        except Exception as e:
            logger.error(f"ONNX export failed: {e}")
            raise

        return output_path
