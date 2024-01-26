FROM ghcr.io/huggingface/text-generation-inference:1.3


#*****************************************************************************
# Environment variables
#*****************************************************************************
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/miniconda3/bin:${PATH}"
ENV PATH="/root/.cargo/bin:${PATH}"
ENV MAX_JOBS=16
ENV CARGO_BUILD_JOBS=16
ENV RUSTUP_HOME=/root/.rustup
ENV CARGO_HOME=/root/.cargo
ENV PYTHONUNBUFFERED=1
ENV HF_HOME=/data_zfs/hf_cache
ENV HUGGINGFACE_HUB_CACHE=data_zfs/hf_cache
ENV SENTENCE_TRANSFORMERS_HOME=/data_zfs/hf_cache/sentence_transformers
ENV NVIDIA_DISABLE_REQUIRE=1

# Update and install some packages
RUN apt-get update \
  && apt-get install -y zsh tmux wget curl git vim htop \
  libssl-dev gcc unzip pkg-config ninja-build make \
  g++ build-essential
