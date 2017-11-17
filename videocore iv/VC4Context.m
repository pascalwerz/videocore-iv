//
//  VC4Context.m
//  videocore iv
//
//  Created by Pascal Werz on 05/02/2016.
//  Copyright © 2016 Pascal Werz. All rights reserved.
//

#import "VC4Context.h"
#import "VC4Definition.h"
#import "VC4Disassembly.h"
#import "VC4InstructionDefs.h"




@implementation VC4Context

- (instancetype)initWithCPU:(VC4Definition *)cpu andFile:(NSObject<HPDisassembledFile> *)file
{
    if (self = [super init])
    {
        _cpu = cpu;
        _file = file;
        _currentProcedure = nil;
    }
    return self;
}



- (NSObject<CPUDefinition> *)cpuDefinition
{
    return _cpu;
}



- (void)initDisasmStructure:(DisasmStruct *)disasm withSyntaxIndex:(NSUInteger)syntaxIndex
{
    disasm->syntaxIndex = 0;
    memset(&disasm->prefix, 0, sizeof(disasm->prefix));
    memset(disasm->implicitlyReadRegisters, 0, sizeof(disasm->implicitlyReadRegisters));
    memset(disasm->implicitlyWrittenRegisters, 0, sizeof(disasm->implicitlyWrittenRegisters));

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
}



- (Address)adjustCodeAddress:(Address)address
{
    // Instructions are always aligned to a multiple of 2.
    return address & ~1;
}



- (uint8_t)cpuModeFromAddress:(Address)address
{
    return 0;
}



- (BOOL)addressForcesACPUMode:(Address)address
{
    return NO;
}



- (uint8_t)estimateCPUModeAtVirtualAddress:(Address)address
{
    return 0;
}



- (Address)nextAddressToTryIfInstructionFailedToDecodeAt:(Address)address forCPUMode:(uint8_t)mode
{
    return ((address & ~1) + 2);
}



- (int)isNopAt:(Address)address
{
    uint16_t w0 = [_file readUInt16AtVirtualAddress:address];
    return (w0 == 0x0001) ? 2 : 0;
}



- (BOOL)hasProcedurePrologAt:(Address)address
{
    BOOL isProlog;
    uint16_t w0,w1,w2;
    uint32_t l1;
    int o;

    if (address == BAD_ADDRESS) return NO;

    isProlog = NO;

    o = 0;

    w0 = [_file readUInt16AtVirtualAddress:address+o];

    if ((w0 & 0xff80) == 0x0380)                                                    // push lr, rn-rm
    {
        o += 2;
        w0 = [_file readUInt16AtVirtualAddress:address+o];
    }

    w1 = [_file readUInt16AtVirtualAddress:address+o+2];

    while ( ((w0 & 0xff80) == 0x0280) || ( ((w0 & 0xffe0) == 0xa420) && (w1 == 0xcf00) ) )    // push rn-rm || st rd,--(sp)
    {
        if ((w0 & 0xff80) == 0x0280) o += 2; else o += 4;

        w0 = [_file readUInt16AtVirtualAddress:address+o];
        w1 = [_file readUInt16AtVirtualAddress:address+o+2];
    }

    if ((w0 & 0xfc1f) == 0x1419) isProlog = YES;                                    // lea sp, -o*4(sp)

    else if ( (w0 == 0xb059) && ((w1 & 0x8000) == 0x8000) ) isProlog = YES;         // add sp,#-i
    else if ( (w0 == 0xb0d9) && ((w1 & 0x8000) == 0x0000) ) isProlog = YES;         // sub sp,#+i
    else if ( (w0 == 0xb279) && ((w1 & 0x8000) == 0x8000) ) isProlog = YES;         // addscale sp,#-i << 1
    else if ( (w0 == 0xb2b9) && ((w1 & 0x8000) == 0x8000) ) isProlog = YES;         // addscale sp,#-i << 2
    else if ( (w0 == 0xb2d9) && ((w1 & 0x8000) == 0x8000) ) isProlog = YES;         // addscale sp,#-i << 3
    else if ( (w0 == 0xb2f9) && ((w1 & 0x8000) == 0x8000) ) isProlog = YES;         // addscale sp,#-i << 4

    else if ( (w0 == 0xb739) && ((w1 & 0x8000) == 0x8000) ) isProlog = YES;         // add sp, -o

    else if ( (w0 == 0xc059) && ((w1 & 0xffe0) == 0xcf60) ) isProlog = YES;         // add sp,sp,#-i
    else if ( (w0 == 0xc0d9) && ((w1 & 0xffe0) == 0xcf40) ) isProlog = YES;         // sub sp,sp,#+i
    else if ( (w0 == 0xc279) && ((w1 & 0xffe0) == 0xcf60) ) isProlog = YES;         // addscale sp,sp,#-i << 1
    else if ( (w0 == 0xc2b9) && ((w1 & 0xffe0) == 0xcf60) ) isProlog = YES;         // addscale sp,sp,#-i << 2
    else if ( (w0 == 0xc2d9) && ((w1 & 0xffe0) == 0xcf60) ) isProlog = YES;         // addscale sp,sp,#-i << 3
    else if ( (w0 == 0xc2f9) && ((w1 & 0xffe0) == 0xcf60) ) isProlog = YES;         // addscale sp,sp,#-i << 4

    else if ( (w0 == 0xc599) && ((w1 & 0xffe0) == 0xcf60) ) isProlog = YES;         // addscale sp,sp,#-i << 5
    else if ( (w0 == 0xc5b9) && ((w1 & 0xffe0) == 0xcf60) ) isProlog = YES;         // addscale sp,sp,#-i << 6
    else if ( (w0 == 0xc5d9) && ((w1 & 0xffe0) == 0xcf60) ) isProlog = YES;         // addscale sp,sp,#-i << 7
    else if ( (w0 == 0xc5f9) && ((w1 & 0xffe0) == 0xcf60) ) isProlog = YES;         // addscale sp,sp,#-i << 8

    else if ( (w0 == 0xc639) && ((w1 & 0xffe0) == 0xcf40) ) isProlog = YES;         // subscale sp,sp,#+i << 1
    else if ( (w0 == 0xc659) && ((w1 & 0xffe0) == 0xcf40) ) isProlog = YES;         // subscale sp,sp,#+i << 2
    else if ( (w0 == 0xc679) && ((w1 & 0xffe0) == 0xcf40) ) isProlog = YES;         // subscale sp,sp,#+i << 3
    else if ( (w0 == 0xc699) && ((w1 & 0xffe0) == 0xcf40) ) isProlog = YES;         // subscale sp,sp,#+i << 4
    else if ( (w0 == 0xc6b9) && ((w1 & 0xffe0) == 0xcf40) ) isProlog = YES;         // subscale sp,sp,#+i << 5
    else if ( (w0 == 0xc6d9) && ((w1 & 0xffe0) == 0xcf40) ) isProlog = YES;         // subscale sp,sp,#+i << 6
    else if ( (w0 == 0xc6f9) && ((w1 & 0xffe0) == 0xcf40) ) isProlog = YES;         // subscale sp,sp,#+i << 7

    else if ( (w0 == 0xc719) && ((w1 & 0xffe0) == 0xcf40) ) isProlog = YES;         // subscale sp,sp,#+i << 8

    w2 = [_file readUInt16AtVirtualAddress:address+o+4];
    l1 = (w2 << 16) | w1;

    if ( (w0 == 0xe859) && ((l1 & 0x80000000) == 0x80000000) ) isProlog = YES;      // add sp,#-u
    else if ( (w0 == 0xe8d9) && ((l1 & 0x80000000) == 0x00000000) ) isProlog = YES; // sub sp,#+u
    else if ( (w0 == 0xe819) && ((l1 & 0x80000000) == 0x80000000) ) isProlog = YES; // addscale sp,#-u << 1
    else if ( (w0 == 0xe8b9) && ((l1 & 0x80000000) == 0x80000000) ) isProlog = YES; // addscale sp,#-u << 2
    else if ( (w0 == 0xe8d9) && ((l1 & 0x80000000) == 0x80000000) ) isProlog = YES; // addscale sp,#-u << 3
    else if ( (w0 == 0xe8f9) && ((l1 & 0x80000000) == 0x80000000) ) isProlog = YES; // addscale sp,#-u << 4

    else if ( (w0 == 0xef39) && ((l1 & 0x80000000) == 0x80000000) ) isProlog = YES; // add sp,sp,#-u

    return isProlog;
}



