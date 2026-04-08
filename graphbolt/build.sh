#!/bin/bash
# Helper script to build graphbolt libraries for PyTorch
set -e

mkdir -p build
mkdir -p $BINDIR/graphbolt
cd build

if [ $(uname) = 'Darwin' ]; then
  CPSOURCE=*.dylib
else
  CPSOURCE=*.so
fi

# We build for the same architectures as DGL, thus we hardcode
# TORCH_CUDA_ARCH_LIST and we need to at least compile for Volta. Until
# https://github.com/NVIDIA/cccl/issues/1083 is resolved, we need to compile the
# cuda/extension folder with Volta+ CUDA architectures.
TORCH_CUDA_ARCH_LIST="Volta"
if ! [[ -z "${DGL_CUDA_ARCHITECTURES:-}" ]]; then
  TORCH_CUDA_ARCH_LIST=$(
    printf '%s\n' "${DGL_CUDA_ARCHITECTURES}" | tr ';' '\n' \
      | awk '$1 >= 70 { print substr($1, 1, length($1) - 1) "." substr($1, length($1), 1) }' \
      | paste -sd ';' -
  )
  if [[ -z "${TORCH_CUDA_ARCH_LIST}" ]]; then
    TORCH_CUDA_ARCH_LIST="Volta"
  fi
fi
CMAKE_FLAGS="-DUSE_CUDA=$USE_CUDA -DTORCH_CUDA_ARCH_LIST=$TORCH_CUDA_ARCH_LIST"
CMAKE_FLAGS="$CMAKE_FLAGS -DDGL_CUDA_ARCHITECTURES=$DGL_CUDA_ARCHITECTURES"
echo "graphbolt cmake flags: $CMAKE_FLAGS"

if [ $# -eq 0 ]; then
  $CMAKE_COMMAND $CMAKE_FLAGS ..
  env -u MAKEFLAGS -u MFLAGS -u CMAKE_BUILD_PARALLEL_LEVEL "$CMAKE_COMMAND" --build .
  cp -v $CPSOURCE $BINDIR/graphbolt
else
  for PYTHON_INTERP in $@; do
    TORCH_VER=$($PYTHON_INTERP -c 'import torch; print(torch.__version__.split("+")[0])')
    mkdir -p $TORCH_VER
    cd $TORCH_VER
    $CMAKE_COMMAND $CMAKE_FLAGS -DPYTHON_INTERP=$PYTHON_INTERP ../..
    env -u MAKEFLAGS -u MFLAGS -u CMAKE_BUILD_PARALLEL_LEVEL "$CMAKE_COMMAND" --build .
    cp -v $CPSOURCE $BINDIR/graphbolt
    cd ..
  done
fi
