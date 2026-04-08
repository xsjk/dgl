#!/bin/bash
# Helper script to build dgl sparse libraries for PyTorch
set -e

mkdir -p build
mkdir -p $BINDIR/dgl_sparse
cd build

if [ $(uname) = 'Darwin' ]; then
	CPSOURCE=*.dylib
else
	CPSOURCE=*.so
fi

CMAKE_FLAGS="-DTORCH_CUDA_ARCH_LIST=$TORCH_CUDA_ARCH_LIST -DUSE_CUDA=$USE_CUDA -DEXTERNAL_DMLC_LIB_PATH=$EXTERNAL_DMLC_LIB_PATH"
CMAKE_FLAGS="$CMAKE_FLAGS -DDGL_CUDA_ARCHITECTURES=$DGL_CUDA_ARCHITECTURES"
# CMake passes in the list of directories separated by spaces.  Here we replace them with semicolons.
CMAKE_FLAGS="$CMAKE_FLAGS -DDGL_INCLUDE_DIRS=${INCLUDEDIR// /;} -DDGL_BUILD_DIR=$BINDIR"
echo $CMAKE_FLAGS

if [ $# -eq 0 ]; then
	$CMAKE_COMMAND $CMAKE_FLAGS ..
	env -u MAKEFLAGS -u MFLAGS -u CMAKE_BUILD_PARALLEL_LEVEL "$CMAKE_COMMAND" --build .
	cp -v $CPSOURCE $BINDIR/dgl_sparse
else
	for PYTHON_INTERP in $@; do
		TORCH_VER=$($PYTHON_INTERP -c 'import torch; print(torch.__version__.split("+")[0])')
		mkdir -p $TORCH_VER
		cd $TORCH_VER
		$CMAKE_COMMAND $CMAKE_FLAGS -DPYTHON_INTERP=$PYTHON_INTERP ../..
		env -u MAKEFLAGS -u MFLAGS -u CMAKE_BUILD_PARALLEL_LEVEL "$CMAKE_COMMAND" --build .
		cp -v $CPSOURCE $BINDIR/dgl_sparse
		cd ..
	done
fi
