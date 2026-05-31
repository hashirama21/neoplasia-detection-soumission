FROM --platform=linux/amd64 pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime

LABEL maintainer="rare26-team"
LABEL description="RARE26 — Barrett Neoplasia Detection (DINOv2 ViT-B + LoRA + Ensemble)"

ENV TRANSFORMERS_OFFLINE=1
ENV HF_DATASETS_OFFLINE=1
ENV HF_HUB_OFFLINE=1
ENV TORCH_HOME=/opt/app/.torch_cache
ENV HF_HOME=/opt/app/.hf_cache
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

RUN groupadd -r user && useradd -m --no-log-init -r -g user user

RUN apt-get update && apt-get install -y --no-install-recommends \
        libglib2.0-0 \
        libgl1-mesa-glx \
        libgomp1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER user
WORKDIR /opt/app

COPY --chown=user:user requirements.txt /opt/app/

RUN python -m pip install \
    --user \
    --no-cache-dir \
    --no-color \
    --requirement /opt/app/requirements.txt

COPY --chown=user:user src/          /opt/app/src/
COPY --chown=user:user configs/      /opt/app/configs/
COPY --chown=user:user resources/    /opt/app/resources/
COPY --chown=user:user scripts/      /opt/app/scripts/
COPY --chown=user:user inference.py  /opt/app/

RUN python /opt/app/scripts/prewarm.py

ENTRYPOINT ["python", "inference.py"]