- (NSUInteger)detectedPaddingLengthAt:(Address)address
{
    return 0;
}



- (void)analysisBeginsAt:(Address)entryPoint
{
}



- (void)analysisEnded
{
}



- (void)procedureAnalysisBeginsForProcedure:(NSObject<HPProcedure> *)procedure atEntryPoint:(Address)entryPoint
{
    _currentProcedure = procedure;
}



/// The prolog of the created procedure is being analyzed.
/// Warning: this method is not called at the begining of the procedure creation, but once all basic blocks
/// have been created.
- (void)procedureAnalysisOfPrologForProcedure:(NSObject<HPProcedure> *)procedure atEntryPoint:(Address)entryPoint
{
}



- (void)procedureAnalysisOfEpilogForProcedure:(NSObject<HPProcedure> *)procedure atEntryPoint:(Address)entryPoint
{
}



- (void)procedureAnalysisEndedForProcedure:(NSObject<HPProcedure> *)procedure atEntryPoint:(Address)entryPoint
{
    _currentProcedure = nil;
}



- (void)procedureAnalysisContinuesOnBasicBlock:(NSObject<HPBasicBlock> *)basicBlock
{
}



- (void)resetDisassembler
{
    _currentProcedure = nil;
}



- (int)disassembleSingleInstruction:(DisasmStruct *)disasm usingProcessorMode:(NSUInteger)mode
{
    int instLength;

    //    NSLog(@"disassembleSingleInstruction %jx", (uintmax_t)disasm->virtualAddr);
    if (disasm->bytes == NULL) return DISASM_UNKNOWN_OPCODE;

    // disasm is already initialized
    instLength = disassemble(self, disasm, mode);

    // safety net
    return (instLength > 0) ? instLength : DISASM_UNKNOWN_OPCODE;
}



- (BOOL)instructionHaltsExecutionFlow:(DisasmStruct *)disasm
{
    return NO;
}



- (void)performProcedureAnalysis:(NSObject<HPProcedure> *)procedure basicBlock:(NSObject<HPBasicBlock> *)basicBlock disasm:(DisasmStruct *)disasm
{
}



- (void)updateProcedureAnalysis:(DisasmStruct *)disasm
{
}



- (BOOL)instructionCanBeUsedToExtractDirectMemoryReferences:(DisasmStruct *)disasm
{
    return YES;
}



- (BOOL)instructionOnlyLoadsAddress:(DisasmStruct *)disasmStruct
{
    if (disasmStruct->instruction.userData == VC4_INST_LEA)
        return YES;
    return NO;
}



- (BOOL)instructionMayBeASwitchStatement:(DisasmStruct *)disasm
{
    // scalar16
    uint16_t w0 = [_file readUInt16AtVirtualAddress:disasm->virtualAddr];

    if ((w0 & 0xffc0) == 0x0040) return YES; // b/bl rd
    if ((w0 & 0xffd0) == 0x0080) return YES; // tbb/tbs rd

    return NO;
}



- (void)performBranchesAnalysis:(DisasmStruct *)disasm
           computingNextAddress:(Address *)next
                    andBranches:(NSMutableArray<NSNumber *> *)branches
                   forProcedure:(NSObject<HPProcedure> *)procedure
                     basicBlock:(NSObject<HPBasicBlock> *)basicBlock
                      ofSegment:(NSObject<HPSegment> *)segment
                calledAddresses:(NSMutableArray<NSNumber *> *)calledAddresses
                      callsites:(NSMutableArray<NSNumber *> *)callSitesAddresses
{
    // safety: remove any BAD_ADDRESS still present
    [branches removeObject:[NSNumber numberWithInteger:BAD_ADDRESS]];
    [calledAddresses removeObject:[NSNumber numberWithInteger:BAD_ADDRESS]];
    [callSitesAddresses removeObject:[NSNumber numberWithInteger:BAD_ADDRESS]];
}



- (void)performInstructionSpecificAnalysis:(DisasmStruct *)disasm forProcedure:(NSObject<HPProcedure> *)procedure inSegment:(NSObject<HPSegment> *)segment
{
}



- (Address)getThunkDestinationForInstructionAt:(Address)address
{
    return BAD_ADDRESS;
}



- (NSObject<HPASMLine> *)buildMnemonicString:(DisasmStruct *)disasm inFile:(NSObject<HPDisassembledFile> *)file
{
    NSObject<HPHopperServices> *services = _cpu->_services;
    NSObject<HPASMLine> *line = [services blankASMLine];
    [line appendMnemonic:@(disasm->instruction.mnemonic)];
    [line appendSpacesUntil:16];    // largest known opcode is 15 chars: "vindexwriteml32"

    return line;
}



