# videocore-iv
### VideoCore IV VPU plugin for Hopper Disassembler

This project is a **VideoCore IV VPU** plugin for [Hopper Disassembler](http://www.hopperapp.com/)

The VideoCore IV is the graphic processor found, among others, in the Raspberry Pi. It contains a dual core VPU (Vector Processing Unit) and QPUs (floating-point Quad Processor Units).

At reset or power on, the VPUs are the only processors to run, they are responsible for initializing and starting the QPU and ARM cores. The VPUs run the so-called 'firmware' contained in the closed-source files `/boot/bootcode.bin` and `/boot/start*.elf`.

The target processor of this plugin is the **VPU**, not the QPU (which is documented).

#### WARNING

As there is no official documentation for the VideoCore IV VPU, this work is based on various unofficial resources referenced below as well as some own research.

#### BUILDING THE PLUGIN

To build, clone or download the sources, then open the XCode project and build the plugin. Once built, double-click on the plugin. Alternatively, the plugin can be moved in the ~/Library/Application Support/Hopper/Plugins/v4/CPUs folder (that must be created, if needed).

#### NOTE

Hopper Disassembler version 4.2.19 (or greater) is **required**. This plugin will not load with any previous version.

This plugin tries to make full use of Hopper capabilities, but its edges are still rough:

* This project is at an early stage and very little testing has been done,
* Take disassembled vector operations with caution,
* Code is not yet analyzed.

This plugin was developed on OS X, it has not been tested on Linux. I don’t even know if plugins are supported on the Linux version of Hopper. If you manage to use it on Linux, please let me know.

Most documentation used was found (or is referenced) [here](https://github.com/hermanhermitage/videocoreiv). The most useful source is the unofficial [VideoCore IV Programmers Manual](https://github.com/hermanhermitage/videocoreiv/wiki/VideoCore-IV-Programmers-Manual).


Pascal Werz (a.k.a. xvi);