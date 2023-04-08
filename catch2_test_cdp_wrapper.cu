/******************************************************************************
 * Copyright (c) 2011-2023, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

#include <thrust/count.h>

#include <cuda/std/tuple>

// Has to go after all cub headers. Otherwise, this test won't catch unused
// variables in cub kernels.
#include "catch2_test_cdp_helper.h"
#include "catch2_test_helper.h"

// %PARAM% TEST_CDP cdp 0:1

template <class T>
__global__ void cub_api_example_x2_0_kernel(const T *d_in, T *d_out, int num_items)
{
  const int i = blockIdx.x * blockDim.x + threadIdx.x;

  if (i < num_items)
  {
    d_out[i] = d_in[i] * T{2};
  }
}

template <class T>
__global__ void cub_api_example_x0_5_kernel(const T *d_in, T *d_out, int num_items)
{
  const int i = blockIdx.x * blockDim.x + threadIdx.x;

  if (i < num_items)
  {
    d_out[i] = d_in[i] / T{2};
  }
}

struct cub_api_example_t
{
  static constexpr int threads_in_block = 256;

  template <class T, class KernelT>
  CUB_RUNTIME_FUNCTION static cudaError_t invoke(std::uint8_t *d_temp_storage,
                                                 std::size_t &temp_storage_bytes,
                                                 KernelT kernel,
                                                 const T *d_in,
                                                 T *d_out,
                                                 int num_items,
                                                 bool should_be_invoked_on_device)
  {
    NV_IF_TARGET(NV_IS_HOST,
                 (if (should_be_invoked_on_device) { return cudaErrorLaunchFailure; }),
                 (if (!should_be_invoked_on_device) { return cudaErrorLaunchFailure; }));

    if (d_temp_storage == nullptr)
    {
      temp_storage_bytes = static_cast<std::size_t>(num_items);
      return cudaSuccess;
    }

    if (temp_storage_bytes != static_cast<std::size_t>(num_items))
    {
      return cudaErrorInvalidValue;
    }

    const int blocks_in_grid = (num_items + threads_in_block - 1) / threads_in_block;

    return thrust::cuda_cub::launcher::triple_chevron(blocks_in_grid, threads_in_block, 0, 0)
      .doit(kernel, d_in, d_out, num_items);
  }

  template <class T>
  CUB_RUNTIME_FUNCTION static cudaError_t x2_0(std::uint8_t *d_temp_storage,
                                               std::size_t &temp_storage_bytes,
                                               const T *d_in,
                                               T *d_out,
                                               int num_items,
                                               bool should_be_invoked_on_device)
  {
    return invoke(d_temp_storage,
                  temp_storage_bytes,
                  cub_api_example_x2_0_kernel<T>,
                  d_in,
                  d_out,
                  num_items,
                  should_be_invoked_on_device);
  }

  template <class T>
  CUB_RUNTIME_FUNCTION static cudaError_t x0_5(std::uint8_t *d_temp_storage,
                                               std::size_t &temp_storage_bytes,
                                               const T *d_in,
                                               T *d_out,
                                               int num_items,
                                               bool should_be_invoked_on_device)
  {
    return invoke(d_temp_storage,
                  temp_storage_bytes,
                  cub_api_example_x0_5_kernel<T>,
                  d_in,
                  d_out,
                  num_items,
                  should_be_invoked_on_device);
  }
};

DECLARE_CDP_WRAPPER(cub_api_example_t::x2_0, x2_0);
DECLARE_CDP_WRAPPER(cub_api_example_t::x0_5, x0_5);

CUB_TEST("CDP wrapper works with predefined invocables", "[test][utils]")
{
  int n = 42;
  thrust::device_vector<int> in(n, 21);
  thrust::device_vector<int> out(n);

  int *d_in  = thrust::raw_pointer_cast(in.data());
  int *d_out = thrust::raw_pointer_cast(out.data());

  constexpr bool should_be_invoked_on_device = TEST_CDP;

  {
    x2_0(d_in, d_out, n, should_be_invoked_on_device);

    const auto actual   = static_cast<std::size_t>(thrust::count(out.begin(), out.end(), 42));
    const auto expected = static_cast<std::size_t>(n);

    REQUIRE(actual == expected);
  }

  {
    x0_5(d_out, d_out, n, should_be_invoked_on_device);

    const auto actual   = static_cast<std::size_t>(thrust::count(out.begin(), out.end(), 21));
    const auto expected = static_cast<std::size_t>(n);

    REQUIRE(actual == expected);
  }
}

struct custom_x2_0_invocable
{
  template <class T>
  CUB_RUNTIME_FUNCTION cudaError_t operator()(std::uint8_t *d_temp_storage,
                                              std::size_t &temp_storage_bytes,
                                              const T *d_in,
                                              T *d_out,
                                              int num_items,
                                              bool should_be_invoked_on_device)
  {
    return cub_api_example_t::x2_0(d_temp_storage,
                                   temp_storage_bytes,
                                   d_in,
                                   d_out,
                                   num_items,
                                   should_be_invoked_on_device);
  }
};

struct custom_x0_5_invocable
{
  template <class T>
  CUB_RUNTIME_FUNCTION cudaError_t operator()(std::uint8_t *d_temp_storage,
                                              std::size_t &temp_storage_bytes,
                                              const T *d_in,
                                              T *d_out,
                                              int num_items,
                                              bool should_be_invoked_on_device)
  {
    return cub_api_example_t::x0_5(d_temp_storage,
                                   temp_storage_bytes,
                                   d_in,
                                   d_out,
                                   num_items,
                                   should_be_invoked_on_device);
  }
};

CUB_TEST("CDP wrapper works with custom invocables", "[test][utils]")
{
  int n = 42;
  thrust::device_vector<int> in(n, 21);
  thrust::device_vector<int> out(n);

  int *d_in  = thrust::raw_pointer_cast(in.data());
  int *d_out = thrust::raw_pointer_cast(out.data());

  constexpr bool should_be_invoked_on_device = TEST_CDP;

  {
    cdp_launch(custom_x2_0_invocable{}, d_in, d_out, n, should_be_invoked_on_device);

    const auto actual   = static_cast<std::size_t>(thrust::count(out.begin(), out.end(), 42));
    const auto expected = static_cast<std::size_t>(n);

    REQUIRE(actual == expected);
  }

  {
    cdp_launch(custom_x0_5_invocable{}, d_out, d_out, n, should_be_invoked_on_device);

    const auto actual   = static_cast<std::size_t>(thrust::count(out.begin(), out.end(), 21));
    const auto expected = static_cast<std::size_t>(n);

    REQUIRE(actual == expected);
  }
}
