CC = riscv64-unknown-elf-gcc
MARCH = rv32i
MABI = ilp32
CFLAGS = -Wall -pedantic -c -static -fvisibility=hidden -nostartfiles -march=$(MARCH) -mabi=$(MABI) -std=c11 -O2
LDFLAGS = -nostdlib -T mem.ld -Wl,-Map=program.map

all: startup.o main.o program.elf

startup.o: startup.S
	$(CC) $(CFLAGS) $^ -o $@

main.o: main.c
	$(CC) $(CFLAGS) $^ -o $@

program.elf: startup.o main.o
	$(CC) $(LDFLAGS) $^ -o $@

clean:
	rm -rf startup.o main.o program.map program.elf