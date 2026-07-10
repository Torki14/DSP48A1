# DSP48A1
• Architected a parameterized DSP48A1 DSP-slice RTL model in Verilog from the Xilinx UG389 specification, imple
menting the pre-adder/subtracter, 18x18 two’s-complement multiplier, dual-path X/Z post-adder multiplexers, and
configurable pipeline registers (A, B, C, D, M, P, OPMODE, Carry) via a reusable parameterized bypassable-register
submodule.
• Developed a directed, self-checking Verilog testbench with a software-computed golden reference model covering mul
tiply, multiply-accumulate, pre-adder add/subtract, 48-bit wide-adder, and post-adder subtract operating modes, plus
synchronous reset verification.
• Validated the design through the complete Vivado flow (elaboration, synthesis, implementation) targeting a Spartan-6
FPGA, with linting to a clean, warning-free methodology report.
