CC = riscv64-unknown-elf-gcc

RISCV_GCC_OPTIONS = -mabi=ilp32 -mno-fdiv -mno-div -misa-spec=20191213 -march=rv32i -mstrict-align

GCC_OVERALL_OPTIONS = -c
GCC_C_OPTIONS = -ffreestanding -std=c11
GCC_WARNING_OPTIONS = -Wall -pedantic
GCC_OPTIMIZE_OPTIONS = -fno-function-sections -fno-data-sections -fno-zero-initialized-in-bss -O2
GCC_CODE_GEN_OPTIONS = -fvisibility=hidden
GCC_OPTIONS = $(GCC_OVERALL_OPTIONS) $(GCC_C_OPTIONS) $(GCC_WARNING_OPTIONS) $(GCC_OPTIMIZE_OPTIONS) \
			  $(GCC_CODE_GEN_OPTIONS) $(RISCV_GCC_OPTIONS)

LINKER_OPTIONS = -nostartfiles -nodefaultlibs -nostdlib -static -T mem.ld -Wl,-Map=program.map

all: startup.o main.o program.elf

startup.o: startup.S
	$(CC) $(GCC_OPTIONS) $^ -o $@

main.o: main.c
	$(CC) $(GCC_OPTIONS) $^ -o $@

program.elf: startup.o main.o
	$(CC) $(LINKER_OPTIONS) $^ -o $@

clean:
	rm -rf startup.o main.o program.map program.elf