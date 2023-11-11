CC = riscv64-unknown-elf-gcc

RISCV_OPTIONS = -mabi=ilp32 -mno-fdiv -mno-div -misa-spec=20191213 -march=rv32i -mstrict-align
OVERALL_OPTIONS = -c
C_OPTIONS = -ffreestanding -std=c11
WARNING_OPTIONS = -Wall -pedantic
OPTIMIZE_OPTIONS = -fno-function-sections -fno-data-sections -fno-zero-initialized-in-bss -O2
CODE_GEN_OPTIONS = -fvisibility=hidden

CFLAGS = $(OVERALL_OPTIONS) $(C_OPTIONS) $(WARNING_OPTIONS) $(OPTIMIZE_OPTIONS) \
			  $(CODE_GEN_OPTIONS) $(RISCV_OPTIONS)

LDFLAGS = -nostartfiles -nodefaultlibs -nostdlib -static -T mem.ld -Wl,-Map=memory.map

SRC_OBJ = $(addsuffix .o, $(basename $(SRC)))  # create name of .o file from "SRC" cmd argument

# for compiling standalone programs
standalone: $(SRC_OBJ) standalone.elf

# for compiling firmware in C with startup, headers etc.
firmware: startup.o $(SRC_OBJ) firmware.elf

startup.o: startup.S
	$(CC) $(CFLAGS) $^ -o $@

$(SRC_OBJ): $(SRC)
	$(CC) $(CFLAGS) $^ -o $@

standalone.elf: $(SRC_OBJ)
	$(CC) $(LDFLAGS) $^ -o $@

firmware.elf: startup.o $(SRC_OBJ)
	$(CC) $(LDFLAGS) $^ -o $@

clean:
	rm -rf *.o memory.map standalone.elf firmware.elf