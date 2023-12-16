# Memory mapping
For now there is only one platform supporting only bare-metal programs.

| Address                 | Usage                         |
|-------------------------|-------------------------------|
| 0x0000_0000-0xEFFF_FFFF | User program and data         |
| 0xF000_0000-0xFFFF_FFFF | Platform reserved (MMIO etc.) |

# Platform reserved area
| Address                 | Usage |
|-------------------------|-------|
| 0xF000_0000-0xF000_000F | GPIO  |
| 0xF000_0010-0xF000_001F | UART  |

## GPIO
| Address                 | Usage     |
|-------------------------|-----------|
| 0xF000_0000             | GPIOWR_A  |
| 0xF000_0001             | GPIODIR_A |
| 0xF000_0002             | GPIORD_A  |
| 0xF000_0003             | GPIOWR_B  |
| 0xF000_0004             | GPIODIR_B |
| 0xF000_0005             | GPIORD_B  |
| 0xF000_0006-0xF000_000F | reserved  |

## UART
| Address                 | Usage         |
|-------------------------|---------------|
| 0xF000_0010             | UART_TX_DATA  |
| 0xF000_0011             | UART_RX_DATA  |
| 0xF000_0012             | UART_CONFIG_A |
| 0xF000_0013             | UART_CONFIG_B |
| 0xF000_0014             | UART_STATUS_A |
| 0xF000_0015             | UART_IF_REG   |
| 0xF000_0016-0xF000_001F | reserved      |