# resources/ — Setup Instructions

Copy trained weights here before building the Docker image.
These files are NOT tracked by git (see .gitignore).

## Expected structure after setup

```
resources/
├── seed_42.pt
├── seed_123.pt
├── seed_456.pt
├── seed_789.pt
├── seed_1337.pt
└── calibration/
    ├── isotonic_calibrator.pkl
    └── calibration_results.json   ← optimal_threshold: 0.5010
```

---

## Step 1 — Download and extract outputs from Google Drive

Run in Colab or locally:

```python
import gdown

# Download the outputs zip from Google Drive
url = 'https://drive.google.com/uc?id=1-N3_JFfECmDDuoPgyleHSeVVRiEiHgdx'
gdown.download(url, 'outputs.zip', quiet=False)

# Extract
import subprocess
subprocess.run(["mkdir", "-p", "outputs_extracted"], check=True)
subprocess.run(["unzip", "-o", "outputs.zip", "-d", "outputs_extracted"], check=True)
```

---

## Step 2 — Copy weights into resources/

Run from the `RARE25-Submission/` directory:

```python
import shutil
from pathlib import Path

base     = Path("outputs_extracted/root/outputs")
dest     = Path("resources")
cal_src  = base / "ensemble" / "results"

# Best checkpoint per seed → renamed to seed_*.pt
seed_map = {
    "seed_42":   "epoch_002_val_ppv_1.0000.pt",
    "seed_123":  "epoch_001_val_ppv_1.0000.pt",
    "seed_456":  "epoch_003_val_ppv_1.0000.pt",
    "seed_789":  "epoch_001_val_ppv_1.0000.pt",
    "seed_1337": "epoch_002_val_ppv_1.0000.pt",
}

for seed, ckpt_name in seed_map.items():
    src = base / seed / "checkpoints" / ckpt_name
    shutil.copy(src, dest / f"{seed}.pt")
    print(f"Copied → resources/{seed}.pt")

# Ensemble calibration artifacts
(dest / "calibration").mkdir(exist_ok=True)
shutil.copy(cal_src / "isotonic_calibrator.pkl",  dest / "calibration/isotonic_calibrator.pkl")
shutil.copy(cal_src / "calibration_results.json", dest / "calibration/calibration_results.json")
print("Calibration artifacts copied.")
```

---

## Step 3 — Build and test locally

```bash
cd RARE25-Submission/
./do_test_run.sh
```

Expected output:
```
[INFO] Ensemble ready — 5 model(s)
[INFO] Threshold: 0.5010
[INFO] Processing N frame(s)...
[INFO] Done — X/N frame(s) neoplastic (thr=0.5010)
```

Check output file:
```bash
cat test/output/interface_0/stacked-neoplastic-lesion-likelihoods.json
# → [0.123456, 0.234567, ...]
```

---

## Step 4 — Export for Grand Challenge

```bash
./do_save.sh
# → rare26-algorithm_YYYY-MM-DD_HH-MM-SS.tar.gz
```

Upload `rare26-algorithm_*.tar.gz` on Grand Challenge:
**Submit → Containers tab → Upload a Container**