- (NSObject<HPASMLine> *)buildOperandString:(DisasmStruct *)disasm forOperandIndex:(NSUInteger)operandIndex inFile:(NSObject<HPDisassembledFile> *)file raw:(BOOL)raw
{
    uint64_t mask[65] =
    {
        0x0ull, 0x1ull, 0x3ull, 0x7ull, 0xfull, 0x1full, 0x3full, 0x7full, 0xffull,
        0x1ffull, 0x3ffull, 0x7ffull, 0xfffull, 0x1fffull, 0x3fffull, 0x7fffull, 0xffffull,
        0x1ffffull, 0x3ffffull, 0x7ffffull, 0xfffffull, 0x1fffffull, 0x3fffffull, 0x7fffffull, 0xffffffull,
        0x1ffffffull, 0x3ffffffull, 0x7ffffffull, 0xfffffffull, 0x1fffffffull, 0x3fffffffull, 0x7fffffffull, 0xffffffffull,
        0x1ffffffffull, 0x3ffffffffull, 0x7ffffffffull, 0xfffffffffull, 0x1fffffffffull, 0x3fffffffffull, 0x7fffffffffull, 0xffffffffffull,
        0x1ffffffffffull, 0x3ffffffffffull, 0x7ffffffffffull, 0xfffffffffffull, 0x1fffffffffffull, 0x3fffffffffffull, 0x7fffffffffffull, 0xffffffffffffull,
        0x1ffffffffffffull, 0x3ffffffffffffull, 0x7ffffffffffffull, 0xfffffffffffffull, 0x1fffffffffffffull, 0x3fffffffffffffull, 0x7fffffffffffffull, 0xffffffffffffffull,
        0x1ffffffffffffffull, 0x3ffffffffffffffull, 0x7ffffffffffffffull, 0xfffffffffffffffull, 0x1fffffffffffffffull, 0x3fffffffffffffffull, 0x7fffffffffffffffull, 0xffffffffffffffffull
    };
    char tmpString[256];
    NSObject<HPHopperServices> *services = _cpu->_services;
    NSObject<HPASMLine> *line = [services blankASMLine];
    char ** stringArray;
    uint64_t p1, p2, p3;

    if (operandIndex >= DISASM_MAX_OPERANDS) return nil;
    DisasmOperand *operand = disasm->operand + operandIndex;
    if (operand->type == DISASM_OPERAND_NO_OPERAND) return nil;

    for (int ud = 0; ud < DISASM_MAX_USER_DATA; ud++)
    {
        if (operand->userData[ud] == VC4_OPERAND_DATA_END)
            break;
        switch (operand->userData[ud])
        {
            default:
                NSLog(@"buildOperandString: invalid disasm->operand[%ju]->userData[%u] = %llx", (uintmax_t)operandIndex, ud, operand->userData[ud]);
                [line appendRawString:@((char *) operand->userData)];
                ud=DISASM_MAX_USER_DATA;
                break;
            case VC4_OPERAND_DATA_STRING:
                [line appendRawString:@((char *) operand->userData[++ud])];
                break;
            case VC4_OPERAND_DATA_STRINGARRAY:
                stringArray = (char **) operand->userData[++ud];
                [line appendRawString:@(stringArray[operand->userData[++ud]])];
                break;
            case VC4_OPERAND_DATA_REGISTERGP:
                p1 = operand->userData[++ud];
                [line appendRegister:@(regname[p1]) ofClass:RegClass_GeneralPurposeRegister andIndex:p1];
                break;
            case VC4_OPERAND_DATA_REGISTERSTRING:
                p1 = operand->userData[++ud];
                [line appendRegister:@((char *)p1)];
                break;
            case VC4_OPERAND_DATA_SIGNED:
                p1 = operand->userData[++ud];
                p2 = operand->userData[++ud];
                [line appendFormattedNumber:@([self formattedSigned:(int32_t)p1 argIndex:(int)operandIndex bitWidth:(int)p2 andPC:disasm->virtualAddr]) withValue:[NSNumber numberWithLong:(int32_t)(p1 & mask[p2])]];
                break;
            case VC4_OPERAND_DATA_UNSIGNED:
                p1 = operand->userData[++ud];
                p2 = operand->userData[++ud];
                [line appendFormattedNumber:@([self formattedUnsigned:(int32_t)p1 argIndex:(int)operandIndex bitWidth:(int)p2 andPC:disasm->virtualAddr]) withValue:[NSNumber numberWithUnsignedLong:(int32_t)(p1 & mask[p2])]];
                break;
            case VC4_OPERAND_DATA_DECIMAL:
                p1 = operand->userData[++ud];
                sprintf(tmpString, "%llu", p1);
                [line appendFormattedNumber:@(tmpString) withValue:[NSNumber numberWithUnsignedLong:p1]];
                break;
            case VC4_OPERAND_DATA_VALUE:
                p1 = operand->userData[++ud];
                p2 = operand->userData[++ud];
                [line appendFormattedNumber:@([self formattedValue:(int32_t)p1 argIndex:(int)operandIndex bitWidth:(int)p2 andPC:disasm->virtualAddr])  withValue:[NSNumber numberWithUnsignedLong:(int32_t)(p1 & mask[p2])]];
                break;
            case VC4_OPERAND_DATA_VALUECANBESIGNED:
                p1 = operand->userData[++ud];
                p2 = operand->userData[++ud];
                p3 = operand->userData[++ud];
                [line appendFormattedNumber:@([self formattedValue:(int32_t)p1 defaultAsSigned:p3 argIndex:(int)operandIndex bitWidth:(int)p2 andPC:disasm->virtualAddr]) withValue:[NSNumber numberWithUnsignedLong:(int32_t)(p1 & mask[p2])]];
                break;
            case VC4_OPERAND_DATA_VALUEWITHSIGN:
                p1 = operand->userData[++ud];
                p2 = operand->userData[++ud];
                if (p1) [line appendFormattedNumber:@([self formattedValueWithSign:(int32_t)p1 argIndex:(int)operandIndex bitWidth:(int)p2 andPC:disasm->virtualAddr]) withValue:[NSNumber numberWithLong:(int32_t)(p1 & mask[p2])]];
                break;
            case VC4_OPERAND_DATA_FLOAT32:
                p1 = operand->userData[++ud];
                [line appendString:@([self formattedFloat:(int32_t)p1 argIndex:(int)operandIndex bitWidth:32 andPC:disasm->virtualAddr])];
                break;
            case VC4_OPERAND_DATA_ADDRESS32:
                p1 = operand->userData[++ud];
                [line appendFormattedAddress:@([self formattedAddress:(uint32_t)p1 & 0xffffffff argIndex:(int)operandIndex andPC:disasm->virtualAddr]) withValue:p1 & 0xffffffff];
                break;
            case VC4_OPERAND_DATA_ADDRESS64:
                p1 = operand->userData[++ud];
                [line appendAddress:(Address)p1];
                break;
            case VC4_OPERAND_DATA_RA48:
                p1 = operand->userData[++ud];
                p2 = operand->userData[++ud];
                p3 = operand->userData[++ud];
                [line appendRegister:@(vRa48((int) p1, (int) p2, (int) p3, self, (int) operandIndex, disasm->virtualAddr))];
                break;
            case VC4_OPERAND_DATA_RB48:
                p1 = operand->userData[++ud];
                p2 = operand->userData[++ud];
                p3 = operand->userData[++ud];
                [line appendRegister:@(vRb48((int) p1, (int) p2, (int) p3, self, (int) operandIndex, disasm->virtualAddr))];
                break;
            case VC4_OPERAND_DATA_RD48:
                p1 = operand->userData[++ud];
                p2 = operand->userData[++ud];
                p3 = operand->userData[++ud];
                [line appendRegister:@(vRd48((int) p1, (int) p2, (int) p3))];
                break;
            case VC4_OPERAND_DATA_RA80:
                p1 = operand->userData[++ud];
                p2 = operand->userData[++ud];
                p3 = operand->userData[++ud];
                [line appendRegister:@(vRa80((int) p1, (int) p2, (int) p3, self, (int) operandIndex, disasm->virtualAddr))];
                break;
            case VC4_OPERAND_DATA_RB80:
                p1 = operand->userData[++ud];
                p2 = operand->userData[++ud];
                [line appendRegister:@(vRb80((int) p1, (int) p2, self, (int) operandIndex, disasm->virtualAddr))];
                break;
            case VC4_OPERAND_DATA_RD80:
                p1 = operand->userData[++ud];
                p2 = operand->userData[++ud];
                [line appendRegister:@(vRd80((int) p1, (int) p2))];
                break;
        }
    }

    [line setIsOperand:operandIndex startingAtIndex:0];

    return line;
}



- (NSObject<HPASMLine> *)buildCompleteOperandString:(DisasmStruct *)disasm inFile:(NSObject<HPDisassembledFile> *)file raw:(BOOL)raw
{
    NSObject<HPHopperServices> *services = _cpu->_services;
    NSObject<HPASMLine> *line = [services blankASMLine];

    for (int op_index = 0; op_index < DISASM_MAX_OPERANDS; op_index++) {
        NSObject<HPASMLine> *part = [self buildOperandString:disasm forOperandIndex:op_index inFile:file raw:raw];
        if (part == nil) break;
        if (op_index) [line appendRawString:@", "];
        [line append:part];
    }

    return line;
}



- (BOOL)canDecompileProcedure:(NSObject<HPProcedure> *)procedure
{
    return NO;
}



- (Address)skipHeader:(NSObject<HPBasicBlock> *)basicBlock ofProcedure:(NSObject<HPProcedure> *)procedure
{
    return basicBlock.from;
}



- (Address)skipFooter:(NSObject<HPBasicBlock> *)basicBlock ofProcedure:(NSObject<HPProcedure> *)procedure
{
    return basicBlock.to;
}



- (ASTNode *)decompileInstructionAtAddress:(Address)a
                                    disasm:(DisasmStruct *)d
                                 addNode_p:(BOOL *)addNode_p
                           usingDecompiler:(Decompiler *)decompiler
{
    return nil;
}



- (ASTNode *)rawDecodeArgumentIndex:(int)argIndex
                           ofDisasm:(DisasmStruct *)disasm
                  ignoringWriteMode:(BOOL)ignoreWrite
                    usingDecompiler:(Decompiler *)decompiler
{
    return nil;
}



- (NSData *)assembleRawInstruction:(NSString *)instr atAddress:(Address)addr forFile:(NSObject<HPDisassembledFile> *)file withCPUMode:(uint8_t)cpuMode usingSyntaxVariant:(NSUInteger)syntax error:(NSError **)error
{
    return nil;
}



- (NSString *)defaultFormattedVariableNameForDisplacement:(int64_t)displacement inProcedure:(NSObject<HPProcedure> *)procedure
{
    return [NSString stringWithFormat:@"var_%jd", (uintmax_t)displacement];
}



- (NSUInteger)stackArgumentSlotForDisplacement:(int64_t)displacement inProcedure:(NSObject<HPProcedure> *)procedure
{
    return -1;
}



- (int64_t)displacementForStackSlotIndex:(NSUInteger)slot inProcedure:(NSObject<HPProcedure> *)procedure
{
    return 0;
}



