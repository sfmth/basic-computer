# basic-computer
Verilog Implementation of the Basic Computer introduced in the book "Computer System Architecture by M. Morris Mano"

A Verilog implementation of the basic computer described in the book "Computer System Architecture - Morris Mano" (Chapter 5)

This code is a behavioural description of the hardware rather than a dataflow (RTL) description, the technique for implementing the behavioural model of a simple processor was borrowed from the book "Verilog Digital System Design - Zainalabedin Navabi" (Chapter 10)

Memory is defined inside the main module and there isn't a separate module for it since I had problems with putting the memory in a seperate module.

### Passed Functional Analysis and compilation using Quartus Prime Lite 20.1.1.

## HOW TO USE
The initial block at line 37 defines memory data and you can program the processor by modifying that part.
You can simulate it using the RTL simulation in Quartus Prime. Module basic_computer_test provides the clock for the basic computer.

#### Example:

In this test we run the following program which evaluates the equation 1 + 1 = 2:

000 LDA 003

001 ADD 003

002 STA 004

003 DATA 001

004 EMPTY xxx

This program loads the contents of address 003 in the AC register (000), then adds the contents of the 003 address to the AC register (001), then stores the results in the 004 address of memory (002), 003 contains the data to be added to itself which in this case is equal to 1, and the 004 memory is not known since there isn't anything written to it at the begining and it changes when the answer is calculated and stored in it.

The following image shows the simulation results of this program and the last row is the memory cell 004 and it changes to "10" after a while, showing that the calculation of 1 + 1 has been successful:

![image_2022-05-09_22-44-01](https://user-images.githubusercontent.com/23662796/168422762-7aa8bd8c-36fc-41bb-afbe-68e2087b6561.png)



### Notes:
- Input Output ports don't work.
- HLT, CIR, CIL don't work.

