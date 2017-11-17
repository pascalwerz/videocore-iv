//
//  VC4Disassembly.m
//  videocore iv
//
//  Created by Pascal Werz on 05/02/2016.
//  Copyright © 2016 Pascal Werz. All rights reserved.
//

#import "VC4Disassembly.h"
#import "VC4Context.h"
#import "VC4Definition.h"
#import "VC4InstructionDefs.h"



char *sign[2] = { "s", "u" };



BOOL signIsSigned[2] = { YES, NO };



int regbase[4] = { REG_R0, REG_R6, REG_R16, REG_GP };



char *regname[32] =
{
    "r0"  ,"r1" ,"r2" ,"r3" ,"r4" ,"r5" ,"r6" ,"r7" ,
    "r8"  ,"r9" ,"r10","r11","r12","r13","r14","r15",
    "r16" ,"r17","r18","r19","r20","r21","r22","r23",
    "gp"  ,"sp" ,"lr" ,"r27","esp","tp", "sr" ,"pc"
};



char *procControlRegName[32] =
{
    "prfpxcs", "prcanary", "p2",       "p3",       "p4",       "p5",       "p6",      "p7",
    "p8",      "p9",       "prpowctl", "prtimctl", "prcortim", "prslptim", "prowcnt", "prorcnt",
    "prspinl", "p17",      "p18",      "p19",      "p20",      "p21",      "p22",     "p23",
    "p24",     "p25",      "p26",      "p27",      "p28",      "p29",      "p30",     "p31"
};



char *condition[16] =
{
    "eq", "ne", "lo", "hs",
    "mi", "pl", "vs", "vc",
    "hi", "ls", "ge", "lt",
    "gt", "le", ""  , "f"
};



char *conditionWithSeparator[16] =
{
    ".eq", ".ne", ".lo", ".hs",
    ".mi", ".pl", ".vs", ".vc",
    ".hi", ".ls", ".ge", ".lt",
    ".gt", ".le", ""  ,  ".f"
};



DisasmBranchType branchtype[16] =
{
    DISASM_BRANCH_JE, DISASM_BRANCH_JNE, DISASM_BRANCH_JC,  DISASM_BRANCH_JNC,
    DISASM_BRANCH_JS, DISASM_BRANCH_JNS, DISASM_BRANCH_JNO, DISASM_BRANCH_JO,
    DISASM_BRANCH_JA, DISASM_BRANCH_JNA, DISASM_BRANCH_JGE, DISASM_BRANCH_JL,
    DISASM_BRANCH_JG, DISASM_BRANCH_JLE, DISASM_BRANCH_JMP, DISASM_BRANCH_NONE
};



DisasmCondition conditioncondition[16] =
{
    DISASM_INST_COND_EQ, DISASM_INST_COND_NE, DISASM_INST_COND_CS, DISASM_INST_COND_CC,
    DISASM_INST_COND_MI, DISASM_INST_COND_PL, DISASM_INST_COND_VC, DISASM_INST_COND_VS,
    DISASM_INST_COND_HI, DISASM_INST_COND_LS, DISASM_INST_COND_GE, DISASM_INST_COND_LT,
    DISASM_INST_COND_GT, DISASM_INST_COND_LE, DISASM_INST_COND_AL, DISASM_INST_COND_NEVER
};



char *operation[32] =
{
    "mov",     "cmn", "add",      "bic",      "mul",     "eor",      "sub",      "and",
    "not",     "ror", "cmp",      "rsub",     "btest",   "or",       "bmask",    "max",
    "bitset",  "min", "bitclear", "addscale", "bitflip", "addscale", "addscale", "addscale",
    "signext", "neg", "lsr",      "msb",      "shl",     "brev",     "asr",      "abs"
};



char *operationRight[32] =
{
    "",        "",    "",         "",         "",       "",         "",          "",
//  "mov",     "cmn", "add",      "bic",      "mul",     "eor",      "sub",      "and",
    "",        "",    "",         "",         "",        "",         "",         "",
//  "not",     "ror", "cmp",      "rsub",     "btest",   "or",       "bmask",    "max",
    "",        "",    "",         "<<1",      "",        "<<2",      "<<3",      "<<4",
//  "bitset",  "min", "bitclear", "addscale", "bitflip", "addscale", "addscale", "addscale",
    "",        "",    "",         "",         "",        "",         "",         "",
//  "signext", "neg", "lsr",      "msb",      "shl",     "brev",     "asr",      "abs"

};



BOOL operationHasRegisterResult[32] =
{
    YES,       NO,    YES,        YES,        YES,       YES,        YES,        YES,
//  "mov",     "cmn", "add",      "bic",      "mul",     "eor",      "sub",      "and",
    YES,       YES,   NO,         YES,        NO,        YES,        YES,        YES,
//  "not",     "ror", "cmp",      "rsub",     "btest",   "or",       "bmask",    "max",
    YES,       YES,   YES,        YES,        YES,       YES,        YES,        YES,
//  "bitset",  "min", "bitclear", "addscale", "bitflip", "addscale", "addscale", "addscale",
    YES,       YES,   YES,        YES,        YES,       YES,        YES,        YES
//  "signext", "neg", "lsr",      "msb",      "shl",     "brev",     "asr",      "abs"
};



BOOL operationHasLeftOperand[32] =
{
    NO,        YES,   YES,        YES,        YES,       YES,        YES,        YES,
//  "mov",     "cmn", "add",      "bic",      "mul",     "eor",      "sub",      "and",
    NO,        YES,   YES,        YES,        YES,       YES,        YES,        YES,
//  "not",     "ror", "cmp",      "rsub",     "btest",   "or",       "bmask",    "max",
    YES,       YES,   YES,        YES,        YES,       YES,        YES,        YES,
//  "bitset",  "min", "bitclear", "addscale", "bitflip", "addscale", "addscale", "addscale",
    YES,       NO,    YES,        NO,         YES,       YES,        YES,        NO
//  "signext", "neg", "lsr",      "msb",      "shl",     "brev",     "asr",      "abs"
};



BOOL operationRightOperandDefaultAsSigned[32] =
{
    NO,        YES,   YES,        NO,         YES,       NO,         YES,        NO,
//  "mov",     "cmn", "add",      "bic",      "mul",     "eor",      "sub",      "and",
    NO,        YES,   YES,        YES,        NO,        NO,          NO,        YES,     // consider ror bitcount as signed!
//  "not",     "ror", "cmp",      "rsub",     "btest",   "or",       "bmask",    "max",
    NO,        YES,   NO,         YES,        NO,        YES,        YES,        YES,
//  "bitset",  "min", "bitclear", "addscale", "bitflip", "addscale", "addscale", "addscale",
    NO,        YES,   NO,         NO,         NO,        NO,         NO,         YES
//  "signext", "neg", "lsr",      "msb",      "shl",     "brev",     "asr",      "abs"
};



// this helps with e.g. rotate counts larger than +/- 32
uint32_t operationRightOperandMask[32] =
{
    -1,        -1,    -1,         31,         -1,        -1,         -1,         -1,
//  "mov",     "cmn", "add",      "bic",      "mul",     "eor",      "sub",      "and",
    -1,        -1,    -1,         -1,         31,        -1,         31,         -1,      // consider ror bitcount as signed, so don't mask it!
//  "not",     "ror", "cmp",      "rsub",     "btest",   "or",       "bmask",    "max",
    31,        -1,    31,         -1,         31,        -1,         -1,         -1,
//  "bitset",  "min", "bitclear", "addscale", "bitflip", "addscale", "addscale", "addscale",
    31,        -1,    31,         -1,         31,        31,         31,        -1
//  "signext", "neg", "lsr",      "msb",      "shl",     "brev",     "asr",      "abs"
};



int operationRightOperandShiftAmount[32] =
{
    0,         0,     0,          0,          0,         0,          0,          0,
//  "mov",     "cmn", "add",      "bic",      "mul",     "eor",      "sub",      "and",
    0,         0,     0,          0,          0,         0,          0,          0,
//  "not",     "ror", "cmp",      "rsub",     "btest",   "or",       "bmask",    "max",
    0,         0,     0,          1,          0,         2,          3,          4,
//  "bitset",  "min", "bitclear", "addscale", "bitflip", "addscale", "addscale", "addscale",
    0,         0,     0,          0,          0,         0,          0,          0
//  "signext", "neg", "lsr",      "msb",      "shl",     "brev",     "asr",      "abs"
};



BOOL operationImpliesWriteToSR[32] =
{
    NO,        YES,   NO,         NO,         NO,        NO,         NO,         NO,
//  "mov",     "cmn", "add",      "bic",      "mul",     "eor",      "sub",      "and",
    NO,        NO,    YES,        NO,         YES,       NO,         NO,         NO,
//  "not",     "ror", "cmp",      "rsub",     "btest",   "or",       "bmask",    "max",
    NO,        NO,    NO,         NO,         NO,        NO,         NO,         NO,
//  "bitset",  "min", "bitclear", "addscale", "bitflip", "addscale", "addscale", "addscale",
    NO,        NO,    NO,         NO,         NO,        NO,         NO,         NO
//  "signext", "neg", "lsr",      "msb",      "shl",     "brev",     "asr",      "abs"
};



char *operation2[32] =  // NULL means invalid op
{
    NULL,       NULL,       NULL,       NULL,       // handled as mulhd<cc>.<zz>
    NULL,       NULL,       NULL,       NULL,       // handled as div<cc>.<zz>
    "adds",     "subs",     "shls",     "clipsh",
    "addscale", "addscale", "addscale", "addscale",
    "count",    "subscale", "subscale", "subscale",
    "subscale", "subscale", "subscale", "subscale",
    "subscale", NULL,       NULL,       NULL,
    NULL,       NULL,       NULL,       NULL,
};



char *operation2Right[32] =
{
    "",         "",         "",         "",
    //  -,          -,          -,          -,
    "",         "",         "",         "",
    //  -,          -,          -,          -,
    "",         "",         "",         "",
    //  "adds",     "subs",     "shls",     "clipsh",
    "<<5",      "<<6",      "<<7",      "<<8",
    //  "addscale", "addscale", "addscale", "addscale",
    "",         "<<1",      "<<2",      "<<3",
    //  "count",    "subscale", "subscale", "subscale",
    "<<4",      "<<5",      "<<6",      "<<7",
    //  "subscale", "subscale", "subscale", "subscale",
    "<<8",      "",         "",         "",
    //  "subscale", -,          -,          -,
    "",         "",         "",         ""
    //  -,          -,          -,          -
};



BOOL operation2HasLeftOperand[32] =
{
    YES,        YES,        YES,        YES,
//  -,          -,          -,          -,
    YES,        YES,        YES,        YES,
//  -,          -,          -,          -,
    YES,        YES,        YES,        NO,
//  "adds",     "subs",     "shls",     "clipsh",
    YES,        YES,        YES,        YES,
//  "addscale", "addscale", "addscale", "addscale",
    NO,         YES,        YES,        YES,
//  "count",    "subscale", "subscale", "subscale",
    YES,        YES,        YES,        YES,
//  "subscale", "subscale", "subscale", "subscale",
    YES,        YES,        YES,        YES,
//  "subscale", -,          -,          -,
    YES,        YES,        YES,        YES,
//  -,          -,          -,          -
};



BOOL operation2PresentRightOperandAsSigned[32] =
{
    NO,         NO,         NO,         NO,
//  -,          -,          -,          -,
    NO,         NO,         NO,         NO,
//  -,          -,          -,          -,
    YES,        YES,        NO,         YES,
//  "adds",     "subs",     "shls",     "clipsh",
    YES,        YES,        YES,        YES,
//  "addscale", "addscale", "addscale", "addscale",
    NO,         YES,        YES,        YES,
//  "count",    "subscale", "subscale", "subscale",
    YES,        YES,        YES,        YES,
//  "subscale", "subscale", "subscale", "subscale",
    YES,        NO,         NO,         NO,
//  "subscale", -,          -,          -,
    NO,         NO,         NO,         NO,
//  -,          -,          -,          -
};



uint32_t operation2RightOperandMask[32] =
{
    -1,         -1,         -1,         -1,
//  -,          -,          -,          -,
    -1,         -1,         -1,         -1,
//  -,          -,          -,          -,
    -1,         -1,         31,         -1,
//  "adds",     "subs",     "shls",     "clipsh",
    -1,         -1,         -1,         -1,
//  "addscale", "addscale", "addscale", "addscale",
    -1,         -1,         -1,         -1,
//  "count",    "subscale", "subscale", "subscale",
    -1,         -1,         -1,         -1,
//  "subscale", "subscale", "subscale", "subscale",
    -1,         -1,         -1,         -1,
//  "subscale", -,          -,          -,
    -1,         -1,         -1,         -1
//  -,          -,          -,          -,
};



int operation2RightOperandShiftAmount[32] =
{
    0,          0,          0,          0,
//  -,          -,          -,          -,
    0,          0,          0,          0,
//  -,          -,          -,          -,
    0,          0,          0,          0,
//  "adds",     "subs",     "shls",     "clipsh",
    5,          6,          7,          8,
//  "addscale", "addscale", "addscale", "addscale",
    0,          1,          2,          3,
//  "count",    "subscale", "subscale", "subscale",
    4,          5,          6,          7,
//  "subscale", "subscale", "subscale", "subscale",
    8,          0,          0,          0,
//  "subscale", -,          -,          -,
    0,          0,          0,          0
//  -,          -,          -,          -
};



