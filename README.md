# Basic 5 Stage Pipelined CPU 

## Reference

John L. Hennessy and David A. Patterson. (2017). *Computer Architecture: A Quantitative Approach, Sixth Edition.* Morgan Kaufmann Publishers Inc.

## Folders

- document: report and figures
- script: tcl scripts to setup the project and generate bitstream
- source: Verilog sources and headers
- program: test assembly program and its binary file
- constraint: xdc constraint file
- simulation: Verilog CPU simulation files & wave configuration file

## Requirements

`makefile` in this repository is only tested on Windows. Please make sure Vivado is installed and added to `PATH`.

## Debug VGA

If you want the debug VGA module to be added, uncomment the `define` code in `./source/header/debug.vh`.

## Setup Project

To setup the Vivado project, enter following make command:

```bash
make setup
```

## Generate Bitstream

To generate bitstream, enter

```bash
make compile
```

if you already setup the project, or just enter

```bash
make
```

which will automatically setup and compile.

## Clean

To clean the repository, enter

```bash
make clean
```

