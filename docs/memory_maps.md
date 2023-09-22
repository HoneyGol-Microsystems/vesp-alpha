# Memory mapping
For now there is only one platform supporting only bare-metal programs.

| Address | Usage |
|---------|-------|
| 0x0000_0000-0xEFFF_FFFF | User program and data |
| 0xF000_0000-0xFFFF_FFFF | Platform reserved (MMIO etc.) |

## Platform reserved area
| Address | Usage |
|---------|-------|
| 0xF000_0000 | GPIOWR_A   |
| 0xF000_0001 | GPIODIR_A  |
| 0xF000_0002 | GPIORD_A   |
| 0xF000_0003 | GPIOWR_B   |
| 0xF000_0004 | GPIODIR_B  |
| 0xF000_0005 | GPIORD_B   |