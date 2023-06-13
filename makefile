CXX = g++
NVCC = nvcc

CXXFLAGS = -Wall -std=c++14 -O3 -Iinc -I/usr/local/cuda-12.1/include
CUDAFLAGS = -arch=sm_86 -std=c++14 -c

CUDALIB_DIR=-L/usr/local/cuda-12.1/lib64
CUDA_LIB = -lcufft -lcudart

TARGET = cuda_gpu_test.run

SRC_DIR := src
BIN_DIR := build

EXE = $(BIN_DIR)/$(TARGET)

C_SRC := $(wildcard $(SRC_DIR)/*.c)
C_OBJ := $(C_SRC:$(SRC_DIR)/%.c=$(BIN_DIR)/%.o)

CXX_SRC := $(wildcard $(SRC_DIR)/*.cpp)
CXX_OBJ := $(CXX_SRC:$(SRC_DIR)/%.cpp=$(BIN_DIR)/%.o)

CUDA_SRC := $(wildcard $(SRC_DIR)/*.cu)
CUDA_OBJ := $(CUDA_SRC:$(SRC_DIR)/%.cu=$(BIN_DIR)/%.o)

OBJS = $(CXX_OBJ) $(C_OBJ) $(CUDA_OBJ)

.PHONY: all clean

all: $(EXE)
	@true

clean:
	@$(RM) -rv $(BIN_DIR) $(BIN_DIR)

$(EXE): $(OBJS)
	@$(CXX) -o $@ $(OBJS) $(CUDALIB_DIR) $(CUDA_LIB)
	@echo "[\33[1;32mSuccess\33[0m]	Linking complete!"

$(BIN_DIR)/%.o: $(SRC_DIR)/%.c | $(BIN_DIR)
	@$(CXX) $(CXXFLAGS) -c $< -o $@
	@echo "[\33[1;32mSuccess\33[0m]	Compiled "$<" successfully!"

$(BIN_DIR)/%.o: $(SRC_DIR)/%.cu | $(BIN_DIR)
	@$(NVCC) $(CUDAFLAGS) -c $< -o $@
	@echo "[\33[1;32mSuccess\33[0m]	Compiled "$<" successfully!"

$(BIN_DIR):
	@mkdir -p $@
	@echo "[\33[1;32mSuccess\33[0m]	Create build directory."
