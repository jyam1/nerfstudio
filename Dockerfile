ARG CUDA_VERSION=11.8.0
ARG OS_VERSION=22.04
ARG USER_ID=1000

# Define base image.
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${OS_VERSION}
ARG CUDA_VERSION
ARG OS_VERSION
ARG USER_ID

# metainformation
LABEL org.opencontainers.image.version="0.1.18"
LABEL org.opencontainers.image.source="https://github.com/nerfstudio-project/nerfstudio"
LABEL org.opencontainers.image.licenses="Apache License 2.0"
LABEL org.opencontainers.image.base.name="docker.io/library/nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${OS_VERSION}"

# Variables used at build time.
ARG CUDA_ARCHITECTURES=86

# Set environment variables.
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin
ENV CUDA_HOME="/usr/local/cuda"

# Install required apt packages and clear cache afterwards.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    ffmpeg \
    git \
    libatlas-base-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-test-dev \
    libhdf5-dev \
    libcgal-dev \
    libeigen3-dev \
    libflann-dev \
    libfreeimage-dev \
    libgflags-dev \
    libglew-dev \
    libgoogle-glog-dev \
    libmetis-dev \
    libprotobuf-dev \
    libqt5opengl5-dev \
    libsqlite3-dev \
    libsuitesparse-dev \
    nano \
    protobuf-compiler \
    python-is-python3 \
    python3.10-dev \
    python3-pip \
    qtbase5-dev \
    sudo \
    vim-tiny \
    wget && \
    rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh
ENV PATH="/opt/conda/bin:${PATH}"

# Create Conda environment
RUN conda create -n nerfstudio python=3.10 && \
    echo "source activate nerfstudio" >> ~/.bashrc

# Install Conda packages
RUN /bin/bash -c "source activate nerfstudio && \
    conda install -c conda-forge \
    cmake \
    eigen \
    glew \
    glog \
    hdf5 \
    libgcc-ng \
    metis \
    opencv \
    protobuf \
    pytorch \
    qt \
    sqlite \
    suitesparse \
    torchvision"

# Activate Conda environment
SHELL ["/bin/bash", "-c", "source activate nerfstudio"]

# Install additional packages
RUN conda install -c conda-forge colmap ceres-solver

# Create non-root user and setup environment.
RUN useradd -m -d /home/user -g root -G sudo -u ${USER_ID} user
RUN usermod -aG sudo user
RUN echo "user:user" | chpasswd
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to the new user and workdir.
USER ${USER_ID}
WORKDIR /home/user

# Install Python packages using Conda
RUN conda install -c conda-forge \
    python=3.10 \
    pathtools \
    promise \
    pybind11 \
    omegaconf \
    plyfile==0.8.1

# Install other Conda packages or Git clone and build as needed.

# Change working directory
WORKDIR /workspace

# Install nerfstudio cli auto completion
RUN ns-install-cli --mode install

# Bash as the default entrypoint.
CMD /bin/bash -l
