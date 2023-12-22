# Memory mapping
For now there is only one platform which includes two peripherals (GPIO and uptime timer). UART is being prepared in the `uart` branch.

Peripherals are memory mapped. Memory subsystem is controlled via address decoder component.

| Address | Usage |
|---------|-------|
| 0x0000_0000-0xEFFF_FFFF | User program and data |
| 0xF000_0000-0xFFFF_FFFF | Platform reserved (MMIO etc.) |

## Main memory
The memory subsystem is based on Hardvard architecture (legacy Von Neumann support is available). Instruction memory is implemented using LUTs, data memory using DRAMs.

Address space of instruction memory and data memory is separated. This means that addressing of both memories starts from 0. The addressing is handled automatically by our firmware support package (Makefile and linker script).

Not whole address space reserved for memory is actually used. Currently we use 512 words for both memories. Up to 8192 words for instruction and 1024 words for data memory was tested to pass static timing analysis.

## Platform reserved area
### GPIO
| Address | Usage |
|---------|-------|
| 0xF000_0000 | GPIOWR_A   |
| 0xF000_0001 | GPIODIR_A  |
| 0xF000_0002 | GPIORD_A   |
| 0xF000_0003 | GPIOWR_B   |
| 0xF000_0004 | GPIODIR_B  |
| 0xF000_0005 | GPIORD_B   |
| 0xF000_0006-0xF000_000F | reserved |

### System Uptime Timer (millis_timer)
| Address | Usage |
|---------|-------|
| 0xF000_0020 | TMR_MILLIS_VAL |