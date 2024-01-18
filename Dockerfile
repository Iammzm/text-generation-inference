FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

#*****************************************************************************
# Arguments
#*****************************************************************************
# Miniconda version
ARG MINICONDA_VERSION=Miniconda3-py311_23.11.0-0-Linux-x86_64
# Protoc version (required by TGI)
ARG PROTOC_VERSION=protoc-21.12-linux-x86_64
# TGI version
ARG TGI_VERSION=v1.0.1
# Open VScode server version
# ARG OPENVSCODE_VERSION=openvscode-server-v1.80.1


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

# Create environment with Python 3.9 (required by TGI)
RUN conda create -n ai-copilot python=3.9


# Install pytorch
RUN conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -n ai-copilot

# Make all below RUN command use the correct conda environment
SHELL ["conda", "run", "--no-capture-output", "-n", "ai-copilot", "/bin/bash", "-c"]

# Install text-generation-inference and text-generation-benchmark
RUN git clone https://github.com/huggingface/text-generation-inference
## <HOTFIX> Required to fix https://github.com/huggingface/text-generation-inference/pull/838
# RUN git config --global user.email "none@example.com" && git config --global user.name "None"
# RUN cd text-generation-inference && git cherry-pick 05dd14fdb93f83ad5fde6d5b9cb6c21edef71aa1
## </HOTFIX>

RUN pip install git+https://github.com/OlivierDehaene/megablocks@181709df192de9a941fdf3a641cdc65a0462996e

# # Install dev requirements
# COPY requirements-dev.txt /requirements-dev.txt
# RUN pip install -r /requirements-dev.txt --no-cache-dir && rm -f /requirements-dev.txt

# # Install project requirements
# COPY requirements.txt /requirements.txt
# RUN pip install -r /requirements.txt --no-cache-dir && rm -f /requirements.txt


RUN cd text-generation-inference && BUILD_EXTENSIONS=True make install
RUN cd text-generation-inference/server && make install-vllm install-flash-attention
# Don't touch the line below, for the love of God, I know it[]'s stupid ¯\_(ツ)_/¯
RUN pip uninstall -y ninja && pip install ninja && pip install flash-attn --no-build-isolation
RUN cd text-generation-inference && make install-benchmark



# Install prometheus
# RUN wget https://github.com/prometheus/prometheus/releases/download/v2.46.0/prometheus-2.46.0.linux-amd64.tar.gz \
#   && tar -xzf prometheus-2.46.0.linux-amd64.tar.gz && rm prometheus-2.46.0.linux-amd64.tar.gz
# ENV PATH="/prometheus-2.46.0.linux-amd64:${PATH}"

# Install grafana
# RUN wget https://dl.grafana.com/enterprise/release/grafana-enterprise-10.1.0.linux-amd64.tar.gz \
#   && tar -xzf grafana-enterprise-10.1.0.linux-amd64.tar.gz && rm grafana-enterprise-10.1.0.linux-amd64.tar.gz

# ENV PATH="/grafana-10.1.0/bin:${PATH}"
