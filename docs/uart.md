# UART Peripheral

Main frequency: UART will use reference clock 100/27, which is roughly equal to 3.7037, close to the 1.8432 (8250 UART's clock) times two. This allows to support up to 231 481 bps.

##  Registers
| addr | name | access | comment |
| ---- | ----- | ------- | ------ |
| 0 | tx data | R+W | enqueue data to send |
| 1 | rx data | R | get data from receive queue |
| 2 | config register A | R+W | - |
| 3 | config register B | R+W | - |
| 4 | reserved | R+W | - |
| 5 | status register A | R | - |
| 6 | interrupt flag register | R+W | writing in form of reset only |
| 7 | reserved | R+W | - |

### TX data
| bits | usage | comment |
| ---- | ----- | ------- |
| 7-0 | enqueue tx data | add outgoing data to transmission queue |

### RX data
| bits | usage | comment |
| ---- | ----- | ------- |
| 7-0 | access rx data | access first incoming byte in receive queue |

### Config register A
| bits | usage | comment |
| ---- | ----- | ------- |
| 7-3 | clock divisor | divides main frequency and thus determines baudrate |
| 2 | enable irq on tx queue empty | |
| 1 | enable irq on rx queue full | |
| 0 | enable irq on parity error | |

### Config register B
| bits | usage | comment |
| ---- | ----- | ------- |
| 7-6 | parity type | 0: no, 1: even, 2-3: odd |
| 5-4 | data bits count | count = value + 5 |
| 3 | double stop bits | 0: no, 1: yes |
| 2 | enable irq on stop bit error | |
| 1-0 | reserved | |

### Status register A
| bits | meaning | comment |
| ---- | ----- | ------- |
| 7 | tx queue full | 1 if tx queue is full |
| 6 | rx queue empty | 1 if rx queue is empty |
| 5-0 | reserved | |

### Interrupt flag register
| bits | meaning | comment |
| ---- | ----- | ------- |
| 7 | tx queue empty IF |  |
| 6 | rx queue full IF | |
| 5 | parity error IF | |
| 4 | stop bit error IF | |
| 3-0 | reserved | |

