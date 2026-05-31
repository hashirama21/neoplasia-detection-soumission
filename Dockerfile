FROM --platform=linux/amd64 pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime

LABEL maintainer="rare26-team"
LABEL description="RARE26 — Barrett Neoplasia Detection (DINOv2 ViT-B + LoRA + Ensemble)"

ENV PYTHONUNBUFFERED=1

# Non-root user required by Grand Challenge
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

COPY --chown=user:user src/       /opt/app/src/
COPY --chown=user:user configs/   /opt/app/configs/
COPY --chown=user:user resources/ /opt/app/resources/
COPY --chown=user:user inference.py /opt/app/

ENTRYPOINT ["python", "inference.py"]
