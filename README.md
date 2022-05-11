# basic-computer
Verilog Implementation of the Basic Computer introduced in the book "Computer System Architecture by M. Morris Mano"

A Verilog implementation of the basic computer described in the book "Computer System Architecture - Morris Mano" (Chapter 5)

This code is a behavioural description of the hardware rather than a dataflow (RTL) description, the technique for implementing the behavioural model of a simple processor was borrowed from the book "Verilog Digital System Design - Zainalabedin Navabi" (Chapter 10)

Memory is defined inside the main module and there isn't a separate module for it since I had problems with putting the memory in a seperate module.

### Passed Functional Analysis and compilation using Quartus Prime Lite 20.1.1.

## HOW TO USE
The initial block at line 37 defines memory data and you can program the processor by modifying that part.
You can simulate it using the RTL simulation in Quartus Prime. Module basic_computer_test provides the clock for the basic computer.

### Notes:
- Input Output ports don't work.
- HLT, CIR, CIL don't work.
