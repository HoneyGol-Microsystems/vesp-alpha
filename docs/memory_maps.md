# Memory mapping
For now there is only one platform supporting only bare-metal programs.

## BARE01
| Address | Usage |
|---------|-------|
| 0x0000_0000-0xEFFF_FFFF | User program and data |
| 0xF000_0000-0xFFFF_FFFF | Platform reserved (MMIO etc.) |

### Platform reserved area
| Address | Usage |
|---------|-------|
| 0xF000_0000 | Debug LEDs 0-7 |
| 0xF000_0000 | Debug LEDs 8-15 |

#### Debug LEDs
These two bytes are always connected to some debugging or status LEDs. They can be used for initial testing and diagnosis.
In a case of Basys3 board, LD15-LD0 are connected to these addresses.