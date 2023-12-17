# GPIO peripheral
The GPIO (general purpose input-output) peripheral allows programmer to interface with the outside world using digital (HIGH, LOW) values.
These values can be either read to or written from the 16 available ports.

## Hardware implementation
Whole GPIO is implementated in the `gpio.sv` file.

The GPIO peripheral principle is very simple. It consists of three types of registers:
- `GPIODIR`: directions of the ports.
    - `0`: input
    - `1`: output
- `GPIOWR`: value to be written to the ports if a write mode is active.
- `GPIORD`: values to be read by software.

Apart from these registers, there is also a tri-state buffer. Depending on the value of the `GPIODIR`,
the tri-state buffer of the corresponding register is either in high-impedance state (0) or output state (1).
- In high-impedance state, the port works as an input and the value can be read from the `GPIORD` register.
- In output state, the port works as an output and the value to be output can be written to the `GPIOWR` register.

For better understanding, please consult a scheme in the picture below. In the scheme `x` can be `A` or `B`, `y` corresponds to a specific bit.

![GPIO hardware scheme](../img/scheme-gpio.svg)

The description uses `Z` values to instuct synthesis tools to infer tri-state buffers. In Xilinx's Vivado it was verified that
the synthesis infers `IOBUF` blocks.

## Mapping of ports to registers
For now there are 16 ports:
- Ports 0-7 are interfaced with by `_A` registers (`GPIODIR_A`...).
- Ports 8-15 with `_B` registers.

Ports in registers are indexed as usual: port 0 corresponds to lowest bit (bit 0) in its register, port 1 to bit 1, etc. See diagram below:
```
GPIODIR_A, GPIOWR_A, GPIORD_A:
76543210
     |||
     ||+ port 0
     |+  port 1
     +   port 2
         etc.

GPIODIR_B, GPIOWR_B, GPIORD_B:
76543210
     |||
     ||+ port 8
     |+  port 9
     +   port 10
         etc.
```

## Usage in C code
Every register is mapped to the main address space reachable from the C firmware code. Just include `vesp.h` header to be able to use all of the registers.
See examples software examples to check practical usages of these registers.
