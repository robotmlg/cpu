# Matt Goldman
# CS 505
# Final Project Description

Compile with $ make
Run with cpu.test.run +img=<imgfile>

Note: This project was written on a Mac, so the Makefile may need to be modified
to function on Linux (or Windows, I guess).  Specifically, on line 19, you may
need to change ``gsed'' to just ``sed'' (Mac sed isn't strictly gnu compatible).

-------------------------------------------------------------------------------

##Intro

Here is a very basic implementation of a 5-stage pipeline.  The x86 instruction
subset implemented here is very small.  I spent a majority of my time working
out kinks in the inter-stage communication process, eventually settling on a
quite hacky method in which the sending stage must wait a couple cycles for the
receiving stage to obtain the data.

## Memory

I use the provided memory cell system to store the instructions.

TODO:
- implement writing to memory

## Fetch

Implemented instructions:
- 0x00-0x5F

My fetch stage is heavily based on my combined fetch/decode from warm-up 2.
(you can see the leftover infrastructure commented out.)  As the process of
implementing more instructions stretched on, I elected to implement fewer 
instructions so that I could move on to other pipeline stages.  I have a
writeback pathway implemented for branch instructions, althought since I
cannot fetch or decode branch instructions, this remains untested.

TODO: 
- fetch the rest of the instruction set
- test the PC input

## Decode

Implemented instructions:
- 0x00-0x5F

Again, this is heavily based on my warm-up 2 submission.  

TODO: 
- decode the rest of the instruction set

## Memory

My memory stage contains the register file within it for reading the operand
values.  It also determines which register is the destination register for the
instruction and marks that register as dirty.  If one of the source registers
is marked as dirty, this stage stalls until it is marked as clean again by
the writeback stage

TODO:
- implement communication with the memory module for LOAD instructions

## Execute

Implemented instructions:
- XOR

My execute stage contains the alu from warm-up 1, for the intended purpose of
executing aritmetic instructions.  However, I chose to forgo hooking up the alu
module so that I could spend more time working on other modules.  I only 
implemented the XOR instruction as it is the first instruction in all my test
files (the classic xor %ebp, %ebp to zero it out).

TODO: 
- implement more than just XOR

## Writeback

My writeback module is just about the bare minimum needed to be called a
``writeback'' module.  The only implemented feature is to writeback the PC from
a branch instruction, although I did not implement branch instructions so this 
is untested.

TODO:
- implement memory writeback
- implement regfile writeback


## Conclusion

This project was extremely interesting to me.  I only wish that I had devoted
the time it deserved to it.  I'm definitely considering finishing up this project
over the summer for my own edification.

Global TODO:
- implement pipeline flush mechanism
- implement stack for POP/PUSH instructions
- implement I-cache and D-cache
