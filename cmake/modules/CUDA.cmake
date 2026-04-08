enable_language(CUDA)
find_package(CUDAToolkit REQUIRED)

if(NOT CMAKE_CUDA_ARCHITECTURES)
  message(FATAL_ERROR "CMAKE_CUDA_ARCHITECTURES must be set when USE_CUDA=ON.")
endif()

message(STATUS "Found CUDA compiler=${CMAKE_CUDA_COMPILER}")
message(STATUS "CUDA architectures: ${CMAKE_CUDA_ARCHITECTURES}")

function(dgl_configure_cuda_target target)
  target_include_directories(${target} PRIVATE ${CUDAToolkit_INCLUDE_DIRS})
  set_target_properties(
    ${target}
    PROPERTIES
    CUDA_ARCHITECTURES "${CMAKE_CUDA_ARCHITECTURES}"
    CUDA_STANDARD 17)
  target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:${DGL_CUDA_COMPILE_OPTIONS}>)
endfunction()

macro(dgl_config_cuda linker_libs)
  add_definitions(-DDGL_USE_CUDA)

  message(STATUS "CMAKE_CXX_FLAGS: ${CMAKE_CXX_FLAGS}")
  string(REGEX REPLACE "[ \t\n\r]+" "," CXX_HOST_FLAGS "${CMAKE_CXX_FLAGS}")

  set(DGL_CUDA_COMPILE_OPTIONS "")
  if(NOT CXX_HOST_FLAGS STREQUAL "")
    list(APPEND DGL_CUDA_COMPILE_OPTIONS "-Xcompiler=${CXX_HOST_FLAGS}")
  endif()
  if(USE_OPENMP)
    # Needed by CUDA disjoint union source file.
    list(APPEND DGL_CUDA_COMPILE_OPTIONS "-Xcompiler=${OpenMP_CXX_FLAGS}")
  endif()
  list(APPEND DGL_CUDA_COMPILE_OPTIONS
    "--expt-relaxed-constexpr"
    "--expt-extended-lambda"
    "-Wno-deprecated-declarations"
    "-std=c++17")

  message(STATUS "CUDA compile options: ${DGL_CUDA_COMPILE_OPTIONS}")

  list(APPEND ${linker_libs}
    CUDA::cudart
    CUDA::cublas
    CUDA::cusparse)
endmacro()
