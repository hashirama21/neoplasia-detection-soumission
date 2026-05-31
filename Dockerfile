FROM --platform=linux/amd64 pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime

LABEL maintainer="rare26-team"
LABEL description="RARE26 — Barrett Neoplasia Detection (DINOv2 ViT-B + LoRA + Ensemble)"

# ── Offline enforcement ───────────────────────────────────────────────────────
# Prevent ANY network call at runtime (Grand Challenge runs --network none).
# Set during build so the pre-warm step validates offline behaviour too.
ENV TRANSFORMERS_OFFLINE=1
ENV HF_DATASETS_OFFLINE=1
ENV HF_HUB_OFFLINE=1
ENV TORCH_HOME=/opt/app/.torch_cache
ENV HF_HOME=/opt/app/.hf_cache
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# ── Non-root user (required by Grand Challenge) ───────────────────────────────
RUN groupadd -r user && useradd -m --no-log-init -r -g user user

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        libglib2.0-0 \
        libgl1-mesa-glx \
        libgomp1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Switch to user and install Python dependencies ───────────────────────────
USER user
WORKDIR /opt/app

COPY --chown=user:user requirements.txt /opt/app/

RUN python -m pip install \
    --user \
    --no-cache-dir \
    --no-color \
    --requirement /opt/app/requirements.txt

# ── Copy source, configs, weights ─────────────────────────────────────────────
COPY --chown=user:user src/       /opt/app/src/
COPY --chown=user:user configs/   /opt/app/configs/
COPY --chown=user:user resources/ /opt/app/resources/
COPY --chown=user:user inference.py /opt/app/

# ── Pre-warm timm model architecture ─────────────────────────────────────────
# Runs at BUILD time (internet available) to cache any config files timm needs.
# At RUNTIME the container is fully air-gapped (--network none).
RUN python -c "
import timm, torch, sys
print('Pre-warming timm ViT-B/14 DINOv2 architecture...')
model = timm.create_model(
    'vit_base_patch14_dinov2.lvd142m',
    pretrained=False,
    num_classes=0,
    img_size=392,
    dynamic_img_size=True,
)
dummy = torch.zeros(1, 3, 392, 392)
with torch.no_grad():
    out = model(dummy)
print(f'Pre-warm OK — output shape: {out.shape}')
del model, dummy
"

# ── Verify offline: re-run pre-warm with HF_HUB_OFFLINE=1 (already set) ──────
RUN python -c "
import os, timm, torch
assert os.environ.get('HF_HUB_OFFLINE') == '1', 'HF_HUB_OFFLINE not set!'
model = timm.create_model(
    'vit_base_patch14_dinov2.lvd142m',
    pretrained=False,
    num_classes=0,
    img_size=392,
    dynamic_img_size=True,
)
print('Offline check passed — model instantiates without network.')
del model
"

ENTRYPOINT ["python", "inference.py"]