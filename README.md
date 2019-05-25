# videocore-iv
### VideoCore IV VPU plugin for Hopper Disassembler

This project is a **VideoCore IV VPU** plugin for [Hopper Disassembler](http://www.hopperapp.com/)

The VideoCore IV is the graphic processor found, among others, in the Raspberry Pi. It contains a dual core VPU (Vector Processing Unit) and QPUs (floating-point Quad Processor Units).

At reset or power on, the VPUs are the only processors to run, they are responsible for initializing and starting the QPU and ARM cores. The VPUs run the so-called 'firmware' contained in the closed-source files `/boot/bootcode.bin` and `/boot/start*.elf`.

The target processor of this plugin is the **VPU**, not the QPU (which is documented).

#### WARNING

As there is no official documentation for the VideoCore IV VPU, this work is based on various unofficial resources referenced below as well as some own research.

#### BUILDING THE PLUGIN (OS X)

To build, clone or download the sources, then open the XCode project and build the plugin. Once built, double-click on the plugin. Alternatively, the plugin can be moved in the ~/Library/Application Support/Hopper/Plugins/v4/CPUs folder (that must be created, if needed).


#### BUILDING THE PLUGIN (Linux)

This version has been tested with the Linux SDK for Hopper 4.3.30. The following steps are required:

    . <PATH_TO_HOPPER_SDK>/Linux/gnustep-Linux-x86_64/share/GNUstep/Makefiles/GNUstep.sh 
    make HOPPER_INCLUDE_PATH=<PATH_TO_HOPPER_SDK>/include
    ln -s `pwd`/VC4CPU.bundle ~/GNUstep/Library/ApplicationSupport/Hopper/PlugIns/v4/CPUs/VC4CPU.hopperCPU


#### NOTE

Hopper Disassembler version 4.2.19 (or greater) is **required**. This plugin will not load with any previous version.

This plugin tries to make full use of Hopper capabilities, but its edges are still rough:

* This project is at an early stage and very little testing has been done,
* Take disassembled vector operations with caution,
* Code is not yet analyzed.

Most documentation used was found (or is referenced) [here](https://github.com/hermanhermitage/videocoreiv). The most useful source is the unofficial [VideoCore IV Programmers Manual](https://github.com/hermanhermitage/videocoreiv/wiki/VideoCore-IV-Programmers-Manual).


Pascal Werz (a.k.a. xvi);
