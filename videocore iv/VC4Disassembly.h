//
//  VC4Disassembly.h
//  videocore iv
//
//  Created by Pascal Werz on 05/02/2016.
//  Copyright © 2016 Pascal Werz. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Hopper/Hopper.h>

@class VC4Context;

int disassemble(VC4Context * context, DisasmStruct * disasm, NSUInteger mode);

int scalar16(uint16_t w0, VC4Context * context, DisasmStruct * disasm, NSUInteger mode);
int scalar32(uint16_t w0, VC4Context * context, DisasmStruct * disasm, NSUInteger mode);
int scalar48(uint16_t w0, VC4Context * context, DisasmStruct * disasm, NSUInteger mode);
int vector48(uint16_t w0, VC4Context * context, DisasmStruct * disasm, NSUInteger mode);
int vector80(uint16_t w0, VC4Context * context, DisasmStruct * disasm, NSUInteger mode);

uint32_t bits(uint32_t x, int bit, int size);
uint32_t bits2(uint32_t x, int bit2, int size2, int bit1, int size1);
int32_t msbextendedbits(uint32_t x, int bit, int size);
int32_t msbextendedbits2(uint32_t x, int bit2, int size2, int bit1, int size1);
int32_t float6(uint32_t imm);
