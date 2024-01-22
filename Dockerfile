FROM nvidia/cuda:12.1.0-devel-ubuntu20.04
#*****************************************************************************
# Arguments
#*****************************************************************************
# Miniconda version
ARG MINICONDA_VERSION=Miniconda3-py311_23.11.0-2-Linux-x86_64
# Protoc version (required by TGI)
ARG PROTOC_VERSION=protoc-21.12-linux-x86_64

ARG PYTORCH_VERSION=2.1.1
ARG PYTHON_VERSION=3.10
# Keep in sync with `server/pyproject.toml
ARG CUDA_VERSION=12.1
ARG MAMBA_VERSION=23.3.1-1
ARG CUDA_CHANNEL=nvidia
ARG INSTALL_CHANNEL=pytorch

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
ENV SENTENCE_TRANSFORMERS_HOME=/data_zfs/hf_cache/sentence_transformers
ENV NVIDIA_DISABLE_REQUIRE=1

# Update and install some packages
RUN apt-get update \
  && apt-get install -y zsh tmux wget curl git vim htop \
  libssl-dev gcc unzip pkg-config ninja-build make \
  g++ build-essential

# Install visual studio code server (openvscode fork)
# RUN wget -q https://github.com/gitpod-io/openvscode-server/releases/download/${OPENVSCODE_VERSION}/${OPENVSCODE_VERSION}-linux-x64.tar.gz \
#   && tar -xzf ${OPENVSCODE_VERSION}-linux-x64.tar.gz \
#   && mv ${OPENVSCODE_VERSION}-linux-x64 /usr/local/openvscode-server \
#   && ln -s /usr/local/openvscode-server/bin/openvscode-server /usr/local/bin/code-server \
#   && rm ${OPENVSCODE_VERSION}-linux-x64.tar.gz

# Install protoc
RUN curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v21.12/${PROTOC_VERSION}.zip \
  && unzip -o ${PROTOC_VERSION}.zip -d /usr/local bin/protoc \
  && unzip -o ${PROTOC_VERSION}.zip -d /usr/local 'include/*' \
  && rm -f ${PROTOC_VERSION}.zip

# Install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install miniconda
RUN curl -sS https://repo.anaconda.com/miniconda/${MINICONDA_VERSION}.sh -O \
  && bash ${MINICONDA_VERSION}.sh -b \
  && rm -f ${MINICONDA_VERSION}.sh

RUN conda create -n ai-copilot python=${PYTHON_VERSION}


# Install pytorch
RUN conda install pytorch torchvision torchaudio pytorch-cuda=${CUDA_VERSION} -c pytorch -c nvidia -n ai-copilot

# Make all below RUN command use the correct conda environment
SHELL ["conda", "run", "--no-capture-output", "-n", "ai-copilot", "/bin/bash", "-c"]


# Install text-generation-inference and text-generation-benchmark
RUN git clone https://github.com/huggingface/text-generation-inference
RUN pip install git+https://github.com/OlivierDehaene/megablocks@181709df192de9a941fdf3a641cdc65a0462996e


RUN cd text-generation-inference && BUILD_EXTENSIONS=True make install
# try running when in session (using gpu)
RUN cd text-generation-inference/server && make install-vllm-cuda install-flash-attention-v2-cuda
RUN cd text-generation-inference/server && make install-flash-attention-v2-cuda
RUN cd text-generation-inference && make install-benchmark