int operation2Instruction[32] =
{
    DISASM_UNKNOWN_OPCODE, DISASM_UNKNOWN_OPCODE, DISASM_UNKNOWN_OPCODE, DISASM_UNKNOWN_OPCODE,
    DISASM_UNKNOWN_OPCODE, DISASM_UNKNOWN_OPCODE, DISASM_UNKNOWN_OPCODE, DISASM_UNKNOWN_OPCODE,
    VC4_INST_ADDS,         VC4_INST_SUBS,         VC4_INST_SHLS,         VC4_INST_CLIPSH,
    VC4_INST_ADDSCALE32,   VC4_INST_ADDSCALE64,   VC4_INST_ADDSCALE128,  VC4_INST_ADDSCALE256,
    VC4_INST_COUNT,        VC4_INST_SUBSCALE2,    VC4_INST_SUBSCALE4,    VC4_INST_SUBSCALE8,
    VC4_INST_SUBSCALE16,   VC4_INST_SUBSCALE32,   VC4_INST_SUBSCALE64,   VC4_INST_SUBSCALE128,
    VC4_INST_SUBSCALE256,  DISASM_UNKNOWN_OPCODE, DISASM_UNKNOWN_OPCODE, DISASM_UNKNOWN_OPCODE,
    DISASM_UNKNOWN_OPCODE, DISASM_UNKNOWN_OPCODE, DISASM_UNKNOWN_OPCODE, DISASM_UNKNOWN_OPCODE
};



char *foperation[16] =
{
    "fadd",  "fsub",   "fmul",  "fdiv",
    "fcmp",  "fabs",   "frsub", "fmax",
    "frcp",  "frsqrt", "fnmul", "fmin",
    "fceil", "ffloor", "flog2", "fexp2",
};



BOOL foperationHasRegisterResult[16] =
{
    YES, YES, YES, YES,
    NO,  YES, YES, YES,
    YES, YES, YES, YES,
    YES, YES, YES, YES
};



BOOL foperationHasLeftOperand[16] =
{
    YES, YES, YES, YES,
    YES, NO,  YES, YES,
    NO,  NO,  YES, YES,
    NO,  NO,  NO,  NO
};



char *foperation2[4] =
{
    "ftrunc", "floor", "flts", "fltu",
};



char *foperation2Right[4] =
{
    "sasl", "sasl", "sasr", "sasr"
};



char *opSizeSuffix[4] =
{
    "", "h", "b", "hs"
};



char * opSizeShift[4] =
{
    "<<2", "<<1", "", "<<1"
};



int opBitWidth[4] =
{
    32, 16, 8, 16
};



ByteType byteTypeForOpWidth[4] =
{
    Type_Int32, Type_Int16, Type_Int8, Type_Int16
};



uint32_t mask(int width)
{
    return (1 << width) - 1;
}



uint32_t bits(uint32_t x, int bit, int size)
{
    if (size == 0) return 0;
    x >>= bit - size + 1;
    x &= mask(size);

    return x;
}



uint32_t bits2(uint32_t x, int bit2, int size2, int bit1, int size1)
{
    int32_t r;

    r = (bits(x, bit2, size2) << size1) | bits(x, bit1, size1);

    return r;
}



int32_t msbextendedbits(uint32_t x, int bit, int size)
{
    if (size == 0) return 0;
    x >>= bit - size + 1;
    x &= mask(size);
    if (x & (1 << (size - 1))) x -= 1 << size;

    return (int32_t) x;
}



int32_t msbextendedbits2(uint32_t x, int bit2, int size2, int bit1, int size1)
{
    int32_t r;

    r = (bits(x, bit2, size2) << size1) | bits(x, bit1, size1);
    size1 += size2;
    if (r & (1 << (size1 - 1))) r -= 1 << size1;

    return r;
}



int32_t float6(uint32_t imm)
{
    int32_t f;
    int exponent;
    int mantissa;

    f = 0;

    // sign
    if (imm & 0x20) f |= 0x80000000;

    exponent = (imm >> 0x2) & 0x7;
    if (exponent != 0)
    {
        f |= (exponent + 0x7c) << 0x17;
        mantissa = imm & 0x3;
        f |= mantissa << 0x15;
    }

    return f;
}



int disassemble(VC4Context * context, DisasmStruct * disasm, NSUInteger mode)
{
    uint16_t w0;
    int instLength;

    if (disasm->virtualAddr & 1) return DISASM_UNKNOWN_OPCODE;  // don't even try to disassemble at odd addresses

    disasm->syntaxIndex = 0;
    memset(&disasm->prefix, 0, sizeof(disasm->prefix));
    memset(disasm->implicitlyReadRegisters, 0, sizeof(disasm->implicitlyReadRegisters));
    memset(disasm->implicitlyWrittenRegisters, 0, sizeof(disasm->implicitlyWrittenRegisters));
    disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] = 1 << REG_PC;
    disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] = 1 << REG_PC;

    disasm->instruction.mnemonic[0] = 0;
    disasm->instruction.unconditionalMnemonic[0] = 0;
    disasm->instruction.condition = DISASM_INST_COND_AL;
    disasm->instruction.userData = VC4_INST_OTHER;   // holds the instruction code.
    disasm->instruction.branchType = DISASM_BRANCH_NONE;
    memset(&disasm->instruction.eflags, 0, sizeof(disasm->instruction.eflags));
    disasm->instruction.addressValue = BAD_ADDRESS;
    disasm->instruction.pcRegisterValue = disasm->virtualAddr;

    for (int i = 0; i < DISASM_MAX_OPERANDS; i++)
    {
        for (int j = 0; j < DISASM_MAX_USER_DATA; j++) disasm->operand[i].userData[j] = VC4_OPERAND_DATA_END; // holds the operand formatting
        disasm->operand[i].type = DISASM_OPERAND_NO_OPERAND;
        disasm->operand[i].size = 0;
        disasm->operand[i].accessMode = DISASM_ACCESS_NONE;
        memset(&disasm->operand[i].memory, 0, sizeof(disasm->operand[i].memory));
        disasm->operand[i].memoryDecoration = 0;
        disasm->operand[i].shiftMode = DISASM_SHIFT_NONE;
        disasm->operand[i].shiftAmount = 0;
        disasm->operand[i].shiftByReg = 0;
        disasm->operand[i].isBranchDestination = NO;
    }

    w0 = [context->_file readUInt16AtVirtualAddress:disasm->virtualAddr];

         if ((w0 & 0xf800) == 0xf800) instLength = vector80(w0, context, disasm, mode);
    else if ((w0 & 0xf800) == 0xf000) instLength = vector48(w0, context, disasm, mode);
    else if ((w0 & 0xf000) == 0xe000) instLength = scalar48(w0, context, disasm, mode);
    else if ((w0 & 0x8000) == 0x8000) instLength = scalar32(w0, context, disasm, mode);
    else                              instLength = scalar16(w0, context, disasm, mode);

    if (instLength != DISASM_UNKNOWN_OPCODE)
        disasm->instruction.length = instLength;

    return instLength;
}



