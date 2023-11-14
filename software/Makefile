# -----------------------------------------------------------------------------
# Software directories
# -----------------------------------------------------------------------------
ROOT_PATH        = ..
COMMON_PATH      = $(ROOT_PATH)/software/common
EXAMPLE_PATH     = $(ROOT_PATH)/software/example
LIB_INCLUDE_PATH = $(ROOT_PATH)/software/lib/include
LIB_SRC_PATH     = $(ROOT_PATH)/software/lib/src

# -----------------------------------------------------------------------------
# Source files
# -----------------------------------------------------------------------------
# Software source files
STARTUP_SRC  = $(COMMON_PATH)/startup.S
EXAMPLE_SRC  = $(wildcard $(EXAMPLE_PATH)/*.S) $(wildcard $(EXAMPLE_PATH)/*.c)
LIB_SRC      = $(wildcard $(LIB_SRC_PATH)/*.c)
FIRMWARE_SRC = $(STARTUP_SRC) $(LIB_SRC)

# Object files
FIRMWARE_OBJ = $(addsuffix .o, $(FIRMWARE_SRC))
ALL_OBJ      = $(addsuffix .o, $(STARTUP_SRC) $(EXAMPLE_SRC) $(LIB_SRC))

# Create name of .o file from "SRC" cmd argument
SRC_OBJ = $(addsuffix .o, $(SRC))
ALL_OBJ += $(SRC_OBJ)

# Linker script source file
LINKER_SCRIPT_SRC = $(COMMON_PATH)/mem.ld

# -----------------------------------------------------------------------------
# Compiler stuff
# -----------------------------------------------------------------------------
# Compiler
CC = riscv64-unknown-elf-gcc

# Compiler options
RISCV_OPTIONS     = -mabi=ilp32 -mno-fdiv -mno-div -misa-spec=20191213 -march=rv32i -mstrict-align
OVERALL_OPTIONS   = -c
C_OPTIONS 	      = -ffreestanding -std=c11
WARNING_OPTIONS   = -Wall -pedantic
OPTIMIZE_OPTIONS  = -fno-function-sections -fno-data-sections -fno-zero-initialized-in-bss -O2
DIRECTORY_OPTIONS = -I $(LIB_INCLUDE_PATH)
CODE_GEN_OPTIONS  = -fvisibility=hidden

# All compiler options
CFLAGS = $(OVERALL_OPTIONS) $(C_OPTIONS) $(WARNING_OPTIONS) $(OPTIMIZE_OPTIONS) \
			  $(CODE_GEN_OPTIONS) $(DIRECTORY_OPTIONS) $(RISCV_OPTIONS)

# Linker script options
LDFLAGS = -nostartfiles -nodefaultlibs -nostdlib -static -T $(LINKER_SCRIPT_SRC) -Wl,-Map=memory.map,--gc-sections

# -----------------------------------------------------------------------------
# User targets
# -----------------------------------------------------------------------------
# Target for compiling standalone programs
standalone: standalone.elf

# Target for compiling firmware in C with startup, headers etc.
firmware: firmware.elf

# Target for cleaning
clean:
	rm -rf ./*.o $(ALL_OBJ) memory.map standalone.elf firmware.elf

# -----------------------------------------------------------------------------
# ELF targets
# -----------------------------------------------------------------------------
standalone.elf: $(SRC_OBJ)
	$(CC) $(LDFLAGS) $^ -o $@

firmware.elf: $(FIRMWARE_OBJ) $(SRC_OBJ)
	$(CC) $(LDFLAGS) $^ -o $@

# -----------------------------------------------------------------------------
# Targets for compilation of source files into object files
# -----------------------------------------------------------------------------
%.S.o: %.S
	$(CC) $(CFLAGS) $^ -o $@

%.c.o: %.c
	$(CC) $(CFLAGS) $^ -o $@