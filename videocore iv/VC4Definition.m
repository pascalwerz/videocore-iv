//
//  VC4Definition.m
//  videocore iv
//
//  Created by Pascal Werz on 05/02/2016.
//  Copyright © 2016 Pascal Werz. All rights reserved.
//

#import "VC4Definition.h"

@implementation VC4Definition

- (Class)cpuContextClass
{
    return [VC4Context class];
}

+ (int)sdkVersion {
	return HOPPER_CURRENT_SDK_VERSION;
}

- (NSObject<CPUContext> *)buildCPUContextForFile:(NSObject<HPDisassembledFile> *)file
{
    return [[VC4Context alloc] initWithCPU:self andFile:file];
}



- (NSArray *)cpuFamilies
{
    return @[@"VideoCore IV"];
}

- (NSString *)commandLineIdentifier {
	return @"VC4";
}

- (NSArray *)cpuSubFamiliesForFamily:(NSString *)family
{
    if ([family isEqualToString:@"VideoCore IV"]) return @[@"VideoCore IV VPU"];
    return nil;
}



- (int)addressSpaceWidthInBitsForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily
{
    if ([family isEqualToString:@"VideoCore IV"] && [subFamily isEqualToString:@"VideoCore IV VPU"]) return 32;
    return 0;
}



- (HopperPluginType)pluginType
{
    return Plugin_CPU;
}



- (HopperUUID *)pluginUUID
{
    return [_services UUIDWithString:@"cd77fa0d-3661-4caa-9959-1b49f6a32326"];
}



- (NSString *)pluginName
{
    return @"VideoCore";
}



- (NSString *)pluginDescription
{
    return @"Broadcom VideoCore IV support";
}



- (NSString *)pluginAuthor
{
    return @"Pascal Werz";
}



- (NSString *)pluginCopyright
{
    return @"© Pascal Werz, released under GPL.";
}



- (NSString *)pluginVersion
{
    return @"0.1.0";
}



- (NSUInteger)syntaxVariantCount
{
    return 1;
}



- (NSUInteger)cpuModeCount
{
    return 1;
}



- (NSArray *)syntaxVariantNames
{
    return @[@"generic"];
}



- (NSArray *)cpuModeNames
{
    return @[@"generic"];
}



- (CPUEndianess)endianess
{
    return CPUEndianess_Little;
}



- (NSUInteger)registerClassCount {
    return RegClass_FirstUserClass;
}



- (NSUInteger)registerCountForClass:(RegClass)reg_class
{
    switch (reg_class)
    {
        case RegClass_GeneralPurposeRegister: return 32;
        case RegClass_CPUState: return 0;
        case RegClass_PseudoRegisterSTACK: return 0;
        default: return 0;
    }
}



- (BOOL)registerIndexIsStackPointer:(NSUInteger)reg ofClass:(RegClass)reg_class cpuMode:(uint8_t)cpuMode file:(NSObject<HPDisassembledFile> *)file
{
    return reg_class == RegClass_GeneralPurposeRegister && reg == 25;
}



- (BOOL)registerIndexIsFrameBasePointer:(NSUInteger)reg ofClass:(RegClass)reg_class cpuMode:(uint8_t)cpuMode file:(NSObject<HPDisassembledFile> *)file
{
    return NO;
}



- (BOOL)registerIndexIsProgramCounter:(NSUInteger)reg cpuMode:(uint8_t)cpuMode file:(NSObject<HPDisassembledFile> *)file
{
    return reg == 31;
}



- (BOOL)registerHasSideEffectForIndex:(NSUInteger)reg andClass:(RegClass)reg_class
{
    return NO;
}



- (NSString *)framePointerRegisterNameForFile:(NSObject<HPDisassembledFile> *)file cpuMode:(uint8_t)cpuMode {
    return nil;
}



- (NSString *)registerIndexToString:(NSUInteger)reg ofClass:(RegClass)reg_class withBitSize:(NSUInteger)size position:(DisasmPosition)position andSyntaxIndex:(NSUInteger)syntaxIndex
{
    switch (reg_class)
    {
    case RegClass_GeneralPurposeRegister:
        return [NSString stringWithCString:regname[reg] encoding:NSUTF8StringEncoding];
    default: return [NSString stringWithFormat:@"reg%ju_OfClass_%ju", (uintmax_t)reg, (uintmax_t) reg_class]; // ???
    }
}



- (NSString *)cpuRegisterStateMaskToString:(uint32_t)cpuState {
    return @"";
}



- (NSUInteger)translateOperandIndex:(NSUInteger)index operandCount:(NSUInteger)count accordingToSyntax:(uint8_t)syntaxIndex {
    return index;
}



- (NSData *)nopWithSize:(NSUInteger)size andMode:(NSUInteger)cpuMode forFile:(NSObject<HPDisassembledFile> *)file
{
    if (size & 1) return nil;
    NSMutableData *nopArray = [[NSMutableData alloc] initWithCapacity:size];
    [nopArray setLength:size];
    uint16_t *ptr = (uint16_t *)[nopArray mutableBytes];
    for (NSUInteger i = 0; i < size; i += 2)
        OSWriteBigInt16(ptr, i, 0x0001);    // nop instruction

    return [NSData dataWithData:nopArray];
}



- (BOOL)canAssembleInstructionsForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily
{
    return NO;
}




- (BOOL)canDecompileProceduresForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily
{
    return NO;
}



- (instancetype)initWithHopperServices:(NSObject<HPHopperServices> *)services
{
    if (self = [super init])
    {
        _services = services;
        NSInteger major = [_services hopperMajorVersion];
        NSInteger minor = [_services hopperMinorVersion];
        NSInteger revision = [_services hopperRevision];
        uint64_t combined = (uint64_t) major * 1000000 + (uint64_t) minor * 1000 + (uint64_t) revision;
        // ensure Hopper version is at least 4.2.19 and up

        if (combined < 4002019)
        {
            self = nil;
            NSLog(@"videocore-iv plugin:Hopper version too old.");
        }
    }

    return self;
}

@end
