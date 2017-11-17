//
//  VC4Context.h
//  videocore iv
//
//  Created by Pascal Werz on 05/02/2016.
//  Copyright © 2016 Pascal Werz. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Hopper/Hopper.h>

#import "VC4Definition.h"
#import "VC4Disassembly.h"

enum
{
    VC4_OPERAND_DATA_END,               //  -
    VC4_OPERAND_DATA_STRING,            //  str
    VC4_OPERAND_DATA_STRINGARRAY,       //  str     index
    VC4_OPERAND_DATA_REGISTERGP,        //  id
    VC4_OPERAND_DATA_REGISTERSTRING,    //  str
    VC4_OPERAND_DATA_SIGNED,            //  value   width
    VC4_OPERAND_DATA_UNSIGNED,          //  value   width
    VC4_OPERAND_DATA_DECIMAL,           //  value
    VC4_OPERAND_DATA_VALUE,             //  value   width
    VC4_OPERAND_DATA_VALUECANBESIGNED,  //  value   width   signed
    VC4_OPERAND_DATA_VALUEWITHSIGN,     //  value   width
    VC4_OPERAND_DATA_FLOAT32,           //  value   width
    VC4_OPERAND_DATA_ADDRESS32,         //  address
    VC4_OPERAND_DATA_ADDRESS64,         //  address
    VC4_OPERAND_DATA_RA48,              //  x       f       rs
    VC4_OPERAND_DATA_RB48,              //  x       f       rs
    VC4_OPERAND_DATA_RD48,              //  x       f       rs
    VC4_OPERAND_DATA_RA80,              //  x       f       h
    VC4_OPERAND_DATA_RB80,              //  x       f
    VC4_OPERAND_DATA_RD80               //  x       f
};

#define DISASM_OPERAND0(o) disasm->operand[arg].userData[udx++]=(uint64_t) o
#define DISASM_OPERAND1(o,x) do {DISASM_OPERAND0(o); DISASM_OPERAND0(x);} while (0)
#define DISASM_OPERAND2(o,x,y) do {DISASM_OPERAND1(o,x); DISASM_OPERAND0(y);} while (0)
#define DISASM_OPERAND3(o,x,y,z) do {DISASM_OPERAND2(o,x,y); DISASM_OPERAND0(z);} while (0)

#define OPERAND_END DISASM_OPERAND0(VC4_OPERAND_DATA_END)
#define OPERAND_RAWSTRING(string) DISASM_OPERAND1(VC4_OPERAND_DATA_STRING,string)
#define OPERAND_STRINGARRAY(array,index) DISASM_OPERAND2(VC4_OPERAND_DATA_STRINGARRAY,array,index)
#define OPERAND_REGISTERGP(reg) DISASM_OPERAND1(VC4_OPERAND_DATA_REGISTERGP,reg)
#define OPERAND_REGISTERSTRING(reg) DISASM_OPERAND1(VC4_OPERAND_DATA_REGISTERSTRING,reg)
#define OPERAND_SIGNED(value,width) DISASM_OPERAND2(VC4_OPERAND_DATA_SIGNED,value,width)
#define OPERAND_UNSIGNED(value,width) DISASM_OPERAND2(VC4_OPERAND_DATA_UNSIGNED,value,width)
#define OPERAND_DECIMAL(value) DISASM_OPERAND1(VC4_OPERAND_DATA_DECIMAL,value)
#define OPERAND_VALUE(value,width) DISASM_OPERAND2(VC4_OPERAND_DATA_VALUE,value,width)
#define OPERAND_VALUECANBESIGNED(value,width,issigned) DISASM_OPERAND3(VC4_OPERAND_DATA_VALUECANBESIGNED,value,width,issigned)
#define OPERAND_VALUEWITHSIGN(value,width) DISASM_OPERAND2(VC4_OPERAND_DATA_VALUEWITHSIGN,value,width)
#define OPERAND_FLOAT32(value) DISASM_OPERAND1(VC4_OPERAND_DATA_FLOAT32,value)
#define OPERAND_ADDRESS32(address) DISASM_OPERAND1(VC4_OPERAND_DATA_ADDRESS32,address)
#define OPERAND_ADDRESS64(address) DISASM_OPERAND1(VC4_OPERAND_DATA_ADDRESS64,address)
#define OPERAND_RA48(x,f,rs) DISASM_OPERAND3(VC4_OPERAND_DATA_RA48,x,f,rs)
#define OPERAND_RB48(x,f,rs) DISASM_OPERAND3(VC4_OPERAND_DATA_RB48,x,f,rs)
#define OPERAND_RD48(x,f,rs) DISASM_OPERAND3(VC4_OPERAND_DATA_RD48,x,f,rs)
#define OPERAND_RA80(x,f,h) DISASM_OPERAND3(VC4_OPERAND_DATA_RA80,x,f,h)
#define OPERAND_RB80(x,f) DISASM_OPERAND2(VC4_OPERAND_DATA_RB80,x,f)
#define OPERAND_RD80(x,f) DISASM_OPERAND2(VC4_OPERAND_DATA_RD80,x,f)

@class VC4Definition;

@interface VC4Context : NSObject<CPUContext>
{
@public
    NSObject<HPDisassembledFile> * _file;
    VC4Definition * _cpu;
    NSObject<HPProcedure> * _currentProcedure;
}

- (instancetype)initWithCPU:(VC4Definition *)cpu andFile:(NSObject<HPDisassembledFile> *)file;
- (char *) formattedValue:(uint32_t)value argIndex:(int)argIndex bitWidth:(int)width andPC:(Address) virtualAddress;
- (char *) formattedSigned:(int32_t)value argIndex:(int)argIndex bitWidth:(int)width andPC:(Address) virtualAddress;
- (char *) formattedValueWithSign:(int32_t)value argIndex:(int)argIndex bitWidth:(int)width andPC:(Address) virtualAddress;
- (char *) formattedUnsigned:(uint32_t)value argIndex:(int)argIndex bitWidth:(int)width andPC:(Address) virtualAddress;
- (char *) formattedAddress:(uint32_t)value argIndex:(int)argIndex andPC:(Address) virtualAddress;
- (char *) formattedValue:(uint32_t)value defaultAsSigned:(BOOL)defaultSigned argIndex:(int)argIndex bitWidth:(int)width andPC:(Address)virtualAddress;
- (char *) formattedFloat:(int32_t)value argIndex:(int)argIndex bitWidth:(int)width andPC:(Address) virtualAddress;

@end