char * vRa48(int x, int f, int rs, VC4Context * context, int arg, Address pc)
{
    static char r[64];

    switch(bits(x,9,4))
    {
        case 0x0: sprintf(r, "%s(%u,0)",  vName[0], bits(x,5,6)); break;
        case 0x2: sprintf(r, "%s(%u,16)", vName[0], bits(x,5,6)); break;
        case 0x4: sprintf(r, "%s(%u,32)", vName[0], bits(x,5,6)); break;
        case 0x6: sprintf(r, "%s(%u,48)", vName[0], bits(x,5,6)); break;
        case 0x8: sprintf(r, "%s(%u,0)",  vName[1], bits(x,5,6)); break;
        case 0xa: sprintf(r, "%s(%u,32)", vName[1], bits(x,5,6)); break;
        case 0xc: sprintf(r, "%s(%u,0)",  vName[2], bits(x,5,6)); break;

        case 0x1: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x3: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x5: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x7: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x9: sprintf(r, "%s(%u,%u)", vName[4], bits(x,5,2) * 16, bits(x,7,1)*32+bits(x,3,4)); break;
        case 0xb: sprintf(r, "%s(%u,%u)", vName[4], bits(x,5,2) * 16, bits(x,7,1)*32+bits(x,3,4)); break;
        case 0xd: sprintf(r, "%s(%u,%u)", vName[5], bits(x,5,2) * 16, bits(x,3,4)); break;

        case 0xe:
        case 0xf: sprintf(r, "%s", [context formattedValue:0 argIndex:arg bitWidth:1 andPC:pc]); f = 0; break;
    }
    if (f) sprintf(r, "%s+%s", r, regname[rs & 0x7]);
    
    return r;
}



char * vRb48(int x, int f, int rs, VC4Context * context, int arg, Address pc)
{
    static char r[64];
    int reg = bits(x,3,4);

    switch(bits(x,9,4))
    {
        case 0x0: sprintf(r, "%s(%u,0)",  vName[0], bits(x,5,6)); break;
        case 0x2: sprintf(r, "%s(%u,16)", vName[0], bits(x,5,6)); break;
        case 0x4: sprintf(r, "%s(%u,32)", vName[0], bits(x,5,6)); break;
        case 0x6: sprintf(r, "%s(%u,48)", vName[0], bits(x,5,6)); break;
        case 0x8: sprintf(r, "%s(%u,0)",  vName[1], bits(x,5,6)); break;
        case 0xa: sprintf(r, "%s(%u,32)", vName[1], bits(x,5,6)); break;
        case 0xc: sprintf(r, "%s(%u,0)",  vName[2], bits(x,5,6)); break;

        case 0x1: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x3: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x5: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x7: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x9: sprintf(r, "%s(%u,%u)", vName[4], bits(x,5,2) * 16, bits(x,7,1)*32+bits(x,3,4)); break;
        case 0xb: sprintf(r, "%s(%u,%u)", vName[4], bits(x,5,2) * 16, bits(x,7,1)*32+bits(x,3,4)); break;
        case 0xd: sprintf(r, "%s(%u,%u)", vName[5], bits(x,5,2) * 16, bits(x,3,4)); break;

        case 0xe:
        case 0xf:
            if (reg != 15)
                sprintf(r, "%s", regname[reg]);
            else
                sprintf(r, "%s", [context formattedValue:0 argIndex:arg bitWidth:32 andPC:pc]);
            break;
    }
    if (f && (bits(x,9,4) < 0xe)) sprintf(r, "%s+%s", r, regname[rs & 0x7]);
    
    return r;
}



char * vRd48(int x, int f, int rs)
{
    static char r[64];

    switch(bits(x,9,4))
    {
        case 0x0: sprintf(r, "%s(%u,0)",  vName[0], bits(x,5,6)); break;
        case 0x2: sprintf(r, "%s(%u,16)", vName[0], bits(x,5,6)); break;
        case 0x4: sprintf(r, "%s(%u,32)", vName[0], bits(x,5,6)); break;
        case 0x6: sprintf(r, "%s(%u,48)", vName[0], bits(x,5,6)); break;
        case 0x8: sprintf(r, "%s(%u,0)",  vName[1], bits(x,5,6)); break;
        case 0xa: sprintf(r, "%s(%u,32)", vName[1], bits(x,5,6)); break;
        case 0xc: sprintf(r, "%s(%u,0)",  vName[2], bits(x,5,6)); break;

        case 0x1: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x3: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x5: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x7: sprintf(r, "%s(%u,%u)", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4)); break;
        case 0x9: sprintf(r, "%s(%u,%u)", vName[4], bits(x,5,2) * 16, bits(x,7,1)*32+bits(x,3,4)); break;
        case 0xb: sprintf(r, "%s(%u,%u)", vName[4], bits(x,5,2) * 16, bits(x,7,1)*32+bits(x,3,4)); break;
        case 0xd: sprintf(r, "%s(%u,%u)", vName[5], bits(x,5,2) * 16, bits(x,3,4)); break;

        case 0xe:
        case 0xf: sprintf(r, "-");  f = 0; break;
    }
    if (f) sprintf(r, "%s+%s", r, regname[rs & 0x7]);
    
    return r;
}



- (char *) formattedValue:(uint32_t)value argIndex:(int)argIndex bitWidth:(int)width andPC:(Address)virtualAddress
{
    static char result[DISASM_MAX_OPERANDS][DISASM_MAX_USER_DATA];
    static char * alphabet = "0123456789abcdef";
    char formatString[DISASM_MAX_USER_DATA];
    char aux[256];
    NSString * name;

    uint32_t usedValue;
    ArgFormat Format;
    bool Signed;
    bool Negate;
    bool LeadingZeroes;	// for power of two bases only

    char * minusSign = "";
    char * tildeSign = "";
    char * baseString;

    int charWidth;
    int i,j;
    int base;
    int baseWidth;
    float f32;

    result[argIndex][0] = 0;    // empty string
    formatString[0] = 0;        // empty string

    Format = [_file formatForArgument:argIndex atVirtualAddress:virtualAddress];

    Negate = Format & Format_Negate;
    LeadingZeroes = Format & Format_LeadingZeroes;
    Signed = Format & Format_Signed;
    Format &= FORMAT_TYPE_MASK;

    usedValue = value;
    if (Negate)
    {
        tildeSign = "~";
        usedValue = ~usedValue;
        Signed = 0;
    }

    if (Signed && (usedValue & 0x80000000))
    {
        minusSign = "-";
        usedValue = -usedValue;
    }

    name = [_file nameForVirtualAddress:(Address)value];
    if (Format == Format_Default && name)
        Format = Format_Address;

    base = 0;
    baseWidth = 1;
    baseString = "";
    switch(Format)
    {
        case Format_Character:
            if (usedValue <= 0xff && isprint(usedValue))
            {
                sprintf(formatString, "%s%s'%%c'", tildeSign, minusSign);
                sprintf(result[argIndex], formatString, usedValue);
                break;
            }
            else if (usedValue <= 0xffff && isprint(usedValue & 0xff) && isprint((usedValue >> 8) & 0xff))
            {
                sprintf(formatString, "%s%s'%%c%%c'", tildeSign, minusSign);
                sprintf(result[argIndex], formatString, (usedValue >> 8) & 0xff, usedValue & 0xff);
                break;
            }
            else if (usedValue <= 0xffffff && isprint(usedValue & 0xff) && isprint((usedValue >> 8) & 0xff) && isprint((usedValue >> 16) & 0xff))
            {
                sprintf(formatString, "%s%s'%%c%%c%%c'", tildeSign, minusSign);
                sprintf(result[argIndex], formatString, (usedValue >> 16) & 0xff, (usedValue >> 8) & 0xff, usedValue & 0xff);
                break;
            }
            else if (isprint(usedValue & 0xff) && isprint((usedValue >> 8) & 0xff) && isprint((usedValue >> 16) & 0xff) && isprint((usedValue >> 24) & 0xff))
            {
                sprintf(formatString, "%s%s'%%c%%c%%c%%c'", tildeSign, minusSign);
                sprintf(result[argIndex], formatString, (usedValue >> 24) & 0xff, (usedValue >> 16) & 0xff, (usedValue >> 8) & 0xff, usedValue & 0xff);
                break;
            }
            // else flow through Format_Default
        default:
        case Format_Default:
        case Format_Hexadecimal:
            if (!base) { base = 16; baseWidth = 4; baseString = "0x"; }
        case Format_Decimal:
            if (!base) { base = 10; baseString = ""; }
        case Format_Octal:
            if (!base) { base =  8; baseWidth = 3; baseString = "0o"; }
        case Format_Binary:
            if (!base) { base =  2; baseWidth = 1; baseString = "0t"; }

            if (LeadingZeroes && base != 10)
                charWidth = (width + baseWidth - 1) / baseWidth;
            else
                charWidth = 1;

            i = 0;
            do
            {
                aux[i++] = alphabet[usedValue % base];
                usedValue /= base;
                if (charWidth) charWidth--;
            } while (charWidth || usedValue);
            aux[i] = 0;

            for (j = 0; j < i / 2; j++)
            {
                char tmp;
                tmp = aux[j];
                aux[j] = aux[i - j - 1];
                aux[i - j - 1] = tmp;
            }

            sprintf(formatString, "%s%s%s%%s", tildeSign, minusSign, baseString);
            sprintf(result[argIndex], formatString, aux);
            break;
        case Format_StackVariable:
            sprintf(result[argIndex], "var_%x", usedValue);
            break;
        case Format_Offset:
            break;
        case Format_Address:
            if (name)
                strncpy(result[argIndex], [name cStringUsingEncoding:NSUTF8StringEncoding], sizeof(result[argIndex]) - 1);
            else
                sprintf(result[argIndex], "0x%jx", (uintmax_t)value);
            break;
        case Format_Float:
            * (uint32_t *)(&f32) = value;
            sprintf(result[argIndex], "%g", f32);
            break;
    }

    return result[argIndex];
}



