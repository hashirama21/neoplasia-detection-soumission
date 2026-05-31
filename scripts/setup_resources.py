"""
setup_resources.py — Copy trained weights from extracted outputs zip into resources/.

Usage (CI or local):
    python scripts/setup_resources.py --extracted_dir outputs_extracted

Expected input layout (from outputs.zip):
    outputs_extracted/root/outputs/
        seed_42/checkpoints/epoch_002_val_ppv_1.0000.pt
        seed_123/checkpoints/epoch_001_val_ppv_1.0000.pt
        seed_456/checkpoints/epoch_003_val_ppv_1.0000.pt
        seed_789/checkpoints/epoch_001_val_ppv_1.0000.pt
        seed_1337/checkpoints/epoch_002_val_ppv_1.0000.pt
        ensemble/results/isotonic_calibrator.pkl
        ensemble/results/calibration_results.json
"""

import argparse
import shutil
import sys
from pathlib import Path

SEED_MAP = {
    "seed_42":   "epoch_002_val_ppv_1.0000.pt",
    "seed_123":  "epoch_001_val_ppv_1.0000.pt",
    "seed_456":  "epoch_003_val_ppv_1.0000.pt",
    "seed_789":  "epoch_001_val_ppv_1.0000.pt",
    "seed_1337": "epoch_002_val_ppv_1.0000.pt",
}

CALIBRATION_FILES = [
    "isotonic_calibrator.pkl",
    "calibration_results.json",
]


def setup(extracted_dir: str, dest_dir: str = "resources") -> None:
    base    = Path(extracted_dir)
    dest    = Path(dest_dir)
    cal_src = base / "root" / "outputs" / "ensemble" / "results"

    # Try alternate root layouts
    for candidate in [
        base / "root" / "outputs",
        base / "outputs",
        base,
    ]:
        if (candidate / "seed_42").exists():
            base = candidate
            cal_src = base / "ensemble" / "results"
            break

    (dest / "calibration").mkdir(parents=True, exist_ok=True)

    # Copy seed checkpoints
    for seed, ckpt_name in SEED_MAP.items():
        src = base / seed / "checkpoints" / ckpt_name
        if not src.exists():
            print(f"ERROR: {src} not found", file=sys.stderr)
            sys.exit(1)
        dst = dest / f"{seed}.pt"
        shutil.copy(src, dst)
        size_mb = dst.stat().st_size / 1e6
        print(f"  {seed}.pt  ({size_mb:.0f} MB)")

    # Copy calibration artifacts
    for fname in CALIBRATION_FILES:
        src = cal_src / fname
        if not src.exists():
            print(f"ERROR: {src} not found", file=sys.stderr)
            sys.exit(1)
        shutil.copy(src, dest / "calibration" / fname)
        print(f"  calibration/{fname}")

    print(f"\nresources/ ready — 5 checkpoints + calibration artifacts")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--extracted_dir", default="outputs_extracted",
                        help="Directory where outputs.zip was extracted")
    parser.add_argument("--dest_dir", default="resources",
                        help="Destination resources/ directory")
    args = parser.parse_args()
    setup(args.extracted_dir, args.dest_dir)