int scalar16(uint16_t w0, VC4Context * context, DisasmStruct * disasm, NSUInteger mode)
{
    int arg = 0;
    int udx = 0;

    if (w0 == 0x0000)
    {
        strcpy(disasm->instruction.mnemonic, "bkpt");
        disasm->instruction.userData = VC4_INST_BKPT;

        return 2;
    }
    else if (w0 == 0x0001)
    {
        strcpy(disasm->instruction.mnemonic, "nop");
        disasm->instruction.userData = VC4_INST_NOP;

        return 2;
    }
    else if (w0 == 0x0002)
    {
        strcpy(disasm->instruction.mnemonic, "sleep");
        disasm->instruction.userData = VC4_INST_SLEEP;

        return 2;
    }
    else if (w0 == 0x0003)
    {
        strcpy(disasm->instruction.mnemonic, "user");
        disasm->instruction.userData = VC4_INST_USER;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 2;
    }
    else if (w0 == 0x0004)
    {
        strcpy(disasm->instruction.mnemonic, "ei");
        disasm->instruction.userData = VC4_INST_EI;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 2;
    }
    else if (w0 == 0x0005)
    {
        strcpy(disasm->instruction.mnemonic, "di");
        disasm->instruction.userData = VC4_INST_DI;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 2;
    }
    else if (w0 == 0x0006)
    {
        strcpy(disasm->instruction.mnemonic, "cbclr");
        disasm->instruction.userData = VC4_INST_CBCLR;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 2;
    }
    else if (w0 == 0x0007)
    {
        strcpy(disasm->instruction.mnemonic, "cbadd1");
        disasm->instruction.userData = VC4_INST_CBADD1;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 2;
    }
    else if (w0 == 0x0008)
    {
        strcpy(disasm->instruction.mnemonic, "cbadd2");
        disasm->instruction.userData = VC4_INST_CBADD2;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 2;
    }
    else if (w0 == 0x0009)
    {
        strcpy(disasm->instruction.mnemonic, "cbadd3");
        disasm->instruction.userData = VC4_INST_CBADD3;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 2;
    }
    else if (w0 == 0x000a)
    {
        strcpy(disasm->instruction.mnemonic, "rti");
        disasm->instruction.userData = VC4_INST_RTI;
        disasm->instruction.branchType = DISASM_BRANCH_RET;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 2;
    }
    else if ((w0 & 0xffe0) == 0x0020)
    {
        strcpy(disasm->instruction.mnemonic, "swi");
        disasm->instruction.userData = VC4_INST_SWI;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_ESP;

        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = 5;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;


        return 2;
    }
    else if ((w0 & 0xffe0) == 0x0040)
    {
        strcpy(disasm->instruction.mnemonic, "b");
        disasm->instruction.userData = VC4_INST_B;
        if (bits(w0, 4, 5) == REG_LR)
            disasm->instruction.branchType = DISASM_BRANCH_RET;
        else
            disasm->instruction.branchType = DISASM_BRANCH_JMP;

        disasm->operand[arg].isBranchDestination = YES;
        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xffe0) == 0x0060)
    {
        strcpy(disasm->instruction.mnemonic, "bl");
        disasm->instruction.userData = VC4_INST_BL;
        disasm->instruction.branchType = DISASM_BRANCH_CALL;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_LR;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;

        disasm->operand[arg].isBranchDestination = YES;
        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xffe0) == 0x0080)
    {
        strcpy(disasm->instruction.mnemonic, "switch");
        disasm->instruction.userData = VC4_INST_TBB;
        disasm->instruction.branchType = DISASM_BRANCH_JMP;

        disasm->operand[arg].isBranchDestination = YES;
        OPERAND_REGISTERGP(bits(w0, 3, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 3, 4));
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xffe0) == 0x00a0)
    {
        strcpy(disasm->instruction.mnemonic, "switch");
        disasm->instruction.userData = VC4_INST_TBS;
        disasm->instruction.branchType = DISASM_BRANCH_JMP;

        disasm->operand[arg].isBranchDestination = YES;
        OPERAND_REGISTERGP(bits(w0, 3, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 3, 4));
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xfff0) == 0x00e0)
    {
        strcpy(disasm->instruction.mnemonic, "version");
        disasm->instruction.userData = VC4_INST_LDCPUID;

        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xffc0) == 0x01c0)
    {
        strcpy(disasm->instruction.mnemonic, "swi");
        disasm->instruction.userData = VC4_INST_SWI;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_ESP;

        disasm->operand[arg].immediateValue = 0x20 + bits(w0, 4, 5);
        OPERAND_UNSIGNED(disasm->operand[arg].immediateValue, 6);
        disasm->operand[arg].size = 6;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xff80) == 0x0200)
    {
        int b, m;

        b = bits(w0, 6, 2);
        m = bits(w0, 4, 5);
        strcpy(disasm->instruction.mnemonic, "ldm");
        disasm->instruction.userData = VC4_INST_POPMULTIPLE;
        disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;

        if (m == 0 || (b == 0x03 && m == 0x0f))  // only one register. later case is gp-r7
        {   // gp-r7 pops gp and maybe others, at least sp is modified so this does not work as tested on RPi 2
            //  but is included here for symmetry with the push.
            OPERAND_REGISTERGP(regbase[b]);
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = OP_REGISTER(regbase[b]);
        }
        else
        {
            OPERAND_REGISTERGP(regbase[b]);
            OPERAND_RAWSTRING("-");
            OPERAND_REGISTERGP((regbase[b] + m) & 0x1f);
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = DISASM_OPERAND_REGISTER_TYPE | DISASM_OPERAND_GENERAL_REG;
            for (int i = 0; i <= m; i++)
            {
                disasm->operand[arg].type |= 1 << ((regbase[b] + i) & 0x1f);
            }
        }
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(REG_SP);
        OPERAND_RAWSTRING("++)");
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_POSTINCREMENT | OP_REGISTER(REG_SP);
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xff80) == 0x0280)
    {
        int b, m;

        b = bits(w0, 6, 2);
        m = bits(w0, 4, 5);
        strcpy(disasm->instruction.mnemonic, "stm");
        disasm->instruction.userData = VC4_INST_PUSHMULTIPLE;
        disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;

        if (m == 0 || (b == 0x03 && m == 0x0f))  // only one register. later case is gp-r7, pushes only gp
        {
            OPERAND_REGISTERGP(regbase[b]);
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(regbase[b]);
        }
        else
        {
            OPERAND_REGISTERGP(regbase[b]);
            OPERAND_RAWSTRING("-");
            OPERAND_REGISTERGP((regbase[b] + m) & 0x1f);
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_REGISTER_TYPE | DISASM_OPERAND_GENERAL_REG;
            for (int i = 0; i <= m; i++)
            {
                disasm->operand[arg].type |= 1 << ((regbase[b] + i) & 0x1f);
            }
        }
        arg++; udx = 0;

        OPERAND_RAWSTRING("(--");
        OPERAND_REGISTERGP(REG_SP);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = DISASM_OPERAND_PREDECREMENT | OP_REGISTER(REG_SP);
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xff80) == 0x0300)
    {
        int b, m;

        b = bits(w0, 6, 2);
        m = bits(w0, 4, 5);

        strcpy(disasm->instruction.mnemonic, "ldm");
        disasm->instruction.userData = VC4_INST_POPPC;
        disasm->instruction.branchType = DISASM_BRANCH_RET;
        disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;

        if (m == 0x1f || (b == 0x03 && m == 0x0f))  // later case is gp-r7
        {
            // only pc, no no operand here
        }
        else if (m == 0) // degenerate case
        {
            OPERAND_REGISTERGP(regbase[b]);
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = OP_REGISTER(regbase[b]);
            arg++; udx = 0;
        }
        else
        {
            OPERAND_REGISTERGP(regbase[b]);
            OPERAND_RAWSTRING("-");
            OPERAND_REGISTERGP((regbase[b] + m) & 0x1f);
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = DISASM_OPERAND_REGISTER_TYPE | DISASM_OPERAND_GENERAL_REG;
            for (int i = 0; i <= m; i++)
            {
                disasm->operand[arg].type |= 1 << ((regbase[b] + i) & 0x1f);
            }
            arg++; udx = 0;
        }

        OPERAND_REGISTERGP(REG_PC);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(REG_PC);
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(REG_SP);
        OPERAND_RAWSTRING("++)");
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_POSTINCREMENT | OP_REGISTER(REG_SP);
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xff80) == 0x0380)
    {
        int b, m;

        b = bits(w0, 6, 2);
        m = bits(w0, 4, 5);

        strcpy(disasm->instruction.mnemonic, "stm");
        disasm->instruction.userData = VC4_INST_PUSHLR;
        disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;

        if (m == 0x1f || (b == 0x03 && m == 0x0f))  // later case is gp-r7
        {
            // only lr, no no operand here
        }
        else if (m == 0) // degenerate case
        {
            OPERAND_REGISTERGP(regbase[b]);
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(regbase[b]);
            arg++; udx = 0;
        }
        else
        {
            OPERAND_REGISTERGP(regbase[b]);
            OPERAND_RAWSTRING("-");
            OPERAND_REGISTERGP((regbase[b] + m) & 0x1f);
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_REGISTER_TYPE | DISASM_OPERAND_GENERAL_REG;
            for (int i = 0; i <= m; i++)
            {
                disasm->operand[arg].type |= 1 << ((regbase[b] + i) & 0x1f);
            }
            arg++; udx = 0;
        }

        OPERAND_REGISTERGP(REG_LR);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(REG_LR);
        arg++; udx = 0;

        OPERAND_RAWSTRING("(--");
        OPERAND_REGISTERGP(REG_SP);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = DISASM_OPERAND_PREDECREMENT | OP_REGISTER(regbase[b]);
        arg++; udx = 0;


        return 2;
    }
    else if ((w0 & 0xfe00) == 0x0400)
    {
        strcpy(disasm->instruction.mnemonic, "ld");
        disasm->instruction.userData = VC4_INST_LDSPOFFSET;

        OPERAND_REGISTERGP(bits(w0, 3, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 3, 4));
        arg++; udx = 0;

		OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(REG_SP);
        OPERAND_VALUEWITHSIGN(msbextendedbits(w0, 8, 5)*4, 5+2);
		OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << REG_SP;
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = msbextendedbits(w0, 8, 5)*4;
        disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xfe00) == 0x0600)
    {
        strcpy(disasm->instruction.mnemonic, "st");
        disasm->instruction.userData = VC4_INST_STSPOFFSET;

        OPERAND_REGISTERGP(bits(w0, 3, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 3, 4));
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        arg++; udx = 0;

		OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(REG_SP);
        OPERAND_VALUEWITHSIGN(msbextendedbits(w0, 8, 5)*4, 5+2);
		OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << REG_SP;
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = msbextendedbits(w0, 8, 5)*4;
        disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xf900) == 0x0800)
    {
        sprintf(disasm->instruction.mnemonic, "ld%s", opSizeSuffix[bits(w0, 10, 2)]);
        disasm->instruction.userData = VC4_INST_LDU32 + bits(w0, 10, 2);

        OPERAND_REGISTERGP(bits(w0, 3, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 3, 4));
        arg++; udx = 0;

		OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(bits(w0, 7, 4));
		OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(w0, 10, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << bits(w0, 7, 4);
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = 0;
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xf900) == 0x0900)
    {
        sprintf(disasm->instruction.mnemonic, "st%s", opSizeSuffix[bits(w0, 10, 2)]);
        disasm->instruction.userData = VC4_INST_STU32 + bits(w0, 10, 2);

        OPERAND_REGISTERGP(bits(w0, 3, 4));
        disasm->operand[arg].size = opBitWidth[bits(w0, 10, 2)];
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 3, 4));
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(bits(w0, 7, 4));
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(w0, 10, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << bits(w0, 7, 4);
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = 0;
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xf800) == 0x1000)
    {
        strcpy(disasm->instruction.mnemonic, "lea");
        disasm->instruction.userData = VC4_INST_LEA;

        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;

		OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(REG_SP);
        OPERAND_VALUEWITHSIGN(msbextendedbits(w0, 10, 6)*4, 6+2);
		OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = 0;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << REG_SP;
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = msbextendedbits(w0, 10, 6)*4;
        arg++; udx = 0;

        disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;

        return 2;
    }
    else if ((w0 & 0xf800) == 0x1800)
    {
        sprintf(disasm->instruction.mnemonic, "b%s", condition[bits(w0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "b");
        disasm->instruction.userData = VC4_INST_B;
        disasm->instruction.condition = conditioncondition[bits(w0, 10, 4)];
        disasm->instruction.branchType = branchtype[bits(w0, 10, 4)];
        disasm->instruction.addressValue = (uint32_t) disasm->virtualAddr + msbextendedbits(w0, 6, 7)*2;
        if (bits(w0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        disasm->operand[arg].isBranchDestination = YES;
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        arg++; udx = 0;

        return 2;
    }
    else if ((w0 & 0xf000) == 0x2000)
    {
        strcpy(disasm->instruction.mnemonic, "ld");
        disasm->instruction.userData = VC4_INST_LDREGOFFSET;

        OPERAND_REGISTERGP(bits(w0, 3, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 3, 4));
        arg++; udx = 0;

        if (bits(w0, 7, 4) == REG_PC)
        {
            disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + bits(w0, 11, 4)*4;
            OPERAND_RAWSTRING("(");
            OPERAND_ADDRESS32(disasm->instruction.addressValue);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(w0, 7, 4);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = bits(w0, 11, 4)*4;
            [context->_file setType:Type_Int32 atVirtualAddress:disasm->instruction.addressValue forLength:4];
            arg++; udx = 0;
        }
        else
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(bits(w0, 7, 4));
            OPERAND_VALUEWITHSIGN(bits(w0, 11, 4)*4, 4+2);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(w0, 7, 4);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = bits(w0, 11, 4)*4;
            arg++; udx = 0;
        }

        return 2;
    }
    else if ((w0 & 0xf000) == 0x3000)
    {
        strcpy(disasm->instruction.mnemonic, "st");
        disasm->instruction.userData = VC4_INST_STREGOFFSET;

        OPERAND_REGISTERGP(bits(w0, 3, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 3, 4));
        arg++; udx = 0;

        if (bits(w0, 7, 4) == REG_PC)
        {
            disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + bits(w0, 11, 4)*4;
            OPERAND_RAWSTRING("(");
            OPERAND_ADDRESS32(disasm->instruction.addressValue);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(w0, 7, 4);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = bits(w0, 11, 4)*4;
            [context->_file setType:Type_Int32 atVirtualAddress:disasm->instruction.addressValue forLength:4];
            arg++; udx = 0;
        }
        else
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(bits(w0, 7, 4));
            OPERAND_VALUEWITHSIGN(bits(w0, 11, 4)*4, 4+2);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(w0, 7, 4);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = bits(w0, 11, 4)*4;
            arg++; udx = 0;
        }

        return 2;
    }
    else if ((w0 & 0xe000) == 0x4000)
    {
        strcpy(disasm->instruction.mnemonic, operation[bits(w0, 12, 5)]);
        disasm->instruction.userData = VC4_INST_MOV + bits(w0, 12, 5);

        OPERAND_REGISTERGP(bits(w0, 3, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE | DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 3, 4));
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(w0, 7, 4));
        OPERAND_RAWSTRING(operationRight[bits(w0, 12, 5)]);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 7, 4));
        disasm->operand[arg].shiftMode = DISASM_SHIFT_LSL;
        disasm->operand[arg].shiftAmount = operationRightOperandShiftAmount[bits(w0, 12, 5)];
        arg++; udx = 0;

        if (operationImpliesWriteToSR[bits(w0, 12, 5)])
            disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 2;
    }
    else if ((w0 & 0xe000) == 0x6000)
    {
        uint32_t imm;
        int op = bits(w0, 12, 4) * 2;

        strcpy(disasm->instruction.mnemonic, operation[op]);
        disasm->instruction.userData = (VC4_INST_MOV + op);

        OPERAND_REGISTERGP(bits(w0, 3, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE | DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 3, 4));
        arg++; udx = 0;

        imm = (bits(w0, 8, 5) << operationRightOperandShiftAmount[op]) & operationRightOperandMask[op];
        OPERAND_VALUECANBESIGNED(imm, 5+operationRightOperandShiftAmount[op], operationRightOperandDefaultAsSigned[op]);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        disasm->operand[arg].immediateValue = imm;
        arg++; udx = 0;

        if (operationImpliesWriteToSR[op])
            disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 2;
    }

    return DISASM_UNKNOWN_OPCODE;
}