- (char *) formattedSigned:(int32_t)value argIndex:(int)argIndex bitWidth:(int)width andPC:(Address) virtualAddress
{
    static char result[DISASM_MAX_OPERANDS][DISASM_MAX_USER_DATA];
    static char * alphabet = "0123456789abcdef";
    char formatString[DISASM_MAX_USER_DATA];
    char aux[256];
    NSString * name;

    uint32_t usedValue;
    ArgFormat Format;
    bool Signed;
    bool Negate;
    bool LeadingZeroes;	// for power of two bases only

    char * minusSign = "";
    char * tildeSign = "";
    char * baseString;

    int charWidth;
    int i,j;
    int base;
    int baseWidth;
    float f32;

    result[argIndex][0] = 0;    // empty string
    formatString[0] = 0;        // empty string

    Format = [_file formatForArgument:argIndex atVirtualAddress:virtualAddress];

    Format |= Format_Signed;

    Negate = Format & Format_Negate;
    LeadingZeroes = Format & Format_LeadingZeroes;
    Signed = YES;
    Format &= FORMAT_TYPE_MASK;

    usedValue = value;
    if (Negate)
    {
        tildeSign = "~";
        usedValue = ~usedValue;
        Signed = 0;
    }

    if (Signed && (usedValue & 0x80000000))
    {
        minusSign = "-";
        usedValue = -usedValue;
    }

    name = [_file nameForVirtualAddress:(Address)value];
    if (Format == Format_Default && name)
        Format = Format_Address;

    base = 0;
    baseWidth = 1;
    baseString = "";
    switch(Format)
    {
        case Format_Character:
            if (isprint(usedValue))
            {
                sprintf(formatString, "%s%s'%%c'", tildeSign, minusSign);
                sprintf(result[argIndex], formatString, usedValue);
                break;
            }
            // else flow through Format_Default
        default:
        case Format_Default:
        case Format_Hexadecimal:
            if (!base) { base = 16; baseWidth = 4; baseString = "0x"; }
        case Format_Decimal:
            if (!base) { base = 10; baseString = ""; }
        case Format_Octal:
            if (!base) { base =  8; baseWidth = 3; baseString = "0o"; }
        case Format_Binary:
            if (!base) { base =  2; baseWidth = 1; baseString = "0t"; }

            if (LeadingZeroes && base != 10)
                charWidth = (width + baseWidth - 1) / baseWidth;
            else
                charWidth = 1;

            i = 0;
            do
            {
                aux[i++] = alphabet[usedValue % base];
                usedValue /= base;
                if (charWidth) charWidth--;
            } while (charWidth || usedValue);
            aux[i] = 0;

            for (j = 0; j < i / 2; j++)
            {
                char tmp;
                tmp = aux[j];
                aux[j] = aux[i - j - 1];
                aux[i - j - 1] = tmp;
            }

            sprintf(formatString, "%s%s%s%%s", tildeSign, minusSign, baseString);
            sprintf(result[argIndex], formatString, aux);
            break;
        case Format_StackVariable:
            sprintf(result[argIndex], "var_%x", usedValue);
            break;
        case Format_Address:
            name = [_file nameForVirtualAddress:(Address)value];
            if (name)
                strncpy(result[argIndex], [name cStringUsingEncoding:NSUTF8StringEncoding], sizeof(result[argIndex]) - 1);
            else
                sprintf(result[argIndex], "0x%jx", (uintmax_t)value);
            break;
        case Format_Float:
            * (uint32_t *)(&f32) = value;
            sprintf(result[argIndex], "%g", f32);
            break;
    }
    
    return result[argIndex];
}



- (char *) formattedValueWithSign:(int32_t)value argIndex:(int)argIndex bitWidth:(int)width andPC:(Address) virtualAddress
{
    static char result[DISASM_MAX_OPERANDS][DISASM_MAX_USER_DATA];
    static char * alphabet = "0123456789abcdef";
    char formatString[DISASM_MAX_USER_DATA];
    char aux[256];
    NSString * name;

    uint32_t usedValue;
    ArgFormat Format;
    bool Signed;
    bool Negate;
    bool LeadingZeroes;	// for power of two bases only

    char * minusSign = "+";
    char * tildeSign = "";
    char * baseString;

    int charWidth;
    int i,j;
    int base;
    int baseWidth;
    float f32;

    result[argIndex][0] = 0;    // empty string
    formatString[0] = 0;        // empty string

    Format = [_file formatForArgument:argIndex atVirtualAddress:virtualAddress];

    Format |= Format_Signed;

    Negate = Format & Format_Negate;
    LeadingZeroes = Format & Format_LeadingZeroes;
    Signed = YES;
    Format &= FORMAT_TYPE_MASK;

    usedValue = value;
    if (Signed && (usedValue & 0x80000000))
    {
        minusSign = "-";
        usedValue = -usedValue;
    }

    if (Negate)
    {
        tildeSign = "~";
        usedValue = ~usedValue;
        Signed = 0;
    }

    name = [_file nameForVirtualAddress:(Address)value];
    if (Format == Format_Default && name)
        Format = Format_Address;

    base = 0;
    baseWidth = 1;
    baseString = "";
    switch(Format)
    {
        case Format_Character:
            if (isprint(usedValue))
            {
                sprintf(formatString, "%s%s'%%c'", minusSign, tildeSign);
                sprintf(result[argIndex], formatString, usedValue);
                break;
            }
            // else flow through Format_Default
        default:
        case Format_Default:
        case Format_Hexadecimal:
            if (!base) { base = 16; baseWidth = 4; baseString = "0x"; }
        case Format_Decimal:
            if (!base) { base = 10; baseString = ""; }
        case Format_Octal:
            if (!base) { base =  8; baseWidth = 3; baseString = "0o"; }
        case Format_Binary:
            if (!base) { base =  2; baseWidth = 1; baseString = "0t"; }

            if (LeadingZeroes && base != 10)
                charWidth = (width + baseWidth - 1) / baseWidth;
            else
                charWidth = 1;

            i = 0;
            do
            {
                aux[i++] = alphabet[usedValue % base];
                usedValue /= base;
                if (charWidth) charWidth--;
            } while (charWidth || usedValue);
            aux[i] = 0;

            for (j = 0; j < i / 2; j++)
            {
                char tmp;
                tmp = aux[j];
                aux[j] = aux[i - j - 1];
                aux[i - j - 1] = tmp;
            }

            sprintf(formatString, "%s%s%s%%s", minusSign, tildeSign, baseString);
            sprintf(result[argIndex], formatString, aux);
            break;
        case Format_StackVariable:
            sprintf(result[argIndex], "var_%x", usedValue);
            break;
        case Format_Address:
            name = [_file nameForVirtualAddress:(Address)value];
            if (name)
                strncpy(result[argIndex], [name cStringUsingEncoding:NSUTF8StringEncoding], sizeof(result[argIndex]) - 1);
            else
                sprintf(result[argIndex], "0x%jx", (uintmax_t)value);
            break;
        case Format_Float:
            * (uint32_t *)(&f32) = value;
            sprintf(result[argIndex], "%g", f32);
            break;
    }
    
    return result[argIndex];
}



