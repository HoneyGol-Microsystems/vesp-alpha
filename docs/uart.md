# UART Peripheral
The UART peripheral implements a configurable UART transmitter and receiver. Its meant to be used either "standalone" or using some additional physical layer (such as RS232).

## Suported configurations
- Baud rates: ~7 200 up to ~230 400. See Baud rate table.
- Data bits: 5 - 8
- Parity: none/even/odd
- Stop bits: one/two

### Baud rate table
Baud rate is configured using Config rester A, bits 7-3. See table below for bits values and corresponding standard baud rates.

*Please note that because the main clock cannot be devided precisely, real baud rate will be a bit different (real values are also provided in the table). The error is less than 5 % and so tolerable by majority of UART transceivers.*

| Config value | Corresponding baud rate | Real baud rate |
| ---- | ----- | ------- |
| 0 | 230 400 | 223 214 |
| 1 | 115 200 | 111 607 |
| 2 | 76 800 | 74 404 |
| 3 | 56 000 | 55 803 |
| 5 | 38 400 | 37 202 |
| 6 | 31 250 | 31 887 |
| 10 | 19 200 | 20 292 |
| 14 | 14 400 | 14 880 |
| 22 | 9 600 | 9 704 |
| 30 | 7 200 | 7 200 |

## Verified compatible ICs
The peripheral was tested with FTDI FT2232HQ for both receiving and transmitting.

##  Memory mapped registers
| addr | name | access | comment |
| ---- | ----- | ------- | ------ |
| 0 | TX data | R+W | enqueue data to send |
| 1 | RX data | R | get data from receive queue |
| 2 | config register A | R+W | - |
| 3 | config register B | R+W | - |
| 4 | status register A | R | - |
| 5 | interrupt flag register | R+W | - |
| 6 | reserved | - | - |

### TX data
| bits | usage | comment |
| ---- | ----- | ------- |
| 7-0 | enqueue TX data | add outgoing data to transmission queue |

### RX data
| bits | usage | comment |
| ---- | ----- | ------- |
| 7-0 | access RX data | access first incoming byte in receive queue |

### Config register A
| bits | usage | comment |
| ---- | ----- | ------- |
| 7-3 | clock divisor | divides main frequency and thus determines baudrate |
| 2 | enable irq on TX queue empty | - |
| 1 | enable irq on RX queue full | - |
| 0 | enable irq on parity error | - |

### Config register B
| bits | usage | comment |
| ---- | ----- | ------- |
| 7-6 | parity type | 0: no, 1: even, 2-3: odd |
| 5-4 | data bits count | count = value + 5 |
| 3 | double stop bits | 0: no, 1: yes |
| 2 | enable irq on stop bit error | - |
| 1-0 | reserved | - |

### Status register A
| bits | meaning | comment |
| ---- | ----- | ------- |
| 7 | TX queue full | 1 if TX queue is full |
| 6 | RX queue empty | 1 if RX queue is empty |
| 5-0 | reserved | - |

### Interrupt flag register
| bits | meaning | comment |
| ---- | ----- | ------- |
| 7 | TX queue empty IF | - |
| 6 | RX queue full IF | - |
| 5 | parity error IF | - |
| 4 | stop bit error IF | - |
| 3-0 | reserved | - |

## Software support

## Hardware implementation
As a reference frequency, UART uses system clock (50 MHz), which is then divided to create a main UART clock. The clock frequency is 100/14, which is roughly equal to 3.5714, close to the 1.8432 (8250 UART's clock) times two. This allows to support up to 223 214 bps.

*