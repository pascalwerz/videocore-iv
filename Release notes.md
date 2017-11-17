# Release notes for VideoCore IV VPU plugin for Hopper

### v0.1.0 - 08-MAR-2016

* First version. Compiled with Xcode 8.1 for Hopper Disassembler v4.
* Syntax matches as near as possible what looks like the real one (as found on various websites and on the raspi-internals mailing list) with possible differences listed below.
* `r24` is listed as `gp`, the global pointer; `r28` as `esp`, the exception stack pointer; `r29` as `tp`, the thread pointer.
* useless operands have been dropped, e.g. in unary operations like `not rd, ra, rb`, `ra` is useless, so `not rd, rb` is output). This is true for integer, floating and vector operands.
* multiple registers `stm`/`ldm` register range `rn-rm` will be reduced to `rn` if a single register is moved.
* `st rs,(--sp)` is listed as `push rs`, `ld rd,(sp++)` is listed as `pop rd`.
* operands with null offset indirect access such as `(r6+0x0)` are instead listed as `(r6)`, i.e. the null offset is dropped.
* operands with offsets relative to pc such as `(pc+0x12)` are listed as an absolute address reference, e.g. `(0x0cec0012)`.
* `addscale`/`subscale` with immediate right operand are listed with the immediate operand already shifted, dropping the trailing `<<`, e.g. `addscale r4, #0x4<<3` is listed as `addscale r4, #0x20`.
* Vector transfer instructions size are listed as `v8<op>`, `v16<op>` or `v32<op>`, not `v<op>b`, `v<op>h`, `v<op>l`.
* Vector data instructions size are listed as `v16<op>` or `v32<op>`.
* `readacc` instruction size are `s16`, `s32` and `32`, where `s` stands or 'saturating'.
* vector names are `h8(y,x)`, `h16(y,x)`, `h32(y,x)`, etc.
* some vector instructions may be different in 16 bits and 32 bits width (one of which is frequently `vzero`).
* some discovered instructions are new, such as `vsaturate`, branch to absolute address…
* vector B operand encoding for vector80 instructions enhanced for some more discovered cases.
* switch instructions offset tables are not adequately decoded.