- (char *) formattedUnsigned:(uint32_t)value argIndex:(int)argIndex bitWidth:(int)width andPC:(Address) virtualAddress
{
    static char result[DISASM_MAX_OPERANDS][DISASM_MAX_USER_DATA];
    static char * alphabet = "0123456789abcdef";
    char formatString[DISASM_MAX_USER_DATA];
    char aux[256];
    NSString * name;

    uint32_t usedValue;
    ArgFormat Format;
    bool Signed;
    bool Negate;
    bool LeadingZeroes;	// for power of two bases only

    char * minusSign = "";
    char * tildeSign = "";
    char * baseString;

    int charWidth;
    int i,j;
    int base;
    int baseWidth;
    float f32;

    result[argIndex][0] = 0;    // empty string
    formatString[0] = 0;        // empty string

    Format = [_file formatForArgument:argIndex atVirtualAddress:virtualAddress];

    Format &= ~Format_Signed;

    Negate = Format & Format_Negate;
    LeadingZeroes = Format & Format_LeadingZeroes;
    Signed = NO;
    Format &= FORMAT_TYPE_MASK;

    usedValue = value;
    if (Negate)
    {
        tildeSign = "~";
        usedValue = ~usedValue;
        Signed = 0;
    }

    if (Signed && (usedValue & 0x80000000))
    {
        minusSign = "-";
        usedValue = -usedValue;
    }

    name = [_file nameForVirtualAddress:(Address)value];
    if (Format == Format_Default && name)
        Format = Format_Address;

    base = 0;
    baseWidth = 1;
    baseString = "";
    switch(Format)
    {
        case Format_Character:
            if (isprint(usedValue))
            {
                sprintf(formatString, "%s%s'%%c'", tildeSign, minusSign);
                sprintf(result[argIndex], formatString, usedValue);
                break;
            }
            // else flow through Format_Default
        default:
        case Format_Default:
        case Format_Hexadecimal:
            if (!base) { base = 16; baseWidth = 4; baseString = "0x"; }
        case Format_Decimal:
            if (!base) { base = 10; baseString = ""; }
        case Format_Octal:
            if (!base) { base =  8; baseWidth = 3; baseString = "0o"; }
        case Format_Binary:
            if (!base) { base =  2; baseWidth = 1; baseString = "0t"; }

            if (LeadingZeroes && base != 10)
                charWidth = (width + baseWidth - 1) / baseWidth;
            else
                charWidth = 1;

            i = 0;
            do
            {
                aux[i++] = alphabet[usedValue % base];
                usedValue /= base;
                if (charWidth) charWidth--;
            } while (charWidth || usedValue);
            aux[i] = 0;

            for (j = 0; j < i / 2; j++)
            {
                char tmp;
                tmp = aux[j];
                aux[j] = aux[i - j - 1];
                aux[i - j - 1] = tmp;
            }

            sprintf(formatString, "%s%s%s%%s", tildeSign, minusSign, baseString);
            sprintf(result[argIndex], formatString, aux);
            break;
        case Format_StackVariable:
            sprintf(result[argIndex], "var_%x", usedValue);
            break;
        case Format_Offset:
            break;
        case Format_Address:
            name = [_file nameForVirtualAddress:(Address)value];
            if (name)
                strncpy(result[argIndex], [name cStringUsingEncoding:NSUTF8StringEncoding], sizeof(result[argIndex]) - 1);
            else
                sprintf(result[argIndex], "0x%jx", (uintmax_t)value);
            break;
        case Format_Float:
            * (uint32_t *)(&f32) = value;
            sprintf(result[argIndex], "%g", f32);
            break;
    }
    
    return result[argIndex];
}



- (char *) formattedValue:(uint32_t)value defaultAsSigned:(BOOL)defaultSigned argIndex:(int)argIndex bitWidth:(int)width andPC:(Address)virtualAddress
{
    static char result[DISASM_MAX_OPERANDS][DISASM_MAX_USER_DATA];
    static char * alphabet = "0123456789abcdef";
    char formatString[DISASM_MAX_USER_DATA];
    char aux[256];
    NSString * name;

    uint32_t usedValue;
    ArgFormat Format;
    bool Signed;
    bool Negate;
    bool LeadingZeroes;	// for power of two bases only

    char * minusSign = "";
    char * tildeSign = "";
    char * baseString;

    int charWidth;
    int i,j;
    int base;
    int baseWidth;
    float f32;

    result[argIndex][0] = 0;    // empty string
    formatString[0] = 0;        // empty string

    Format = [_file formatForArgument:argIndex atVirtualAddress:virtualAddress];

    Negate = Format & Format_Negate;
    LeadingZeroes = Format & Format_LeadingZeroes;
    Signed = Format & Format_Signed;
    Format &= FORMAT_TYPE_MASK;

    if (Format == Format_Default)
        Signed = defaultSigned;

    usedValue = value;
    if (Negate)
    {
        tildeSign = "~";
        usedValue = ~usedValue;
        Signed = 0;
    }

    if (Signed && (usedValue & 0x80000000))
    {
        minusSign = "-";
        usedValue = -usedValue;
    }

    name = [_file nameForVirtualAddress:(Address)value];
    if (Format == Format_Default && name)
        Format = Format_Address;

    base = 0;
    baseWidth = 1;
    baseString = "";
    switch(Format)
    {
        case Format_Character:
            if (usedValue <= 0xff && isprint(usedValue))
            {
                sprintf(formatString, "%s%s'%%c'", tildeSign, minusSign);
                sprintf(result[argIndex], formatString, usedValue);
                break;
            }
            else if (usedValue <= 0xffff && isprint(usedValue & 0xff) && isprint((usedValue >> 8) & 0xff))
            {
                sprintf(formatString, "%s%s'%%c%%c'", tildeSign, minusSign);
                sprintf(result[argIndex], formatString, (usedValue >> 8) & 0xff, usedValue & 0xff);
                break;
            }
            else if (usedValue <= 0xffffff && isprint(usedValue & 0xff) && isprint((usedValue >> 8) & 0xff) && isprint((usedValue >> 16) & 0xff))
            {
                sprintf(formatString, "%s%s'%%c%%c%%c'", tildeSign, minusSign);
                sprintf(result[argIndex], formatString, (usedValue >> 16) & 0xff, (usedValue >> 8) & 0xff, usedValue & 0xff);
                break;
            }
            else if (isprint(usedValue & 0xff) && isprint((usedValue >> 8) & 0xff) && isprint((usedValue >> 16) & 0xff) && isprint((usedValue >> 24) & 0xff))
            {
                sprintf(formatString, "%s%s'%%c%%c%%c%%c'", tildeSign, minusSign);
                sprintf(result[argIndex], formatString, (usedValue >> 24) & 0xff, (usedValue >> 16) & 0xff, (usedValue >> 8) & 0xff, usedValue & 0xff);
                break;
            }
            // else flow through Format_Default
        default:
        case Format_Default:
        case Format_Hexadecimal:
            if (!base) { base = 16; baseWidth = 4; baseString = "0x"; }
        case Format_Decimal:
            if (!base) { base = 10; baseString = ""; }
        case Format_Octal:
            if (!base) { base =  8; baseWidth = 3; baseString = "0o"; }
        case Format_Binary:
            if (!base) { base =  2; baseWidth = 1; baseString = "0t"; }

            if (LeadingZeroes && base != 10)
                charWidth = (width + baseWidth - 1) / baseWidth;
            else
                charWidth = 1;

            i = 0;
            do
            {
                aux[i++] = alphabet[usedValue % base];
                usedValue /= base;
                if (charWidth) charWidth--;
            } while (charWidth || usedValue);
            aux[i] = 0;

            for (j = 0; j < i / 2; j++)
            {
                char tmp;
                tmp = aux[j];
                aux[j] = aux[i - j - 1];
                aux[i - j - 1] = tmp;
            }

            sprintf(formatString, "%s%s%s%%s", tildeSign, minusSign, baseString);
            sprintf(result[argIndex], formatString, aux);
            break;
        case Format_StackVariable:
            sprintf(result[argIndex], "var_%x", usedValue);
            break;
        case Format_Offset:
            break;
        case Format_Address:
            name = [_file nameForVirtualAddress:(Address)value];
            if (name)
                strncpy(result[argIndex], [name cStringUsingEncoding:NSUTF8StringEncoding], sizeof(result[argIndex]) - 1);
            else
                sprintf(result[argIndex], "0x%jx", (uintmax_t)value);
            break;
        case Format_Float:
            * (uint32_t *)(&f32) = value;
            sprintf(result[argIndex], "%g", f32);
            break;
    }
    
    return result[argIndex];
}



