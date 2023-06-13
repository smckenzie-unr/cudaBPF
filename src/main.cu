#include <cstdlib>
#include <cmath>
#include <complex>
#include <iostream>
#include <fstream>
#include <new>
#include <cmath>
#include <chrono>

// The NVIDIA CUDA cuFFT library
#include <cufft.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>

using namespace std;
using namespace chrono;

constexpr size_t N		(1024);
constexpr size_t B		(1);


__global__ void bpfilter(cufftComplex* c)
{
	int i = threadIdx.x;
	if (i != 30)
	{
		c[i].x = 0.0;
		c[i].y = 0.0;
	}
}
__global__ void multiScalar(cufftComplex* c, const cufftComplex* a, const float b)
{
	int i = threadIdx.x;
	c[i].x = a[i].x * b;
	c[i].y = a[i].y * b;
}

int main(int argc, char* const __restrict argv[])
{
	ofstream outputFile("filtered.csv");
	ifstream inputFile("data.txt");
	cufftComplex* pf8Signal_device(nullptr);
	complex<float>* pf8Signal_host(new(nothrow) complex<float>[N * B]);
	float f8Intermediate(0.0);
	cufftHandle plan;
	cufftResult status;

	for (unsigned int idx = 0; idx < (N * B); idx++)
	{
		inputFile >> f8Intermediate;
		pf8Signal_host[idx].real(f8Intermediate);
		pf8Signal_host[idx].imag(0.0);
	}
	inputFile.close();

	cudaMalloc(&pf8Signal_device, sizeof(cufftComplex) * N * B);
	cudaMemcpy(pf8Signal_device, pf8Signal_host, sizeof(cufftComplex) * N * B, cudaMemcpyHostToDevice);
	status = cufftPlan1d(&plan, N, CUFFT_C2C, B);

	status = cufftExecC2C(plan, pf8Signal_device, pf8Signal_device, CUFFT_FORWARD);
	cudaDeviceSynchronize();
	bpfilter<<<B, N>>>(pf8Signal_device);
	status = cufftExecC2C(plan, pf8Signal_device, pf8Signal_device, CUFFT_INVERSE);
	cudaDeviceSynchronize();
	multiScalar<<<B, N>>>(pf8Signal_device, pf8Signal_device, 1.0F / (N * B));

	cudaMemcpy(pf8Signal_host, pf8Signal_device, sizeof(cufftComplex) * N * B, cudaMemcpyDeviceToHost);
	for (unsigned int idx = 0; idx < (N * B); idx++)
	{
		outputFile << pf8Signal_host[idx].real() * 10.0f << ',' << endl;
	}
	outputFile.close();

	cufftDestroy(plan);
	cudaFree(pf8Signal_device);
	delete[] pf8Signal_host;
	return NULL;
}