int scalar32(uint16_t w0, VC4Context * context, DisasmStruct * disasm, NSUInteger mode)
{
    uint16_t w1 = [context->_file readInt16AtVirtualAddress:disasm->virtualAddr + 2];
    uint32_t l0 = ((uint32_t) w0 << 16) | w1;

    int arg = 0;
    int udx = 0;

    if ((l0 & 0xf0f0c000) == 0x80004000)
    {
        NSLog(@"questionable bcc at 0x%jx", (uintmax_t)disasm->virtualAddr);
        sprintf(disasm->instruction.mnemonic, "b%s", condition[bits(l0, 27, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "b");
        disasm->instruction.userData = VC4_INST_B;
        disasm->instruction.condition = conditioncondition[bits(l0, 27, 4)];
        disasm->instruction.branchType = branchtype[bits(l0, 27, 4)];
        disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + msbextendedbits(l0, 9, 10) * 2;
        if (bits(l0, 27, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        if (bits(l0, 27, 4) <= VC4_MAX_CONDITIONAL) // true and false condition don't depend on arguments
        {
            disasm->instruction.userData = VC4_INST_BCMP;

            OPERAND_REGISTERGP(bits(l0, 19, 4));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 19, 4));
            arg++; udx = 0;

            OPERAND_REGISTERGP(bits(l0, 13, 4));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 13, 4));
            arg++; udx = 0;
        }

        disasm->operand[arg].isBranchDestination = YES;
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xf0f0c000) == 0x8000c000)
    {
        NSLog(@"questionable bcc at 0x%jx", (uintmax_t)disasm->virtualAddr);
        sprintf(disasm->instruction.mnemonic, "b%s", condition[bits(l0, 27, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "b");
        disasm->instruction.userData = VC4_INST_B;
        disasm->instruction.condition = conditioncondition[bits(l0, 27, 4)];
        disasm->instruction.branchType = branchtype[bits(l0, 27, 4)];
        disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + msbextendedbits(l0, 7, 8) * 2;
        if (bits(l0, 27, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        if (bits(l0, 27, 4) <= VC4_MAX_CONDITIONAL) // true and false condition don't depend on arguments
        {
            disasm->instruction.userData = VC4_INST_BCMP;

            OPERAND_REGISTERGP(bits(l0, 19, 4));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 19, 4));
            arg++; udx = 0;

            OPERAND_VALUE(bits(l0, 13, 6), 6);
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
            disasm->operand[arg].immediateValue = bits(l0, 13, 6);
            arg++; udx = 0;
        }

        disasm->operand[arg].isBranchDestination = YES;
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xf0008000) == 0x80000000)
    {
        sprintf(disasm->instruction.mnemonic, "addcmpb%s", condition[bits(l0, 27, 4)]);
        disasm->instruction.userData = VC4_INST_ADDCMPB;
        disasm->instruction.branchType = branchtype[bits(l0, 27, 4)];
        disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + msbextendedbits(l0, 9, 10) * 2;

        OPERAND_REGISTERGP(bits(l0, 19, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE | DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 19, 4));
        arg++; udx = 0;

        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        if (bits(l0, 14, 1) == 0)
        {
            OPERAND_REGISTERGP(bits(l0, 23, 4));
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 23, 4));
        }
        else
        {
            disasm->operand[arg].immediateValue = msbextendedbits(l0, 23, 4);
            OPERAND_SIGNED(disasm->operand[arg].immediateValue, 4);
            disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        }
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(l0, 13, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 13, 4));
        arg++; udx = 0;

        disasm->operand[arg].isBranchDestination = YES;
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xf0008000) == 0x80008000)
    {
        sprintf(disasm->instruction.mnemonic, "addcmpb%s", condition[bits(l0, 27, 4)]);
        disasm->instruction.userData = VC4_INST_ADDCMPB;
        disasm->instruction.branchType = branchtype[bits(l0, 27, 4)];
        disasm->instruction.addressValue = (uint32_t) disasm->virtualAddr + msbextendedbits(l0, 7, 8) * 2;

        OPERAND_REGISTERGP(bits(l0, 19, 4));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE | DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 19, 4));
        arg++; udx = 0;

        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        if (bits(l0, 14, 1) == 0)
        {
            OPERAND_REGISTERGP(bits(l0, 23, 4));
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 23, 4));
        }
        else
        {
            disasm->operand[arg].immediateValue = msbextendedbits(l0, 23, 4);
            OPERAND_SIGNED(disasm->operand[arg].immediateValue, 4);
            disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        }
        arg++; udx = 0;

        disasm->operand[arg].immediateValue = bits(l0, 13, 6);
        OPERAND_UNSIGNED(disasm->operand[arg].immediateValue, 6);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        arg++; udx = 0;

        disasm->operand[arg].isBranchDestination = YES;
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        arg++; udx = 0;

        
        return 4;
    }
    else if ((l0 & 0xf0800000) == 0x90000000)
    {
        sprintf(disasm->instruction.mnemonic, "b%s", condition[bits(l0, 27, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "b");
        disasm->instruction.userData = VC4_INST_B;
        disasm->instruction.branchType = branchtype[bits(l0, 27, 4)];
        disasm->instruction.condition = conditioncondition[bits(l0, 27, 4)];
        disasm->instruction.addressValue = (uint32_t) disasm->virtualAddr + msbextendedbits(l0, 22, 23)*2;
        if (bits(l0, 27, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        disasm->operand[arg].isBranchDestination = YES;
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xf0800000) == 0x90800000)
    {
        strcpy(disasm->instruction.mnemonic, "bl");
        disasm->instruction.userData = VC4_INST_BL;
        disasm->instruction.branchType = DISASM_BRANCH_CALL;
        disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_LR;
        disasm->instruction.addressValue = (uint32_t) disasm->virtualAddr + msbextendedbits2(l0, 27, 4, 22, 23)*2;

        disasm->operand[arg].isBranchDestination = YES;
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        [context->_file addPotentialProcedure:disasm->instruction.addressValue];
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff200060) == 0xa0000000)
    {
        sprintf(disasm->instruction.mnemonic, "ld%s%s", opSizeSuffix[bits(l0, 23, 2)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "ld%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_LDU32 + bits(l0, 23, 2);
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(bits(l0, 15, 5));
        OPERAND_RAWSTRING("+");
        OPERAND_REGISTERGP(bits(l0, 4, 5));
        OPERAND_RAWSTRING(opSizeShift[bits(l0, 23, 2)]);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l0, 15, 5);
        disasm->operand[arg].memory.indexRegistersMask = 1 << bits(l0, 4, 5);
        disasm->operand[arg].memory.scale = disasm->operand[arg].size / 8;
        disasm->operand[arg].memory.displacement = 0;
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff200060) == 0xa0200000)
    {
        sprintf(disasm->instruction.mnemonic, "st%s%s", opSizeSuffix[bits(l0, 23, 2)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "st%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_STU32 + bits(l0, 23, 2);
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(bits(l0, 15, 5));
        OPERAND_RAWSTRING("+");
        OPERAND_REGISTERGP(bits(l0, 4, 5));
        OPERAND_RAWSTRING(opSizeShift[bits(l0, 23, 2)]);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l0, 15, 5);
        disasm->operand[arg].memory.indexRegistersMask = 1 << bits(l0, 4, 5);
        disasm->operand[arg].memory.scale = disasm->operand[arg].size / 8;
        disasm->operand[arg].memory.displacement = 0;
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff20007f) == 0xa4000000)
    {
        sprintf(disasm->instruction.mnemonic, "ld%s%s", opSizeSuffix[bits(l0, 23, 2)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "ld%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_LDU32 + bits(l0, 23, 2);
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING("(--");
        OPERAND_REGISTERGP(bits(l0, 15, 5));
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = DISASM_OPERAND_PREDECREMENT | OP_REGISTER(bits(l0, 15, 5));
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff20007f) == 0xa4200000)
    {
        if (bits(l0, 23, 2) == 0 && bits(l0, 15, 5) == REG_SP && bits(l0, 10, 4) == VC4_COND_T)
        { // st rs,(--sp) = push rs
            sprintf(disasm->instruction.mnemonic, "push");
            disasm->instruction.userData = VC4_INST_PUSH;
            disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
            disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;
            disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;

            OPERAND_REGISTERGP(bits(l0, 20, 5));
            disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
            arg++; udx = 0;
        }
        else
        {
            sprintf(disasm->instruction.mnemonic, "st%s%s", opSizeSuffix[bits(l0, 23, 2)], conditionWithSeparator[bits(l0, 10, 4)]);
            sprintf(disasm->instruction.unconditionalMnemonic, "st%s", opSizeSuffix[bits(l0, 23, 2)]);
            disasm->instruction.userData = VC4_INST_STU32 + bits(l0, 23, 2);
            disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
            if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

            OPERAND_REGISTERGP(bits(l0, 20, 5));
            disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
            arg++; udx = 0;

            OPERAND_RAWSTRING("(--");
            OPERAND_REGISTERGP(bits(l0, 15, 5));
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = DISASM_OPERAND_PREDECREMENT | OP_REGISTER(bits(l0, 15, 5));
            arg++; udx = 0;
        }

        return 4;
    }
    else if ((l0 & 0xff20007f) == 0xa5000000)
    {
        if (bits(l0, 23, 2) == 0 && bits(l0, 15, 5) == REG_SP && bits(l0, 10, 4) == VC4_COND_T)
        { // ld rd,(sp++) = pop rs
            sprintf(disasm->instruction.mnemonic, "pop");
            disasm->instruction.userData = VC4_INST_POP;
            disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
            disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;
            disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SP;

            OPERAND_REGISTERGP(bits(l0, 20, 5));
            disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
            arg++; udx = 0;
        }
        else
        {
            sprintf(disasm->instruction.mnemonic, "ld%s%s", opSizeSuffix[bits(l0, 23, 2)], conditionWithSeparator[bits(l0, 10, 4)]);
            sprintf(disasm->instruction.unconditionalMnemonic, "ld%s", opSizeSuffix[bits(l0, 23, 2)]);
            disasm->instruction.userData = VC4_INST_LDU32 + bits(l0, 23, 2);
            disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
            if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

            OPERAND_REGISTERGP(bits(l0, 20, 5));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
            arg++; udx = 0;

            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(bits(l0, 15, 5));
            OPERAND_RAWSTRING("++)");
            disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_POSTINCREMENT | OP_REGISTER(bits(l0, 15, 5));
            arg++; udx = 0;
        }

        return 4;
    }
    else if ((l0 & 0xff20007f) == 0xa5200000)
    {
        sprintf(disasm->instruction.mnemonic, "st%s%s", opSizeSuffix[bits(l0, 23, 2)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "st%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_STU32 + bits(l0, 23, 2);
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(bits(l0, 15, 5));
        OPERAND_RAWSTRING("++)");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_POSTINCREMENT | OP_REGISTER(bits(l0, 15, 5));
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xfe200000) == 0xa2000000)
    {
        sprintf(disasm->instruction.mnemonic, "ld%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_LDU32 + bits(l0, 23, 2);

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        if (bits(l0, 15, 5) == REG_PC)
        {
            disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + msbextendedbits2(l0, 24, 1, 10, 11);
            OPERAND_RAWSTRING("(");
            OPERAND_ADDRESS32(disasm->instruction.addressValue);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l0, 15, 5);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = msbextendedbits2(l0, 24, 1, 10, 11);
            [context->_file setType:byteTypeForOpWidth[bits(l0, 23, 2)] atVirtualAddress:disasm->instruction.addressValue forLength:opBitWidth[bits(l0, 23, 2)]/8];
            arg++; udx = 0;
        }
        else
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(bits(l0, 15, 5));
            OPERAND_VALUEWITHSIGN(msbextendedbits2(l0, 24, 1, 10, 11), 12);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l0, 15, 5);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = msbextendedbits2(l0, 24, 1, 10, 11);
            arg++; udx = 0;
        }

        return 4;
    }
    else if ((l0 & 0xfe200000) == 0xa2200000)
    {
        sprintf(disasm->instruction.mnemonic, "st%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_STU32 + bits(l0, 23, 2);

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        if (bits(l0, 15, 5) == REG_PC)
        {
            disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + msbextendedbits2(l0, 24, 1, 10, 11);
            OPERAND_RAWSTRING("(");
            OPERAND_ADDRESS32(disasm->instruction.addressValue);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l0, 15, 5);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = msbextendedbits2(l0, 24, 1, 10, 11);
            [context->_file setType:byteTypeForOpWidth[bits(l0, 23, 2)] atVirtualAddress:disasm->instruction.addressValue forLength:opBitWidth[bits(l0, 23, 2)]/8];
            arg++; udx = 0;
        }
        else
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(bits(l0, 15, 5));
            OPERAND_VALUEWITHSIGN(msbextendedbits2(l0, 24, 1, 10, 11), 12);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l0, 15, 5);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = msbextendedbits2(l0, 24, 1, 10, 11);
            arg++; udx = 0;
        }

        return 4;
    }
    else if ((l0 & 0xff200000) == 0xa8000000)
    {
        sprintf(disasm->instruction.mnemonic, "ld%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_LDU32 + bits(l0, 23, 2);

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(REG_GP);
        OPERAND_VALUEWITHSIGN(msbextendedbits(l0, 15, 16), 16);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << 24;
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = msbextendedbits(l0, 15, 16);
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff200000) == 0xa8200000)
    {
        sprintf(disasm->instruction.mnemonic, "st%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_STU32 + bits(l0, 23, 2);

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(REG_GP);
        OPERAND_VALUEWITHSIGN(msbextendedbits(l0, 15, 16), 16);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << 24;
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = msbextendedbits(l0, 15, 16);
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff200000) == 0xa9000000)
    {
        sprintf(disasm->instruction.mnemonic, "ld%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_LDU32 + bits(l0, 23, 2);

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(REG_GP);
        OPERAND_VALUEWITHSIGN(msbextendedbits(l0, 15, 16), 16);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << REG_SP;
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = msbextendedbits(l0, 15, 16);
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff200000) == 0xa9200000)
    {
        sprintf(disasm->instruction.mnemonic, "st%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_STU32 + bits(l0, 23, 2);

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(REG_GP);
        OPERAND_VALUEWITHSIGN(msbextendedbits(l0, 15, 16), 16);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << REG_SP;
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = msbextendedbits(l0, 15, 16);
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff200000) == 0xaa000000)
    {
        sprintf(disasm->instruction.mnemonic, "ld%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_LDU32 + bits(l0, 23, 2);

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + msbextendedbits(l0, 15, 16);
        OPERAND_RAWSTRING("(");
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << REG_PC;
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = msbextendedbits(l0, 15, 16);
        [context->_file setType:byteTypeForOpWidth[bits(l0, 23, 2)] atVirtualAddress:disasm->instruction.addressValue forLength:opBitWidth[bits(l0, 23, 2)]/8];
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff200000) == 0xaa200000)
    {
        sprintf(disasm->instruction.mnemonic, "st%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_STU32 + bits(l0, 23, 2);

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + msbextendedbits(l0, 15, 16);
        OPERAND_RAWSTRING("(");
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << REG_PC;
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = msbextendedbits(l0, 15, 16);
        [context->_file setType:byteTypeForOpWidth[bits(l0, 23, 2)] atVirtualAddress:disasm->instruction.addressValue forLength:opBitWidth[bits(l0, 23, 2)]/8];
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff200000) == 0xab000000)
    {
        sprintf(disasm->instruction.mnemonic, "ld%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_LDU32 + bits(l0, 23, 2);

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(REG_R0);
        OPERAND_VALUEWITHSIGN(msbextendedbits(l0, 15, 16), 16);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << 0;
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = msbextendedbits(l0, 15, 16);
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff200000) == 0xab200000)
    {
        sprintf(disasm->instruction.mnemonic, "st%s", opSizeSuffix[bits(l0, 23, 2)]);
        disasm->instruction.userData = VC4_INST_STU32 + bits(l0, 23, 2);

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING("(");
        OPERAND_REGISTERGP(REG_R0);
        OPERAND_VALUEWITHSIGN(msbextendedbits(l0, 15, 16), 16);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(l0, 23, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
        disasm->operand[arg].memory.baseRegistersMask = 1 << 0;
        disasm->operand[arg].memory.indexRegistersMask = 0;
        disasm->operand[arg].memory.scale = 1;
        disasm->operand[arg].memory.displacement = msbextendedbits(l0, 15, 16);
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xfc000000) == 0xb0000000)
    {
        sprintf(disasm->instruction.mnemonic, "%s", operation[bits(l0, 25, 5)]);
        disasm->instruction.userData = VC4_INST_MOV + bits(l0, 25, 5);

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE | (operationHasLeftOperand[bits(l0, 25, 5)] ? DISASM_ACCESS_READ : 0);
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        disasm->operand[arg].immediateValue = (msbextendedbits(l0, 15, 16) << operationRightOperandShiftAmount[bits(l0, 25, 5)]) & operationRightOperandMask[bits(l0, 25, 5)];
        OPERAND_VALUECANBESIGNED(disasm->operand[arg].immediateValue, 16+operationRightOperandShiftAmount[bits(l0, 25, 5)], operationRightOperandDefaultAsSigned[bits(l0, 25, 5)]);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xfc000000) == 0xb4000000)
    {
        sprintf(disasm->instruction.mnemonic, "lea");
        disasm->instruction.userData = VC4_INST_LEA;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        if (bits(l0, 25, 5) == REG_PC)
        {
            disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + msbextendedbits(l0, 15, 16);
            OPERAND_RAWSTRING("(");
            OPERAND_ADDRESS32(disasm->instruction.addressValue);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = 0;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l0, 25, 5);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = msbextendedbits(l0, 15, 16);
            arg++; udx = 0;
        }
        else
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(bits(l0, 25, 5));
            OPERAND_VALUEWITHSIGN(msbextendedbits(l0, 15, 16), 16);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = 0;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l0, 25, 5);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = msbextendedbits(l0, 15, 16);
            arg++; udx = 0;
        }

        return 4;
    }
    else if ((l0 & 0xffe00000) == 0xbfe00000)
    {
        sprintf(disasm->instruction.mnemonic, "lea");
        disasm->instruction.userData = VC4_INST_LEA;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        disasm->operand[arg].immediateValue = (uint32_t)disasm->virtualAddr + msbextendedbits(l0, 15, 16);
        disasm->instruction.addressValue = disasm->operand[arg].immediateValue;
        OPERAND_RAWSTRING("(");
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = 0;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xfc000060) == 0xc0000000)
    {
        sprintf(disasm->instruction.mnemonic, "%s%s", operation[bits(l0, 25, 5)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "%s", operation[bits(l0, 25, 5)]);
        disasm->instruction.userData = VC4_INST_MOV + bits(l0, 25, 5);
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        if (operationHasRegisterResult[bits(l0, 25, 5)])
        {
            OPERAND_REGISTERGP(bits(l0, 20, 5));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
            arg++; udx = 0;
        }

        if (operationHasLeftOperand[bits(l0, 25, 5)])
        {
            OPERAND_REGISTERGP(bits(l0, 15, 5));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 15, 5));
            arg++; udx = 0;
        }

        OPERAND_REGISTERGP(bits(l0, 4, 5));
        OPERAND_RAWSTRING(operationRight[bits(l0, 25, 5)]);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 4, 5));
        disasm->operand[arg].shiftMode = DISASM_SHIFT_LSL;
        disasm->operand[arg].shiftAmount = operationRightOperandShiftAmount[bits(l0, 25, 5)];
        arg++; udx = 0;

        if (operationImpliesWriteToSR[bits(l0, 25, 5)])
            disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 4;
    }
    else if ((l0 & 0xfc000040) == 0xc0000040)
    {
        sprintf(disasm->instruction.mnemonic, "%s%s", operation[bits(l0, 25, 5)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "%s", operation[bits(l0, 25, 5)]);
        disasm->instruction.userData = VC4_INST_MOV + bits(l0, 25, 5);
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        if (operationHasRegisterResult[bits(l0, 25, 5)])
        {
            OPERAND_REGISTERGP(bits(l0, 20, 5));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
            arg++; udx = 0;
        }

        if (operationHasLeftOperand[bits(l0, 25, 5)])
        {
            OPERAND_REGISTERGP(bits(l0, 15, 5));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 15, 5));
            arg++; udx = 0;
        }

        disasm->operand[arg].immediateValue = (msbextendedbits(l0, 5, 6) << operationRightOperandShiftAmount[bits(l0, 25, 5)]) & operationRightOperandMask[bits(l0, 25, 5)];
        OPERAND_VALUECANBESIGNED(disasm->operand[arg].immediateValue, 6+operationRightOperandShiftAmount[bits(l0, 25, 5)], operationRightOperandDefaultAsSigned[bits(l0, 25, 5)]);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        arg++; udx = 0;

        if (operationImpliesWriteToSR[bits(l0, 25, 5)])
            disasm->implicitlyWrittenRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        return 4;
    }
    else if ((l0 & 0xff800060) == 0xc4000000)
    {
        sprintf(disasm->instruction.mnemonic, "mulhd%s.%s%s", conditionWithSeparator[bits(l0, 10, 4)], sign[bits(l0, 22, 1)], sign[bits(l0, 21, 1)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "mulhd.%s%s", sign[bits(l0, 22, 1)], sign[bits(l0, 21, 1)]);
        disasm->instruction.userData = VC4_INST_MULHD;
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(l0, 15, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 15, 5));
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(l0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 4, 5));
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff800040) == 0xc4000040)
    {
        sprintf(disasm->instruction.mnemonic, "mulhd%s.%s%s", conditionWithSeparator[bits(l0, 10, 4)], sign[bits(l0, 22, 1)], sign[bits(l0, 21, 1)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "mulhd.%s%s", sign[bits(l0, 22, 1)], sign[bits(l0, 21, 1)]);
        disasm->instruction.userData = VC4_INST_MULHD;
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(l0, 15, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        disasm->operand[arg].immediateValue = msbextendedbits(l0, 5, 6);
        if (signIsSigned[bits(l0, 21, 1)])
        {
            OPERAND_SIGNED(disasm->operand[arg].immediateValue, 6);
        }
        else
        {
            OPERAND_UNSIGNED(disasm->operand[arg].immediateValue, 6);
        }
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff800060) == 0xc4800000)
    {
        sprintf(disasm->instruction.mnemonic, "div%s.%s%s", conditionWithSeparator[bits(l0, 10, 4)], sign[bits(l0, 22, 1)], sign[bits(l0, 21, 1)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "div.%s%s", sign[bits(l0, 22, 1)], sign[bits(l0, 21, 1)]);
        disasm->instruction.userData = VC4_INST_DIV;
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(l0, 15, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 15, 5));
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(l0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 4, 5));
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff800040) == 0xc4800040)
    {
        sprintf(disasm->instruction.mnemonic, "div%s.%s%s", conditionWithSeparator[bits(l0, 10, 4)], sign[bits(l0, 22, 1)], sign[bits(l0, 21, 1)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "div.%s%s", sign[bits(l0, 22, 1)], sign[bits(l0, 21, 1)]);
        disasm->instruction.userData = VC4_INST_DIV;
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(l0, 15, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        disasm->operand[arg].immediateValue = msbextendedbits(l0, 5, 6);
        if (signIsSigned[bits(l0, 21, 1)])
        {
            OPERAND_SIGNED(disasm->operand[arg].immediateValue, 6);
        }
        else
        {
            OPERAND_UNSIGNED(disasm->operand[arg].immediateValue, 6);
        }
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        arg++; udx = 0;

        return 4;
    }


    else if ((l0 & 0xfc000060) == 0xc4000000 && operation2[bits(l0, 25, 5)])
    {
        sprintf(disasm->instruction.mnemonic, "%s%s", operation2[bits(l0, 25, 5)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "%s", operation2[bits(l0, 25, 5)]);
        disasm->instruction.userData = operation2Instruction[bits(l0, 25, 5)];
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        if (operation2HasLeftOperand[bits(l0, 25, 5)])
        {
            OPERAND_REGISTERGP(bits(l0, 15, 5));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 15, 5));
            arg++; udx = 0;
        }

        OPERAND_REGISTERGP(bits(l0, 4, 5));
        OPERAND_RAWSTRING(operation2Right[bits(l0, 25, 5)]);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 4, 5));
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xfc000040) == 0xc4000040 && operation2[bits(l0, 25, 5)])
    {
        sprintf(disasm->instruction.mnemonic, "%s%s", operation2[bits(l0, 25, 5)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "%s", operation2[bits(l0, 25, 5)]);
        disasm->instruction.userData = operation2Instruction[bits(l0, 25, 5)];
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        if (operation2HasLeftOperand[bits(l0, 25, 5)])
        {
            OPERAND_REGISTERGP(bits(l0, 15, 5));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 15, 5));
            arg++; udx = 0;
        }

        disasm->operand[arg].immediateValue = (msbextendedbits(l0, 5, 6) << operation2RightOperandShiftAmount[bits(l0, 25, 5)]) & operation2RightOperandMask[bits(l0, 25, 5)];
        OPERAND_VALUECANBESIGNED(disasm->operand[arg].immediateValue, 6+operation2RightOperandShiftAmount[bits(l0, 25, 5)], operation2PresentRightOperandAsSigned[bits(l0, 25, 5)]);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xfe000060) == 0xc8000000)
    {
        sprintf(disasm->instruction.mnemonic, "%s%s", foperation[bits(l0, 24, 4)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "%s", foperation[bits(l0, 24, 4)]);
        disasm->instruction.userData = VC4_INST_FADD + bits(l0, 24, 4);
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        if (foperationHasRegisterResult[bits(l0, 24, 4)])
        {
            OPERAND_REGISTERGP(bits(l0, 20, 5));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
            arg++; udx = 0;
        }

        if (foperationHasLeftOperand[bits(l0, 24, 4)])
        {
            OPERAND_REGISTERGP(bits(l0, 15, 5));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 15, 5));
            arg++; udx = 0;
        }

        OPERAND_REGISTERGP(bits(l0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 4, 5));
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xfe000040) == 0xc8000040)
    {
        sprintf(disasm->instruction.mnemonic, "%s%s", foperation[bits(l0, 24, 4)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "%s", foperation[bits(l0, 24, 4)]);
        disasm->instruction.userData = VC4_INST_FADD + bits(l0, 24, 4);
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        if (foperationHasRegisterResult[bits(l0, 24, 4)])
        {
            OPERAND_REGISTERGP(bits(l0, 20, 5));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
            arg++; udx = 0;
        }

        if (foperationHasLeftOperand[bits(l0, 24, 4)])
        {
            OPERAND_REGISTERGP(bits(l0, 15, 5));
            disasm->operand[arg].size = 32;
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = OP_REGISTER(bits(l0, 15, 5));
            arg++; udx = 0;
        }
        
        OPERAND_FLOAT32(float6(bits(l0, 5, 6)));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        disasm->operand[arg].immediateValue = float6(bits(l0, 5, 6));
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff800060) == 0xca000000)
    {
        sprintf(disasm->instruction.mnemonic, "%s%s", foperation2[bits(l0, 22, 2)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "%s", foperation2[bits(l0, 22, 2)]);
        disasm->instruction.userData = VC4_INST_FTRUNC + bits(l0, 22, 2);
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(l0, 15, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 15, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING(foperation2Right[bits(l0, 22, 2)]);
        OPERAND_RAWSTRING(" ");
        OPERAND_REGISTERGP(bits(l0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 4, 5));
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xff800040) == 0xca000040)
    {
        sprintf(disasm->instruction.mnemonic, "%s%s", foperation2[bits(l0, 22, 2)], conditionWithSeparator[bits(l0, 10, 4)]);
        sprintf(disasm->instruction.unconditionalMnemonic, "%s", foperation2[bits(l0, 22, 2)]);
        disasm->instruction.userData = VC4_INST_FTRUNC + bits(l0, 22, 2);
        disasm->instruction.condition = conditioncondition[bits(l0, 10, 4)];
        if (bits(l0, 10, 4) <= VC4_MAX_CONDITIONAL) disasm->implicitlyReadRegisters[RegClass_GeneralPurposeRegister] |= 1 << REG_SR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(l0, 15, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 15, 5));
        arg++; udx = 0;

        OPERAND_RAWSTRING(foperation2Right[bits(l0, 22, 2)]);
        OPERAND_RAWSTRING(" #");
        OPERAND_DECIMAL(msbextendedbits(l0, 5, 6));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        disasm->operand[arg].immediateValue = 0; // to be enhanced
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xffe0ffe0) == 0xcc000000)
    {
        sprintf(disasm->instruction.mnemonic, "mov");
        disasm->instruction.userData = VC4_INST_MOVPCR;

        OPERAND_REGISTERSTRING(procControlRegName[bits(l0, 20, 5)]);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(l0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        return 4;
    }
    else if ((l0 & 0xffe0ffe0) == 0xcc200000)
    {
        sprintf(disasm->instruction.mnemonic, "mov");
        disasm->instruction.userData = VC4_INST_MOVPCR;

        OPERAND_REGISTERGP(bits(l0, 20, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(l0, 20, 5));
        arg++; udx = 0;

        OPERAND_REGISTERSTRING(procControlRegName[bits(l0, 4, 5)]);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        return 4;
    }

    return DISASM_UNKNOWN_OPCODE;
;
}



int scalar48(uint16_t w0, VC4Context * context, DisasmStruct * disasm, NSUInteger mode)
{
    uint32_t l1;

    int arg = 0;
    int udx = 0;

    l1 = [context->_file readInt32AtVirtualAddress:disasm->virtualAddr + 2];

    if (w0 == 0xe000)
    {
        sprintf(disasm->instruction.mnemonic, "b");
        disasm->instruction.userData = VC4_INST_B;
        disasm->instruction.branchType = DISASM_BRANCH_JMP;

        disasm->operand[arg].isBranchDestination = YES;
        disasm->instruction.addressValue = l1;
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        disasm->operand[arg].size = 0;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        arg++; udx = 0;

        return 6;
    }
    else if ((w0 & 0xffe0) == 0xe500)
    {
        sprintf(disasm->instruction.mnemonic, "lea");
        disasm->instruction.userData = VC4_INST_LEA;

        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;

        disasm->operand[arg].immediateValue = (uint32_t)disasm->virtualAddr + l1;
        disasm->instruction.addressValue = disasm->operand[arg].immediateValue;
        OPERAND_RAWSTRING("(");
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = 0;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        arg++; udx = 0;

        return 6;
    }
    else if ((w0 & 0xff20) == 0xe600)
    {
        sprintf(disasm->instruction.mnemonic, "ld%s", opSizeSuffix[bits(w0, 7, 2)]);
        disasm->instruction.userData = VC4_INST_LDU32 + bits(w0, 7, 2);

        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;

        if (bits(l1, 31, 5) == REG_PC)
        {
            disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + msbextendedbits(l1, 26, 27);
            OPERAND_RAWSTRING("(");
            OPERAND_ADDRESS32(disasm->instruction.addressValue);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = opBitWidth[bits(w0, 7, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l1, 31, 5);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = bits(l1, 26, 27);
            [context->_file setType:byteTypeForOpWidth[bits(w0, 7, 2)] atVirtualAddress:disasm->instruction.addressValue forLength:opBitWidth[bits(w0, 7, 2)]/8];
            arg++; udx = 0;
        }
        else
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(bits(l1, 31, 5));
            OPERAND_VALUEWITHSIGN(msbextendedbits(l1, 26, 27), 27);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = opBitWidth[bits(w0, 7, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l1, 31, 5);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = bits(l1, 26, 27);
            arg++; udx = 0;
        }

        return 6;
    }
    else if ((w0 & 0xff20) == 0xe620)
    {
        sprintf(disasm->instruction.mnemonic, "st%s", opSizeSuffix[bits(w0, 7, 2)]);
        disasm->instruction.userData = VC4_INST_STU32 + bits(w0, 7, 2);

        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = opBitWidth[bits(w0, 7, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;

        if (bits(l1, 31, 5) == REG_PC)
        {
            disasm->instruction.addressValue = (uint32_t)disasm->virtualAddr + msbextendedbits(l1, 26, 27);
            OPERAND_RAWSTRING("(");
            OPERAND_ADDRESS32(disasm->instruction.addressValue);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = opBitWidth[bits(w0, 7, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l1, 31, 5);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = bits(l1, 26, 27);
            [context->_file setType:byteTypeForOpWidth[bits(w0, 7, 2)] atVirtualAddress:disasm->instruction.addressValue forLength:opBitWidth[bits(w0, 7, 2)]/8];
            arg++; udx = 0;
        }
        else
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(bits(l1, 31, 5));
            OPERAND_VALUEWITHSIGN(msbextendedbits(l1, 26, 27), 27);
            OPERAND_RAWSTRING(")");
            disasm->operand[arg].size = opBitWidth[bits(w0, 7, 2)];
            disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[arg].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[arg].memory.baseRegistersMask = 1 << bits(l1, 31, 5);
            disasm->operand[arg].memory.indexRegistersMask = 0;
            disasm->operand[arg].memory.scale = 1;
            disasm->operand[arg].memory.displacement = bits(l1, 26, 27);
            arg++; udx = 0;
        }

        return 6;
    }
    else if ((w0 & 0xff20) == 0xe700 && (l1 & 0xf8000000) == 0xf8000000)
    {
        sprintf(disasm->instruction.mnemonic, "ld%s", opSizeSuffix[bits(w0, 7, 2)]);
        disasm->instruction.userData = VC4_INST_LDU32 + bits(w0, 7, 2);

        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;

        disasm->operand[arg].immediateValue = (uint32_t)disasm->virtualAddr + msbextendedbits(l1, 26, 27);
        disasm->instruction.addressValue = disasm->operand[arg].immediateValue;
        OPERAND_RAWSTRING("(");
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(w0, 7, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        [context->_file setType:byteTypeForOpWidth[bits(w0, 7, 2)] atVirtualAddress:disasm->instruction.addressValue forLength:opBitWidth[bits(w0, 7, 2)]/8];
        arg++; udx = 0;

        return 6;
    }
    else if ((w0 & 0xff20) == 0xe720 && (l1 & 0xf8000000) == 0xf8000000)
    {
        sprintf(disasm->instruction.mnemonic, "st%s", opSizeSuffix[bits(w0, 7, 2)]);
        disasm->instruction.userData = VC4_INST_STU32 + bits(w0, 7, 2);

        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = opBitWidth[bits(w0, 7, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;

        disasm->operand[arg].immediateValue = (uint32_t)disasm->virtualAddr + msbextendedbits(l1, 26, 27);
        disasm->instruction.addressValue = disasm->operand[arg].immediateValue;
        OPERAND_RAWSTRING("(");
        OPERAND_ADDRESS32(disasm->instruction.addressValue);
        OPERAND_RAWSTRING(")");
        disasm->operand[arg].size = opBitWidth[bits(w0, 7, 2)];
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = DISASM_OPERAND_ABSOLUTE;
        [context->_file setType:byteTypeForOpWidth[bits(w0, 7, 2)] atVirtualAddress:disasm->instruction.addressValue forLength:opBitWidth[bits(w0, 7, 2)]/8];
        arg++; udx = 0;

        return 6;
    }
    else if ((w0 & 0xfc00) == 0xe800)
    {
        sprintf(disasm->instruction.mnemonic, "%s", operation[bits(w0, 9, 5)]);
        disasm->instruction.userData = VC4_INST_MOV + bits(w0, 9, 5);

        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE | (operationHasLeftOperand[bits(w0, 9, 5)] ? DISASM_ACCESS_READ : 0);
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;

        disasm->operand[arg].immediateValue = (l1 << operationRightOperandShiftAmount[bits(w0, 9, 5)]) & operationRightOperandMask[bits(w0, 9, 5)];
        OPERAND_VALUECANBESIGNED(disasm->operand[arg].immediateValue, 32, operationRightOperandDefaultAsSigned[bits(w0, 9, 5)]);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        arg++; udx = 0;

        return 6;
    }
    else if ((w0 & 0xfc00) == 0xec00)
    {
        sprintf(disasm->instruction.mnemonic, "add");
        disasm->instruction.userData = VC4_INST_ADD;

        OPERAND_REGISTERGP(bits(w0, 4, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_WRITE;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 4, 5));
        arg++; udx = 0;

        OPERAND_REGISTERGP(bits(w0, 9, 5));
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = OP_REGISTER(bits(w0, 9, 5));
        arg++; udx = 0;

        OPERAND_VALUE(l1, 32);
        disasm->operand[arg].size = 32;
        disasm->operand[arg].accessMode = DISASM_ACCESS_READ;
        disasm->operand[arg].type = DISASM_OPERAND_CONSTANT_TYPE;
        disasm->operand[arg].immediateValue = l1;
        arg++; udx = 0;

        return 6;
    }

    return DISASM_UNKNOWN_OPCODE;
}



char * vWidth[4]=
{
    "8", "16", "32", "3?"
};



char * vReadAccWidth[4]=
{
    "32", "s32", "2?", "s16"
};



char * vRep[8] =
{
    NULL, "rep 2", "rep 4", "rep 8", "rep 16", "rep 32", "rep 64", "rep r0"
};



char * vP[8] =
{
    NULL, "none", "ifz", "ifnz", "ifn", "ifnn", "ifc", "ifnc"
};



char * vF[2] =
{
    NULL, "setf"
};



char * vX[2] =
{
    "16", "32"
};



int vXwidth[2] =
{
    16, 32
};



char * vAccSRU[128] =
{
    // if ENA is not set, 48 bit accumulator is disabled
    NULL,    NULL,    NULL,    NULL,    NULL,         NULL,         NULL,         NULL,
    NULL,    NULL,    NULL,    NULL,    NULL,         NULL,         NULL,         NULL,
    NULL,    NULL,    NULL,    NULL,    NULL,         NULL,         NULL,         NULL,
    NULL,    NULL,    NULL,    NULL,    NULL,         NULL,         NULL,         NULL,
    "uadd",  "usub",  "uacc",  "udec",  "clra uadd",  "clra usub",  "clra uacc",  "clra udec",
    "sadd",  "ssub",  "sacc",  "sdec",  "clra sadd",  "clra ssub",  "clra sacc",  "clra sdec",
    "uaddh", "usubh", "uacch", "udech", "clra uaddh", "clra usubh", "clra uacch", "clra udech",
    "saddh", "ssubh", "sacch", "sdech", "clra saddh", "clra ssubh", "clra sacch", "clra sdech",
    "sumu",  "sumu",  "sumu",  "sumu",  "sumu",       "sumu",       "sumu",       "sumu",
    "sums",  "sums",  "sums",  "sums",  "sums",       "sums",       "sums",       "sums",
    "max2",  "max2",  "max2",  "max2",  "max2",       "max2",       "max2",       "max2",
    "imin",  "imin",  "imin",  "imin",  "imin",       "imin",       "imin",       "imin",
    "max4",  "max4",  "max4",  "max4",  "max4",       "max4",       "max4",       "max4",
    "imax",  "imax",  "imax",  "imax",  "imax",       "imax",       "imax",       "imax",
    "max6",  "max6",  "max6",  "max6",  "max6",       "max6",       "max6",       "max6",
    "max",   "max",   "max",   "max",   "max",        "max",        "max",        "max",
};



BOOL vAccSRUHasReg[128] =
{
    NO,  NO,  NO,  NO,  NO,  NO,  NO,  NO,
    NO,  NO,  NO,  NO,  NO,  NO,  NO,  NO,
    NO,  NO,  NO,  NO,  NO,  NO,  NO,  NO,
    NO,  NO,  NO,  NO,  NO,  NO,  NO,  NO,
    NO,  NO,  NO,  NO,  NO,  NO,  NO,  NO,
    NO,  NO,  NO,  NO,  NO,  NO,  NO,  NO,
    NO,  NO,  NO,  NO,  NO,  NO,  NO,  NO,
    NO,  NO,  NO,  NO,  NO,  NO,  NO,  NO,
    YES, YES, YES, YES, YES, YES, YES, YES,
    YES, YES, YES, YES, YES, YES, YES, YES,
    YES, YES, YES, YES, YES, YES, YES, YES,
    YES, YES, YES, YES, YES, YES, YES, YES,
    YES, YES, YES, YES, YES, YES, YES, YES,
    YES, YES, YES, YES, YES, YES, YES, YES,
    YES, YES, YES, YES, YES, YES, YES, YES,
    YES, YES, YES, YES, YES, YES, YES, YES,
};



BOOL vOpHasRa[2][64] = // e.g. vmov is monadic
{
    {
        NO,          NO,          YES,         YES,         YES,         YES,         YES,        YES,
    //  "mov",       "bitplanes", "even",      "odd",       "altl",      "altu",      "brev",     "ror",
        YES,         YES,         YES,         YES,         YES,         NO,          YES,        YES,
    //  "shl",       "shsls",     "lsr",       "asr",       "sshl",      "zero",      "signasl",  "signasls",
        YES,         YES,         YES,         YES,         YES,         YES,         NO,         NO,
    //  "and",       "or",        "eor",       "bic",       "count",     "msb",       "zero",     "zero",
        YES,         YES,         YES,         YES,         YES,         YES,         NO,         YES,
    //  "min",       "max",       "dist",      "dists",     "clamp",     "sign",      "zero",     "testmag",
        YES,         YES,         YES,         YES,         YES,         YES,         YES,        YES,
    //  "add",       "adds",      "addc",      "addsc",     "sub",       "subs",      "subc",     "subsc",
        YES,         YES,         YES,         YES,         NO,          NO,          NO,         NO,
    //  "rsub",      "rsubs",     "rsubc",     "rsubsc",    "zero",      "zero",      "zero",     "zero",
        YES,         YES,         YES,         YES,         YES,         YES,         YES,        YES,
    //  "mull.ss",   "mulls.ss",  "mulmd.ss",  "mulmds.ss", "mulhd.ss",  "mulhd.su",  "mulhd.us", "mulhd.uu",
        YES,         YES,         YES,         YES,         YES,         YES,         NO,         NO
    //  "mulhdr.ss", "mulhdr.su", "mulhdr.us", "mulhdr.uu", "mulhdt.ss", "mulhdt.su", "zero",     "zero"
    },
    {
        NO,          NO,          YES,         YES,         YES,         YES,         YES,         YES,
    //  "mov",       "bitplanes", "even",      "odd",       "altl",      "altu",      "brev",      "ror",
        YES,         YES,         YES,         YES,         YES,         NO,          YES,         YES,
    //  "shl",       "shsls",     "lsr",       "asr",       "sshl",      "zero",      "signasl",  "signasls",
        YES,         YES,         YES,         YES,         NO,          YES,         NO,          NO,
    //  "and",       "or",        "eor",       "bic",       "zero",       "msb",       "zero",      "zero",
        YES,         YES,         YES,         YES,         YES,         YES,         YES,         YES,
    //  "min",       "max",       "dist",      "dists",     "clamp",     "sign",      "saturate",  "testmag",
        YES,         YES,         YES,         YES,         YES,         YES,         YES,         YES,
    //  "add",       "adds",      "addc",      "addsc",     "sub",       "subs",      "subc",      "subsc",
        YES,         YES,         YES,         YES,         NO,          NO,          NO,          NO,
    //  "rsub",      "rsubs",     "rsubc",     "rsubsc",    "zero",      "zero",      "zero",      "zero",
        NO,          NO,          NO,          NO,          YES,         YES,         YES,         YES,
    //  "zero",      "zero",      "zero",      "zero",      "mulhd.ss",  "mulhd.su",  "mulhd.us",  "mulhd.uu",
        YES,         YES,         YES,         YES,         YES,         YES,         YES,         YES
    //  NULL,        NULL,        NULL,        NULL,        NULL,        NULL,        NULL,        NULL
    }
};



BOOL vOpHasRb[2][64] = // because vzero has no operands at all.
{
    {
        YES,         YES,         YES,         YES,         YES,         YES,         YES,        YES,
    //  "mov",       "bitplanes", "even",      "odd",       "altl",      "altu",      "brev",     "ror",
        YES,         YES,         YES,         YES,         YES,         NO,          YES,        YES,
    //  "shl",       "shsls",     "lsr",       "asr",       "sshl",      "zero",      "signasl",  "signasls",
        YES,         YES,         YES,         YES,         YES,         YES,         NO,         NO,
    //  "and",       "or",        "eor",       "bic",       "count",     "msb",       "zero",     "zero",
        YES,         YES,         YES,         YES,         YES,         YES,         NO,         YES,
    //  "min",       "max",       "dist",      "dists",     "clamp",     "sign",      "zero",     "testmag",
        YES,         YES,         YES,         YES,         YES,         YES,         YES,        YES,
    //  "add",       "adds",      "addc",      "addsc",     "sub",       "subs",      "subc",     "subsc",
        YES,         YES,         YES,         YES,         NO,          NO,          NO,         NO,
    //  "rsub",      "rsubs",     "rsubc",     "rsubsc",    "zero",      "zero",      "zero",     "zero",
        YES,         YES,         YES,         YES,         YES,         YES,         YES,        YES,
    //  "mull.ss",   "mulls.ss",  "mulmd.ss",  "mulmds.ss", "mulhd.ss",  "mulhd.su",  "mulhd.us", "mulhd.uu",
        YES,         YES,         YES,         YES,         YES,         YES,         NO,         NO
    //  "mulhdr.ss", "mulhdr.su", "mulhdr.us", "mulhdr.uu", "mulhdt.ss", "mulhdt.su", "zero",     "zero"
    },
    {
        YES,         YES,         YES,         YES,         YES,         YES,         YES,        YES,
    //  "mov",       "bitplanes", "even",      "odd",       "altl",      "altu",      "brev",     "ror",
        YES,         YES,         YES,         YES,         YES,         NO,          YES,        YES,
    //  "shl",       "shsls",     "lsr",       "asr",       "sshl",      "zero",      "signasl",  "signasls",
        YES,         YES,         YES,         YES,         NO,          YES,         NO,         NO,
    //  "and",       "or",        "eor",       "bic",       "zero",      "msb",       "zero",     "zero",
        YES,         YES,         YES,         YES,         YES,         YES,         YES,        YES,
    //  "min",       "max",       "dist",      "dists",     "clamp",     "sign",      "saturate", "testmag",
        YES,         YES,         YES,         YES,         YES,         YES,         YES,        YES,
    //  "add",       "adds",      "addc",      "addsc",     "sub",       "subs",      "subc",     "subsc",
        YES,         YES,         YES,         YES,         NO,          NO,          NO,         NO,
    //  "rsub",      "rsubs",     "rsubc",     "rsubsc",    "zero",      "zero",      "zero",     "zero",
        NO,          NO,          NO,          NO,          YES,         YES,         YES,        YES,
    //  "zero",      "zero",      "zero",      "zero",      "mulhd.ss",  "mulhd.su",  "mulhd.us", "mulhd.uu",
        YES,         YES,         YES,         YES,         YES,         YES,         YES,         YES
    //  NULL,        NULL,        NULL,        NULL,        NULL,        NULL,        NULL,        NULL
    }
};



char * vOp[2][64] =    // null = invalid vOp
{
    {
        "mov",       "bitplanes", "even",      "odd",       "altl",      "altu",      "brev",     "ror",
        "shl",       "shsls",     "lsr",       "asr",       "sshl",      "zero",      "signasl",  "signasls",
        "and",       "or",        "eor",       "bic",       "count",     "msb",       "zero",     "zero",
        "min",       "max",       "dist",      "dists",     "clamp",     "sign",      "zero",     "testmag",
        "add",       "adds",      "addc",      "addsc",     "sub",       "subs",      "subc",     "subsc",
        "rsub",      "rsubs",     "rsubc",     "rsubsc",    "zero",      "zero",      "zero",     "zero",
        "mull.ss",   "mulls.ss",  "mulmd.ss",  "mulmds.ss", "mulhd.ss",  "mulhd.su",  "mulhd.us", "mulhd.uu",
        "mulhdr.ss", "mulhdr.su", "mulhdr.us", "mulhdr.uu", "mulhdt.ss", "mulhdt.su", "zero",     "zero"
    },
    {
        "mov",       "bitplanes", "even",      "odd",       "altl",      "altu",      "brev",     "ror",
        "shl",       "shsls",     "lsr",       "asr",       "sshl",      "zero",      "signasl",  "signasls",
        "and",       "or",        "eor",       "bic",       "zero",      "msb",       "zero",     "zero",
        "min",       "max",       "dist",      "dists",     "clamp",     "sign",      "saturate", "testmag",
        "add",       "adds",      "addc",      "addsc",     "sub",       "subs",      "subc",     "subsc",
        "rsub",      "rsubs",     "rsubc",     "rsubsc",    "zero",      "zero",      "zero",     "zero",
        "zero",      "zero",      "zero",      "zero",      "mulhd.ss",  "mulhd.su",  "mulhd.us", "mulhd.uu",
        NULL,        NULL,        NULL,        NULL,        NULL,        NULL,        NULL,        NULL
    }

};



BOOL vMop48HasRd[32] =
{
    YES,        YES,            YES,            YES,
//  "ld",       "lookupmh",     "lookupml",     "mop3",
    NO,         NO,             NO,             YES,
//  "st",       "indexwritemh", "indexwriteml", "mop7",
    YES,        NO,             YES,            YES,
//  "readlut",  "writelut",     NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    YES,        YES,            YES,            YES,
//  "mop24",    "mop25",        "mop26",        "mop27",
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
};



BOOL vMop48HasRa[32] =
{
    NO,         NO,             NO,             NO,
//  "ld",       "lookupmh",     "lookupml",     "mop3",
    YES,        YES,            YES,            NO,
//  "st",       "indexwritemh", "indexwriteml", "mop7",
    NO,         YES,            YES,            YES,
//  "readlut",  "writelut",     NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    NO,         YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    NO,         NO,             NO,             NO,
//  "mop24",    "mop25",        "mop26",        "mop27",
    YES,        YES,            YES,            YES
//  NULL,       NULL,           NULL,           NULL,
};



char * vMop48[32] =
{
    "ld",       "lookupmh",     "lookupml",     "mop3",
    "st",       "indexwritemh", "indexwriteml", "mop7",
    "readlut",  "writelut",     "mop10?",       "mop11?",
    "mop12?",   "mop13?",       "mop14?",       "mop15?",
    "mop16?",   "mop17?",       "mop18?",       "mop19?",
    "mop20?",   "mop21?",       "mop22?",       "mop23?",
    "mop24?",   "mop25?",       "mop26?",       "mop27?",
    "mop28?",   "mop29?",       "mop30?",       "mop31?"
};



BOOL vMop80HasRd[32] =
{
    YES,        YES,            YES,            YES,
//  "ld",       "lookupmh",     "lookupml",     "mop3",
    NO,         NO,             NO,             YES,
//  "st",       "indexwritemh", "indexwriteml", "mop7",
    YES,        NO,             YES,            YES,
//  "readlut",  "writelut",     NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    YES,        YES,            YES,            YES,
//  "readacc",  "mop25",        "mop26",       "mop27",
    YES,        YES,            YES,            YES
//  NULL,       NULL,           NULL,           NULL,
};



BOOL vMop80HasRa[32] =
{
    NO,         NO,             NO,             NO,
//  "ld",       "lookupmh",     "lookupml",     "mop3",
    YES,        YES,            YES,            NO,
//  "st",       "indexwritemh", "indexwriteml", "mop7",
    NO,         YES,            YES,            YES,
//  "readlut",  "writelut",     NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    NO,         NO,             NO,             NO,
//  "readacc",  "mop25",        "mop26",       "mop27",
    YES,        YES,            YES,            YES
//  NULL,       NULL,           NULL,           NULL,
};



BOOL vMop80HasMopWidth[32] =
{
    YES,        YES,            YES,            YES,
//  "ld",       "lookupmh",     "lookupml",     "mop3",
    YES,        YES,            YES,            YES,
//  "st",       "indexwritemh", "indexwriteml", "mop7",
    YES,        YES,            YES,            YES,
//  "readlut",  "writelut",     NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
    NO,         YES,            YES,            YES,
//  "readacc",  "mop25",        "mop26",       "mop27",
    YES,        YES,            YES,            YES,
//  NULL,       NULL,           NULL,           NULL,
};



char * vMop80[32] =
{
    "ld",       "lookupmh",     "lookupml",     "mop3?",
    "st",       "indexwritemh", "indexwriteml", "mop7?",
    "readlut",  "writelut",     NULL,           NULL,
    NULL,       NULL,           NULL,           NULL,
    NULL,       NULL,           NULL,           NULL,
    NULL,       NULL,           NULL,           NULL,
    "readacc",  "mop25?",       "mop26?",       "mop27?",
    NULL,       NULL,           NULL,           NULL,
};



char * vName[6] =
{
    "h8", "h16", "h32", "v8", "v16", "v32"
};



int vector48(uint16_t w0, VC4Context * context, DisasmStruct * disasm, NSUInteger mode)
{
    uint16_t w1 = [context->_file readInt16AtVirtualAddress:disasm->virtualAddr + 2];
    uint16_t w2 = [context->_file readInt16AtVirtualAddress:disasm->virtualAddr + 4];
    uint32_t l1 = ((uint32_t) w1 << 16) | w2;

    int arg = 0;
    int udx = 0;

    if ((w0 & 0xfc00) == 0xf000 && (l1 & 0x00000780) == 0x00000380 && vMop48[bits(w0, 9, 5)])
    {
        int Rd   = bits(l1,31,10);
        int Ra   = bits(l1,21,10);
        int Rb   = bits(l1, 5, 6);
        int Rs   = bits(w0, 2, 3);
        int Dird = bits(Rd, 6, 1);
        int Dira = bits(Ra, 6, 1);
        int mop  = bits(w0, 9, 5);

        sprintf(disasm->instruction.mnemonic, "v%s%s", vWidth[bits(w0, 4,2)], vMop48[mop]);
        disasm->instruction.userData = VC4_INST_OTHER;

        if (vMop48HasRd[mop])
        {
            OPERAND_RD48(Rd, bits(l1,11,1), Rs);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vMop48HasRa[mop])
        {
            Ra = (Ra & 0x3bf) | (Dird << 6);
            OPERAND_RA48(Ra, Dira, Rs);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vMop48HasRd[bits(w0, 9, 5)] && ((Rb & 0xf) == 15))
            OPERAND_VALUE(0, 32);
        else if (!vMop48HasRd[bits(w0, 9, 5)] && ((Rb & 0xf) == 15))
            OPERAND_RAWSTRING("-");
        else
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(Rb & 0xf);
            OPERAND_RAWSTRING(")");
        }
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        if (vF[bits(l1,6,1)])
        {
            OPERAND_RAWSTRING(vF[bits(l1,6,1)]);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        return 6;
    }
    else if ((w0 & 0xfc00) == 0xf000 && (l1 & 0x00000400) == 0x00000000 && vMop48[bits(w0, 9, 5)])
    {
        int Rd = bits(l1,31,10);
        int Ra = bits(l1,21,10);
        int Rb = bits(l1,9,10);
        int Rs = bits(w0, 2, 3);
        int Dird = bits(Rd, 6, 1);
        int Dira = bits(Ra, 6, 1);
        int Dirb = bits(Rb, 6, 1);

        sprintf(disasm->instruction.mnemonic, "v%s%s", vWidth[bits(w0, 4,2)], vMop48[bits(w0, 9, 5)]);
        disasm->instruction.userData = VC4_INST_OTHER;

        if (vMop48HasRd[bits(w0, 9, 5)])
        {
            OPERAND_RD48(Rd, bits(l1,11,1), Rs);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vMop48HasRa[bits(w0, 9, 5)])
        {
            Ra = (Ra & 0x3bf) | (Dird << 6);
            OPERAND_RA48(Ra, Dira, Rs);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        Rb = (Rb & 0x3bf) | (Dird << 6);
        OPERAND_RB48(Rb, Dirb, Rs);
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        return 6;
    }
    else if ((w0 & 0xfc00) == 0xf000 && (l1 & 0x00000400) == 0x00000400 && vMop48[bits(w0, 9, 5)])
    {
        int Rd = bits(l1,31,10);
        int Ra = bits(l1,21,10);
        int imm = msbextendedbits(l1, 5, 6);
        int Rs = bits(w0, 2, 3);
        int Dird = bits(Rd, 6, 1);
        int Dira = bits(Ra, 6, 1);

        sprintf(disasm->instruction.mnemonic, "v%s%s", vWidth[bits(w0, 4,2)], vMop48[bits(w0, 9, 5)]);
        disasm->instruction.userData = VC4_INST_OTHER;

        if (vMop48HasRd[bits(w0, 9, 5)])
        {
            OPERAND_RD48(Rd, bits(l1,11,1), Rs);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vMop48HasRa[bits(w0, 9, 5)])
        {
            Ra = (Ra & 0x3bf) | (Dird << 6);
            OPERAND_RA48(Ra, Dira, Rs);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        OPERAND_ADDRESS32(imm);
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        if (vF[bits(l1,6,1)])
        {
            OPERAND_RAWSTRING(vF[bits(l1,6,1)]);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vP[bits(l1, 9, 3)])
        {
            OPERAND_RAWSTRING(vP[bits(l1, 9, 3)]);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }
        
        return 6;
    }
    else if ((w0 & 0xfc00) == 0xf400 && (l1 & 0x00000780) == 0x00000380 && vOp[bits(w0, 9, 1)][bits(w0, 8, 6)])
    {
        int Rs = bits(w0, 2, 3);
        int Rd = bits(l1,31,10);
        int Ra = bits(l1,21,10);
        int z  = bits(l1,11, 1);
        int F  = bits(l1, 6, 1);
        int Rb = bits(l1, 3, 4);
        int op = bits(w0, 8, 6);
        int x  = bits(w0, 9, 1);

        int Dird = bits(Rd, 6, 1);
        int Dira = bits(Ra, 6, 1);

        sprintf(disasm->instruction.mnemonic, "v%s%s", vX[x], vOp[x][op]);
        disasm->instruction.userData = VC4_INST_OTHER;

        OPERAND_RD48(Rd, z, Rs);
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        if (vOpHasRa[x][op])
        {
            Ra = (Ra & 0x3bf) | (Dird << 6);
            OPERAND_RA48(Ra, Dira, Rs);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vOpHasRb[x][op])
        {
            if (Rb == 15)
                OPERAND_VALUE(0, 32);
            else
                OPERAND_REGISTERGP(Rb);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vF[F])
        {
            OPERAND_RAWSTRING(vF[F]);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        return 6;
    }
    else if ((w0 & 0xfc00) == 0xf400 && (l1 & 0x00000400) == 0x00000000 && vOp[bits(w0, 9, 1)][bits(w0, 8, 6)])
    {
        int Rd = bits(l1,31,10);
        int Ra = bits(l1,21,10);
        int Rb = bits(l1,9,10);
        int op = bits(w0, 8, 6);
        int Rs = bits(w0, 2, 3);
        int x  = bits(w0, 9, 1);
        int Dird = bits(Rd, 6, 1);
        int Dira = bits(Ra, 6, 1);
        int Dirb = bits(Rb, 6, 1);

        sprintf(disasm->instruction.mnemonic, "v%s%s", vX[x], vOp[x][op]);
        disasm->instruction.userData = VC4_INST_OTHER;

        OPERAND_RD48(Rd, bits(l1,11,1), Rs);
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        if (vOpHasRa[x][op])
        {
            Ra = (Ra & 0x3bf) | (Dird << 6);
            OPERAND_RA48(Ra, Dira, Rs);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vOpHasRb[x][op])
        {
            Rb = (Rb & 0x3bf) | (Dird << 6);
            OPERAND_RB48(Rb, Dirb, Rs);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        return 6;
    }
    else if ((w0 & 0xfc00) == 0xf400 && (l1 & 0x00000400) == 0x00000400 && vOp[bits(w0, 9, 1)][bits(w0, 8, 6)])
    {
        int Rd = bits(l1,31,10);
        int Ra = bits(l1,21,10);
        int Rs = bits(w0, 2, 3);
        int op = bits(w0, 8, 6);
        int x  = bits(w0, 9, 1);
        int imm = msbextendedbits(l1, 5, 6);
        int Dird = bits(Rd, 6, 1);
        int Dira = bits(Ra, 6, 1);

        sprintf(disasm->instruction.mnemonic, "v%s%s", vX[x], vOp[x][op]);
        disasm->instruction.userData = VC4_INST_OTHER;

        OPERAND_RD48(Rd, bits(l1,11,1), Rs);
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        if (vOpHasRa[x][op])
        {
            Ra = (Ra & 0x3bf) | (Dird << 6);
            OPERAND_RA48(Ra, Dira, Rs);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vOpHasRb[x][op])
        {
            OPERAND_VALUE(imm, vXwidth[x]);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vF[bits(l1,6,1)])
        {
            OPERAND_RAWSTRING(vF[bits(l1,6,1)]);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vP[bits(l1, 9, 3)])
        {
            OPERAND_RAWSTRING(vP[bits(l1, 9, 3)]);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }
        
        return 6;
    }

    return DISASM_UNKNOWN_OPCODE;
}



int vector80(uint16_t w0, VC4Context * context, DisasmStruct * disasm, NSUInteger mode)
{
    uint16_t w1 = [context->_file readInt16AtVirtualAddress:disasm->virtualAddr + 2];
    uint16_t w2 = [context->_file readInt16AtVirtualAddress:disasm->virtualAddr + 4];
    uint32_t l1 = ((uint32_t) w1 << 16) | w2;
    uint16_t w3 = [context->_file readInt16AtVirtualAddress:disasm->virtualAddr + 6];
    uint16_t w4 = [context->_file readInt16AtVirtualAddress:disasm->virtualAddr + 8];
    uint32_t l2 = ((uint32_t) w3 << 16) | w4;

    int arg = 0;
    int udx = 0;

    if ((w0 & 0xfc00) == 0xf800 && ((l1 & 0xe0000780) == 0xe0000380) && vMop80[bits(w0, 9, 5)])
    {
        int counter = 0;

        int mop  = bits(w0, 9, 5);
        int wid  = bits(w0, 4, 2);
        int rep  = bits(w0, 2, 3);

        int Ra   = bits(l1,21,10);
        int setf = bits(l1,11, 1);

        int f_d  = bits(l2,31, 6);
        int f_a  = bits(l2,25, 6);
        int h    = bits(l2,19, 4);
        int cond = bits(l2,15, 3);
        int Rs   = bits(l2, 5, 4);

        int imm  = (msbextendedbits2(l2,12, 7, 1, 2) << 7) | bits(l1, 6, 7);
        int reg  = 15;

        sprintf(disasm->instruction.mnemonic, "v%s%s", vMop80HasMopWidth[mop] ? vWidth[wid] : vReadAccWidth[wid], vMop80[mop]);
        disasm->instruction.userData = VC4_INST_OTHER;

        reg = f_d >> 2;

        OPERAND_RA80(Ra, f_a, h);
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        if (reg != 15 && rep)
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(Rs);
            OPERAND_VALUEWITHSIGN(imm, 16);
            OPERAND_RAWSTRING("+=");
            OPERAND_REGISTERGP(reg);
            OPERAND_RAWSTRING(")");

            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }
        else
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(Rs);
            OPERAND_VALUEWITHSIGN(imm, 16);
            OPERAND_RAWSTRING(")");

            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vF[setf])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vF[setf]);
        }
        if (vP[cond])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vP[cond]);
        }
        if (vRep[rep])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vRep[rep]);
        }

        if (counter)
        {
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }
        
        return 10;
    }
    else if ((w0 & 0xfc00) == 0xf800 && ((l1 & 0x00380780) == 0x00380380) && vMop80[bits(w0, 9, 5)])
    {
        int counter = 0;

        int mop  = bits(w0, 9, 5);
        int wid  = bits(w0, 4, 2);
        int rep  = bits(w0, 2, 3);

        int Rd   = bits(l1,31,10);
        int setf = bits(l1,11, 1);

        int f_d  = bits(l2,31, 6);
        int f_a  = bits(l2,25, 6);
        int cond = bits(l2,15, 3);
        int Rs   = bits(l2, 5, 4);

        int imm  = (msbextendedbits2(l2,12, 7, 1, 2) << 7) | bits(l1, 6, 7);
        int reg  = 15;

        sprintf(disasm->instruction.mnemonic, "v%s%s", vMop80HasMopWidth[mop] ? vWidth[wid] : vReadAccWidth[wid], vMop80[mop]);
        disasm->instruction.userData = VC4_INST_OTHER;

        reg = f_a >> 2;

        OPERAND_RD80(Rd, f_d);
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        if (reg != 15 && rep)
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(Rs);
            OPERAND_VALUEWITHSIGN(imm, 16);
            OPERAND_RAWSTRING("+=");
            OPERAND_REGISTERGP(reg);
            OPERAND_RAWSTRING(")");

            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }
        else
        {
            OPERAND_RAWSTRING("(");
            OPERAND_REGISTERGP(Rs);
            OPERAND_VALUEWITHSIGN(imm, 16);
            OPERAND_RAWSTRING(")");

            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vF[setf])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vF[setf]);
        }
        if (vP[cond])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vP[cond]);
        }
        if (vRep[rep])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vRep[rep]);
        }

        if (counter)
        {
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }
        
        return 10;
    }
    else if ((w0 & 0xfc00) == 0xf800 && ((l1 & 0x00000400) == 0x00000000) && vMop80[bits(w0, 9, 5)])
    {
        int counter = 0;

        int mop  = bits(w0, 9, 5);
        int wid  = bits(w0, 4, 2);
        int rep  = bits(w0, 2, 3);

        int Rd   = bits(l1,31,10);
        int Ra   = bits(l1,21,10);
        int setf = bits(l1,11, 1);
        int Rb   = bits(l1, 9,10);

        int f_d  = bits(l2,31, 6);
        int f_a  = bits(l2,25, 6);
        int h    = bits(l2,19, 4);
        int cond = bits(l2,15, 3);
        int e    = bits(l2,12, 7);
        int f_b  = bits(l2, 5, 6);

        sprintf(disasm->instruction.mnemonic, "v%s%s", vMop80HasMopWidth[mop] ? vWidth[wid] : vReadAccWidth[wid], vMop80[mop]);
        disasm->instruction.userData = VC4_INST_OTHER;

        if (vMop80HasRd[mop])
        {
            OPERAND_RD80(Rd, f_d);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vMop80HasRa[mop])
        {
            OPERAND_RA80(Ra, f_a, h);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        OPERAND_RB80(Rb, f_b);
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        if (vF[setf])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vF[setf]);
        }
        if (vP[cond])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vP[cond]);
        }
        if (vRep[rep])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vRep[rep]);
        }
        if (vAccSRU[e])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vAccSRU[e]);
            if (vAccSRUHasReg[e]) { OPERAND_RAWSTRING(" "); OPERAND_REGISTERGP(e & 7); }

        }

        if (counter)
        {
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        return 10;
    }
    else if ((w0 & 0xfc00) == 0xf800 && ((l1 & 0x00000400) == 0x00000400) && vMop80[bits(w0, 9, 5)])
    {
        int counter = 0;

        int mop  = bits(w0, 9, 5);
        int wid  = bits(w0, 4, 2);
        int rep  = bits(w0, 2, 3);

        int Rd   = bits(l1,31,10);
        int Ra   = bits(l1,21,10);
        int setf = bits(l1,11, 1);

        int f_d  = bits(l2,31, 6);
        int f_a  = bits(l2,25, 6);
        int h    = bits(l2,19, 4);
        int cond = bits(l2,15, 3);
        int e    = bits(l2,12, 7);

        int imm  = msbextendedbits((bits(l2, 5, 6) << 10) | bits(l1, 9,10),15,16);

        sprintf(disasm->instruction.mnemonic, "v%s%s", vMop80HasMopWidth[mop] ? vWidth[wid] : vReadAccWidth[wid], vMop80[mop]);
        disasm->instruction.userData = VC4_INST_OTHER;

        if (vMop80HasRd[mop])
        {
            OPERAND_RD80(Rd, f_d);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vMop80HasRa[mop])
        {
            OPERAND_RA80(Ra, f_a, h);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        OPERAND_SIGNED(imm, 16);
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        if (vF[setf])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vF[setf]);
        }
        if (vP[cond])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vP[cond]);
        }
        if (vRep[rep])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vRep[rep]);
        }
        if (vAccSRU[e])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vAccSRU[e]);
            if (vAccSRUHasReg[e]) { OPERAND_RAWSTRING(" "); OPERAND_REGISTERGP(e & 7); }
        }

        if (counter)
        {
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }
        
        return 10;
    }
    else if ((w0 & 0xfc00) == 0xfc00 && ((l1 & 0x00000400) == 0x00000000) && vOp[bits(w0, 9, 1)][bits(w0, 8, 6)])
    {
        int counter = 0;

        int wid  = bits(w0, 9, 1);
        int op   = bits(w0, 8, 6);
        int rep  = bits(w0, 2, 3);

        int Rd   = bits(l1,31,10);
        int Ra   = bits(l1,21,10);
        int setf = bits(l1,11, 1);
        int Rb   = bits(l1, 9,10);

        int f_d  = bits(l2,31, 6);
        int f_a  = bits(l2,25, 6);
        int h    = bits(l2,19, 4);
        int cond = bits(l2,15, 3);
        int e    = bits(l2,12, 7);
        int f_b  = bits(l2, 5, 6);

        sprintf(disasm->instruction.mnemonic, "v%s%s", vX[wid], vOp[wid][op]);
        disasm->instruction.userData = VC4_INST_OTHER;

        OPERAND_RD80(Rd, f_d);
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        if (vOpHasRa[wid][op])
        {
            OPERAND_RA80(Ra, f_a, h);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vOpHasRb[wid][op])
        {
            OPERAND_RB80(Rb, f_b);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vF[setf])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vF[setf]);
        }
        if (vP[cond])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vP[cond]);
        }
        if (vRep[rep])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vRep[rep]);
        }
        if (vAccSRU[e])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vAccSRU[e]);
            if (vAccSRUHasReg[e]) { OPERAND_RAWSTRING(" "); OPERAND_REGISTERGP(e & 7); }
        }

        if (counter)
        {
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        return 10;
    }
    else if ((w0 & 0xfc00) == 0xfc00 && ((l1 & 0x00000400) == 0x00000400) && vOp[bits(w0, 9, 1)][bits(w0, 8, 6)])
    {
        int counter = 0;

        int wid  = bits(w0, 9, 1);
        int op   = bits(w0, 8, 6);
        int rep  = bits(w0, 2, 3);

        int Rd   = bits(l1,31,10);
        int Ra   = bits(l1,21,10);
        int setf = bits(l1,11, 1);

        int f_d  = bits(l2,31, 6);
        int f_a  = bits(l2,25, 6);
        int h    = bits(l2,19, 4);
        int cond = bits(l2,15, 3);
        int e    = bits(l2,12, 7);

        int imm  = msbextendedbits((bits(l2, 5, 6) << 10) | bits(l1, 9,10),15,16); // sign extended immediate value

        sprintf(disasm->instruction.mnemonic, "v%s%s", vX[wid], vOp[wid][op]);
        disasm->instruction.userData = VC4_INST_OTHER;

        OPERAND_RD80(Rd, f_d);
        disasm->operand[arg].type = DISASM_OPERAND_OTHER;
        arg++; udx = 0;

        if (vOpHasRa[wid][op])
        {
            OPERAND_RA80(Ra, f_a, h);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vOpHasRb[wid][op])
        {
            OPERAND_VALUE(imm, vXwidth[wid]);
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        if (vF[setf])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vF[setf]);
        }
        if (vP[cond])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vP[cond]);
        }
        if (vRep[rep])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vRep[rep]);
        }
        if (vAccSRU[e])
        {
            if (counter++) OPERAND_RAWSTRING(" ");
            OPERAND_RAWSTRING(vAccSRU[e]);
            if (vAccSRUHasReg[e]) { OPERAND_RAWSTRING(" "); OPERAND_REGISTERGP(e & 7); }
        }

        if (counter)
        {
            disasm->operand[arg].type = DISASM_OPERAND_OTHER;
            arg++; udx = 0;
        }

        return 10;
    }

    return DISASM_UNKNOWN_OPCODE;
}