- (char *) formattedAddress:(uint32_t)value argIndex:(int)argIndex andPC:(Address)virtualAddress
{
    static char result[DISASM_MAX_OPERANDS][DISASM_MAX_USER_DATA];
    static char * alphabet = "0123456789abcdef";
    char formatString[DISASM_MAX_USER_DATA];
    char aux[256];
    NSString * name;

    uint32_t usedValue;
    ArgFormat Format;
    bool Signed;
    bool Negate;
    bool LeadingZeroes;	// for power of two bases only

    char * minusSign = "";
    char * tildeSign = "";
    char * baseString;

    int charWidth;
    int i,j;
    int base;
    int baseWidth;

    result[argIndex][0] = 0;    // empty string
    formatString[0] = 0;        // empty string

    Format = [_file formatForArgument:argIndex atVirtualAddress:virtualAddress];

    if ((Format & FORMAT_TYPE_MASK) == Format_Default)
        Format = Format_Address | Format_LeadingZeroes;

    Negate = Format & Format_Negate;
    LeadingZeroes = Format & Format_LeadingZeroes;
    Signed = Format & Format_Signed;
    Format &= FORMAT_TYPE_MASK;

    usedValue = value;
    if (Negate)
    {
        tildeSign = "~";
        usedValue = ~usedValue;
        Signed = 0;
    }

    if (Signed && (usedValue & (1 << 31)))
    {
        minusSign = "-";
        usedValue = -usedValue;
    }

    name = [_file nameForVirtualAddress:(Address)value];
    if (Format == Format_Default && name)
        Format = Format_Address;

    base = 0;
    baseWidth = 1;
    baseString = "";
    switch(Format)
    {
        default:
        case Format_Default:
        case Format_Address:
            name = [_file nameForVirtualAddress:(Address)value];
            if (name)
            {
                strncpy(result[argIndex], [name cStringUsingEncoding:NSUTF8StringEncoding], sizeof(result[argIndex]) - 1);
                break;
            }
        case Format_Hexadecimal:
            if (!base) { base = 16; baseWidth = 4; baseString = "0x"; }
        case Format_Decimal:
            if (!base) { base = 10; baseString = ""; }
        case Format_Octal:
            if (!base) { base =  8; baseWidth = 3; baseString = "0o"; }
        case Format_Binary:
            if (!base) { base =  2; baseWidth = 1; baseString = "0t"; }

            if (LeadingZeroes && (base != 10))
                charWidth = (32 + baseWidth - 1) / baseWidth;
            else
                charWidth = 1;

            i = 0;
            do
            {
                aux[i++] = alphabet[usedValue % base];
                usedValue /= base;
                if (charWidth) charWidth--;
            } while (charWidth || usedValue);
            aux[i] = 0;

            for (j = 0; j < i / 2; j++)
            {
                char tmp;
                tmp = aux[j];
                aux[j] = aux[i - j - 1];
                aux[i - j - 1] = tmp;
            }

            sprintf(formatString, "%s%s%s%%s", tildeSign, minusSign, baseString);
            sprintf(result[argIndex], formatString, aux);
            break;
    }
    
    return result[argIndex];
}



- (char *) formattedFloat:(int32_t)value argIndex:(int)argIndex bitWidth:(int)width andPC:(Address) virtualAddress
{
    static char result[DISASM_MAX_OPERANDS][DISASM_MAX_USER_DATA];
    static char * alphabet = "0123456789abcdef";
    char formatString[DISASM_MAX_USER_DATA];
    char aux[256];
    NSString * name;

    uint32_t usedValue;
    ArgFormat Format;
    bool Signed;
    bool Negate;
    bool LeadingZeroes;	// for power of two bases only

    char * minusSign = "";
    char * tildeSign = "";
    char * baseString;

    int charWidth;
    int i,j;
    int base;
    int baseWidth;
    float f32;

    result[argIndex][0] = 0;    // empty string
    formatString[0] = 0;        // empty string

    Format = [_file formatForArgument:argIndex atVirtualAddress:virtualAddress];

    if ((Format & FORMAT_TYPE_MASK) == Format_Default)
        Format = Format_Float;

    Negate = Format & Format_Negate;
    LeadingZeroes = Format & Format_LeadingZeroes;
    Signed = Format & Format_Signed;
    Format &= FORMAT_TYPE_MASK;

    usedValue = value;
    if (Negate)
    {
        tildeSign = "~";
        usedValue = ~usedValue;
        Signed = 0;
    }

    if (Signed && (usedValue & 0x80000000))
    {
        minusSign = "-";
        usedValue = -usedValue;
    }

    base = 0;
    baseWidth = 1;
    baseString = "";

    switch(Format)
    {
        case Format_Character:
            if (isprint(usedValue))
            {
                sprintf(formatString, "%s%s'%%c'", tildeSign, minusSign);
                sprintf(result[argIndex], formatString, usedValue);
                break;
            }
            // else flow through Format_Default
        case Format_Hexadecimal:
            if (!base) { base = 16; baseWidth = 4; baseString = "0x"; }
        case Format_Decimal:
            if (!base) { base = 10; baseString = ""; }
        case Format_Octal:
            if (!base) { base =  8; baseWidth = 3; baseString = "0o"; }
        case Format_Binary:
            if (!base) { base =  2; baseWidth = 1; baseString = "0t"; }

            if (LeadingZeroes && base != 10)
                charWidth = (width + baseWidth - 1) / baseWidth;
            else
                charWidth = 1;

            i = 0;
            do
            {
                aux[i++] = alphabet[usedValue % base];
                usedValue /= base;
                if (charWidth) charWidth--;
            } while (charWidth || usedValue);
            aux[i] = 0;

            for (j = 0; j < i / 2; j++)
            {
                char tmp;
                tmp = aux[j];
                aux[j] = aux[i - j - 1];
                aux[i - j - 1] = tmp;
            }

            sprintf(formatString, "%s%s%s%%s", tildeSign, minusSign, baseString);
            sprintf(result[argIndex], formatString, aux);
            break;
        case Format_StackVariable:
            sprintf(result[argIndex], "var_%x", usedValue);
            break;
        case Format_Address:
            name = [_file nameForVirtualAddress:(Address)value];
            if (name)
                strncpy(result[argIndex], [name cStringUsingEncoding:NSUTF8StringEncoding], sizeof(result[argIndex]) - 1);
            else
                sprintf(result[argIndex], "0x%jx", (uintmax_t)value);
            break;
        default:
        case Format_Default:
        case Format_Float:
            * (uint32_t *)(&f32) = value;
            sprintf(result[argIndex], "%g", f32);
            break;
    }
    
    return result[argIndex];
}



