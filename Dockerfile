# Execute from the root of the repo as:
# docker buildx build --platform=linux/arm64,linux/amd64 -f docker/Dockerfile ./docker/ --progress=plain

FROM ghcr.io/fenics/dolfinx/lab:v0.7.2
ARG TARGETPLATFORM

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DEB_PYTHON_INSTALL_LAYOUT=deb_system
ENV HDF5_MPI="ON"
ENV HDF5_DIR="/usr/local"
ENV PYVISTA_JUPYTER_BACKEND="static"

# Set working directory
WORKDIR /home/me-672

# Update package lists and install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-utils \
        libgl1-mesa-dev \
        libxrender1 \
        xvfb \
        curl && \
    # Install Node.js from Nodesource
    curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    # Clean up package lists to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade setuptools and pip
RUN python3 -m pip install --no-cache-dir -U setuptools pip pkgconfig

# Install VTK based on target platform
RUN echo ${TARGETPLATFORM} && \
    if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        python3 -m pip install --no-cache-dir "https://github.com/finsberg/vtk-aarch64/releases/download/vtk-9.3.0-cp312/vtk-9.3.0.dev0-cp312-cp312-linux_aarch64.whl"; \
    else \
        python3 -m pip install --no-cache-dir vtk; \
    fi

# Install the package and purge pip cache to reduce image size
RUN python3 -m pip install --no-cache-dir --no-binary=h5py -v . && \
    python3 -m pip cache purge

# Add project files
ADD pyproject.toml /home/me-672/pyproject.toml
ADD *.ipynb /home/me-672/

# Set the entry point for Jupyter Lab
ENTRYPOINT ["jupyter", "lab", "--ip", "0.0.0.0", "--no-browser", "--allow-root"]

