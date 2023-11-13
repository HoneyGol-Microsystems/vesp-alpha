# include paths
ROOT_PATH = ..
BUILD_PATH = $(ROOT_PATH)/build
INCLUDE_PATH = $(ROOT_PATH)/software/lib/include
SRC_PATH = $(ROOT_PATH)/software/lib/src
COMMON_PATH = $(ROOT_PATH)/software/common

# compiler
CC = riscv64-unknown-elf-gcc

# compiler options
RISCV_OPTIONS = -mabi=ilp32 -mno-fdiv -mno-div -misa-spec=20191213 -march=rv32i -mstrict-align
OVERALL_OPTIONS = -c
C_OPTIONS = -ffreestanding -std=c11
WARNING_OPTIONS = -Wall -pedantic
OPTIMIZE_OPTIONS = -fno-function-sections -fno-data-sections -fno-zero-initialized-in-bss -O2
DIRECTORY_OPTIONS = -I $(INCLUDE_PATH)
CODE_GEN_OPTIONS = -fvisibility=hidden

CFLAGS = $(OVERALL_OPTIONS) $(C_OPTIONS) $(WARNING_OPTIONS) $(OPTIMIZE_OPTIONS) \
			  $(CODE_GEN_OPTIONS) $(DIRECTORY_OPTIONS) $(RISCV_OPTIONS)

LDFLAGS = -nostartfiles -nodefaultlibs -nostdlib -static -T $(COMMON_PATH)/mem.ld -Wl,-Map=memory.map

# create name of .o file from "SRC" cmd argument
SRC_OBJ = $(BUILD_PATH)/$(addsuffix .o, $(notdir $(basename $(SRC))))

# for compiling standalone programs
standalone: $(SRC_OBJ) standalone.elf

# for compiling firmware in C with startup, headers etc.
firmware: $(BUILD_PATH)/startup.o $(SRC_OBJ) firmware.elf

$(BUILD_PATH)/startup.o: $(COMMON_PATH)/startup.S
	$(CC) $(CFLAGS) $^ -o $@

$(SRC_OBJ): $(SRC)
	$(CC) $(CFLAGS) $^ -o $@

standalone.elf: $(SRC_OBJ)
	$(CC) $(LDFLAGS) $^ -o $@

firmware.elf: $(BUILD_PATH)/startup.o $(SRC_OBJ)
	$(CC) $(LDFLAGS) $^ -o $@

clean:
	rm -rf memory.map standalone.elf firmware.elf