char * vRa80(int x, int f, int h, VC4Context * context, int arg, Address pc)
{
    static char r[64];
    int reg = bits(f, 5, 4);
    int inc = bits(f, 1, 1);
    int cb  = bits(f, 0, 1);
    char * incr = inc ? "++" : "";
    char * usecb = cb ? "*" : "";

    switch(bits(x,9,4))
    {
        case 0x0: sprintf(r, "%s(%u%s,%u)%s", vName[0], bits(x,5,6), incr, h, usecb);      break;
        case 0x2: sprintf(r, "%s(%u%s,%u)%s", vName[0], bits(x,5,6), incr, h + 16, usecb); break;
        case 0x4: sprintf(r, "%s(%u%s,%u)%s", vName[0], bits(x,5,6), incr, h + 32, usecb); break;
        case 0x6: sprintf(r, "%s(%u%s,%u)%s", vName[0], bits(x,5,6), incr, h + 48, usecb); break;
        case 0x8: sprintf(r, "%s(%u%s,%u)%s", vName[1], bits(x,5,6), incr, h, usecb);      break;
        case 0xa: sprintf(r, "%s(%u%s,%u)%s", vName[1], bits(x,5,6), incr, h + 32, usecb); break;
        case 0xc: sprintf(r, "%s(%u%s,%u)%s", vName[2], bits(x,5,6), incr, h, usecb);      break;

        case 0x1: sprintf(r, "%s(%u%s,%u)%s", vName[3], bits(x,5,6), incr, h, usecb);      break;
        case 0x3: sprintf(r, "%s(%u%s,%u)%s", vName[3], bits(x,5,6), incr, h + 16, usecb); break;
        case 0x5: sprintf(r, "%s(%u%s,%u)%s", vName[3], bits(x,5,6), incr, h + 32, usecb); break;
        case 0x7: sprintf(r, "%s(%u%s,%u)%s", vName[3], bits(x,5,6), incr, h + 48, usecb); break;
        case 0x9: sprintf(r, "%s(%u%s,%u)%s", vName[4], bits(x,5,6), incr, h, usecb);      break;
        case 0xb: sprintf(r, "%s(%u%s,%u)%s", vName[4], bits(x,5,6), incr, h + 32, usecb); break;
        case 0xd: sprintf(r, "%s(%u%s,%u)%s", vName[5], bits(x,5,6), incr, h, usecb);      break;

        case 0xe:
        case 0xf: sprintf(r, "%s", [context formattedValue:0 argIndex:arg bitWidth:32 andPC:pc]); break; break;
    }
    if (reg != 15 && bits(x,9,4) < 0xe) sprintf(r, "%s+%s", r, regname[reg]);

    return r;
}



char * vRb80(int x, int f, VC4Context * context, int arg, Address pc)
{
    static char r[64];
    int reg = bits(f, 5, 4);
    int inc = bits(f, 1, 1);
    int cb  = bits(f, 0, 1);
    int imm = bits(x, 6, 7);
    char * incr = inc ? "++" : "";
    char * usecb = cb ? "*" : "";

    switch(bits(x,9,4))
    {
        case 0x0: sprintf(r, "%s(%u%s,0)%s",  vName[0], bits(x,5,6), incr, usecb); break;
        case 0x2: sprintf(r, "%s(%u%s,16)%s", vName[0], bits(x,5,6), incr, usecb); break;
        case 0x4: sprintf(r, "%s(%u%s,32)%s", vName[0], bits(x,5,6), incr, usecb); break;
        case 0x6: sprintf(r, "%s(%u%s,48)%s", vName[0], bits(x,5,6), incr, usecb); break;
        case 0x8: sprintf(r, "%s(%u%s,0)%s",  vName[1], bits(x,5,6), incr, usecb); break;
        case 0xa: sprintf(r, "%s(%u%s,32)%s", vName[1], bits(x,5,6), incr, usecb); break;
        case 0xc: sprintf(r, "%s(%u%s,0)%s",  vName[2], bits(x,5,6), incr, usecb); break;

        case 0x1: sprintf(r, "%s(%u,%u%s)%s", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4), incr, usecb); break;
        case 0x3: sprintf(r, "%s(%u,%u%s)%s", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4), incr, usecb); break;
        case 0x5: sprintf(r, "%s(%u,%u%s)%s", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4), incr, usecb); break;
        case 0x7: sprintf(r, "%s(%u,%u%s)%s", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4), incr, usecb); break;
        case 0x9: sprintf(r, "%s(%u,%u%s)%s", vName[4], bits(x,5,2) * 16, bits(x,7,1)*32+bits(x,3,4), incr, usecb); break;
        case 0xb: sprintf(r, "%s(%u,%u%s)%s", vName[4], bits(x,5,2) * 16, bits(x,7,1)*32+bits(x,3,4), incr, usecb); break;
        case 0xd: sprintf(r, "%s(%u,%u%s)%s", vName[5], bits(x,5,2) * 16, bits(x,3, 4),     incr, usecb); break;

        case 0xe:
        case 0xf:
            if (reg != 15)
            {
                imm = msbextendedbits((bits(f,1,2)<<7) | imm,8,9);
                if (imm)
                    sprintf(r, "%s%s", regname[reg],
                            [context formattedValueWithSign:(uint32_t)imm argIndex:arg bitWidth:9 andPC:pc]);
                else
                    sprintf(r, "%s", regname[reg]);
                reg = 15; // avoid future indexing handling
            }
            else
            {
                imm = msbextendedbits((bits(f,1,2)<<7) | imm,8,9);
                sprintf(r, "%s",
                        [context formattedValue:(uint32_t)imm argIndex:arg bitWidth:32 andPC:pc]);
                reg = 15; // avoid future indexing handling
            }
            break;
    }
    if (reg != 15) sprintf(r, "%s+%s", r, regname[reg]);

    return r;
}



char * vRd80(int x, int f)
{
    static char r[64];
    int reg = bits(f, 5, 4);
    int inc = bits(f, 1, 1);
    int cb  = bits(f, 0, 1);
    char * incr = inc ? "++" : "";
    char * usecb = cb ? "*" : "";

    switch(bits(x,9,4))
    {
        case 0x0: sprintf(r, "%s(%u%s,0)%s",  vName[0], bits(x,5,6), incr, usecb); break;
        case 0x2: sprintf(r, "%s(%u%s,16)%s", vName[0], bits(x,5,6), incr, usecb); break;
        case 0x4: sprintf(r, "%s(%u%s,32)%s", vName[0], bits(x,5,6), incr, usecb); break;
        case 0x6: sprintf(r, "%s(%u%s,48)%s", vName[0], bits(x,5,6), incr, usecb); break;
        case 0x8: sprintf(r, "%s(%u%s,0)%s",  vName[1], bits(x,5,6), incr, usecb); break;
        case 0xa: sprintf(r, "%s(%u%s,32)%s", vName[1], bits(x,5,6), incr, usecb); break;
        case 0xc: sprintf(r, "%s(%u%s,0)%s",  vName[2], bits(x,5,6), incr, usecb); break;

        case 0x1: sprintf(r, "%s(%u,%u%s)%s", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4), incr, usecb); break;
        case 0x3: sprintf(r, "%s(%u,%u%s)%s", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4), incr, usecb); break;
        case 0x5: sprintf(r, "%s(%u,%u%s)%s", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4), incr, usecb); break;
        case 0x7: sprintf(r, "%s(%u,%u%s)%s", vName[3], bits(x,5,2) * 16, bits2(x,8,2,3,4), incr, usecb); break;
        case 0x9: sprintf(r, "%s(%u,%u%s)%s", vName[4], bits(x,5,2) * 16, bits(x,7,1)*32+bits(x,3,4), incr, usecb); break;
        case 0xb: sprintf(r, "%s(%u,%u%s)%s", vName[4], bits(x,5,2) * 16, bits(x,7,1)*32+bits(x,3,4), incr, usecb); break;
        case 0xd: sprintf(r, "%s(%u,%u%s)%s", vName[5], bits(x,5,2) * 16, bits(x,3, 4),     incr, usecb); break;

        case 0xe:
        case 0xf: sprintf(r, "-"); break;
    }
    if (reg != 15 && (bits(x,9,4) < 0xe)) sprintf(r, "%s+%s", r, regname[reg]);
    
    return r;
}

@end
