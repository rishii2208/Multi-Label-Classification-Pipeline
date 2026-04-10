###############################################
# BASE IMAGE
###############################################
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

###############################################
# SYSTEM DEPENDENCIES
###############################################
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python-is-python3 \
    build-essential \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

###############################################
# WORKING DIRECTORY
###############################################
WORKDIR /app

RUN python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir \
    numpy \
    pandas \
    scipy \
    scikit-learn \
    matplotlib \
    seaborn \
    pytest

###############################################
# EVALUATION ASSETS DIRECTORY
###############################################
# Populated at RUNTIME by the evaluation script.
RUN mkdir -p /eval_assets

CMD ["/bin/bash"]
