CC = riscv64-unknown-elf-gcc

RISCV_OPTIONS = -mabi=ilp32 -mno-fdiv -mno-div -misa-spec=20191213 -march=rv32i -mstrict-align
OVERALL_OPTIONS = -c
C_OPTIONS = -ffreestanding -std=c11
WARNING_OPTIONS = -Wall -pedantic
OPTIMIZE_OPTIONS = -fno-function-sections -fno-data-sections -fno-zero-initialized-in-bss -O2
CODE_GEN_OPTIONS = -fvisibility=hidden

CFLAGS = $(OVERALL_OPTIONS) $(C_OPTIONS) $(WARNING_OPTIONS) $(OPTIMIZE_OPTIONS) \
			  $(CODE_GEN_OPTIONS) $(RISCV_OPTIONS)

LDFLAGS = -nostartfiles -nodefaultlibs -nostdlib -static -T mem.ld -Wl,-Map=program.map

all: startup.o main.o program.elf

startup.o: startup.S
	$(CC) $(CFLAGS) $^ -o $@

main.o: main.c
	$(CC) $(CFLAGS) $^ -o $@

program.elf: startup.o main.o
	$(CC) $(LDFLAGS) $^ -o $@

clean:
	rm -rf startup.o main.o program.map program.elf