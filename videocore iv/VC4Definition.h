//
//  VC4Definition.h
//  videocore iv
//
//  Created by Pascal Werz on 05/02/2016.
//  Copyright © 2016 Pascal Werz. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Hopper/Hopper.h>

#import "VC4Context.h"


typedef NS_ENUM(NSUInteger, VC4RegClass) {
    RegClass_ControlRegister = RegClass_FirstUserClass
};

enum
{
    REG_R0  =  0,
    REG_R1  =  1,
    REG_R2  =  2,
    REG_R3  =  3,
    REG_R4  =  4,
    REG_R5  =  5,
    REG_R6  =  6,
    REG_R7  =  7,
    REG_R8  =  8,
    REG_R9  =  9,
    REG_R10 = 10,
    REG_R11 = 11,
    REG_R12 = 12,
    REG_R13 = 13,
    REG_R14 = 14,
    REG_R15 = 15,
    REG_R16 = 16,
    REG_R17 = 17,
    REG_R18 = 18,
    REG_R19 = 19,
    REG_R20 = 20,
    REG_R21 = 21,
    REG_R22 = 22,
    REG_R23 = 23,
    REG_GP  = 24,
    REG_SP  = 25,
    REG_LR  = 26,
    REG_R27 = 27,
    REG_ESP = 28,
    REG_TP  = 29,
    REG_SR  = 30,
    REG_PC  = 31,
};

extern char *regname[32];
extern char *vName[6];

@interface VC4Definition : NSObject<CPUDefinition>
{
@public
    NSObject<HPHopperServices> * _services;
}

@end
