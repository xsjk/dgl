#!/usr/bin/env bash

cd "$(cd "$(dirname "$0")/.." && pwd)"
ROOT_DIR="$PWD"

ENV_NAME="dgl"
JOBS="16"

CUDA_TOOLKIT_VERSION="$(nvidia-smi -q | awk -F': ' '/CUDA Version/ {print $2; exit}')"
GPU_COMPUTE_CAPS="$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | tr -d ' ' | awk '!seen[$0]++')"
CMAKE_CUDA_ARCHITECTURES="$(printf '%s\n' "${GPU_COMPUTE_CAPS}" | tr -d '.' | paste -sd ';' -)"

echo "==> Detected CUDA Toolkit version: ${CUDA_TOOLKIT_VERSION}"
echo "==> Detected GPU compute capabilities: ${GPU_COMPUTE_CAPS}"
echo "==> Setting CMake CUDA architectures to: ${CMAKE_CUDA_ARCHITECTURES}"

set -eo pipefail


echo "==> Updating submodules"
git submodule update --init --recursive

echo "==> Creating conda environment ${ENV_NAME}"
conda create -y -n "${ENV_NAME}" \
  -c conda-forge \
  -c nvidia \
  python \
  cmake \
  make \
  "pytorch=*=*cuda*" \
  packaging \
  pandas \
  psutil \
  pyyaml \
  requests \
  scipy \
  tqdm \
  pydantic \
  "cuda-toolkit=${CUDA_TOOLKIT_VERSION}"

conda activate "${ENV_NAME}"

set -u

echo "==> Cleaning stale build caches"
rm -rf \
  build \
  tensoradapter/pytorch/build \
  dgl_sparse/build \
  graphbolt/build \
  python/dist

echo "==> Configuring CMake"
cmake -S . -B build \
  -DUSE_CUDA=ON \
  -DCMAKE_CUDA_ARCHITECTURES="${CMAKE_CUDA_ARCHITECTURES}" \
  -DBUILD_CPP_TEST=OFF

echo "==> Building native libraries"
cmake --build build -j"${JOBS}"

echo "==> Building Python wheel"
cd python
python setup.py bdist_wheel
WHEEL_PATH="${ROOT_DIR}/python/$(find dist -maxdepth 1 -name 'dgl-*.whl' | head -n 1)"
cd ..

echo "==> Installing wheel"
pip install --no-deps --force-reinstall "${WHEEL_PATH}"

echo "==> Smoke test"
python -c "import torch, dgl, dgl.sparse, dgl.graphbolt; print('torch', torch.__version__); print('dgl', dgl.__version__)"

echo
echo "Environment: ${ENV_NAME}"
echo "Wheel: ${WHEEL_PATH}"
