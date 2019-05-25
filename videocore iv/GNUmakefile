include $(GNUSTEP_MAKEFILES)/common.make

HOPPER_INCLUDE_PATH=../external/Hopper/include

COMMON_OBJC_FLAGS = -I$(HOPPER_INCLUDE_PATH) -DLINUX -Wno-format -fblocks -fobjc-nonfragile-abi -fobjc-arc

BUNDLE_NAME = VC4CPU

VC4CPU_OBJC_FILES = VC4Definition.m VC4Context.m VC4Disassembly.m

VC4CPU_CFLAGS = 
VC4CPU_OBJCFLAGS = $(COMMON_OBJC_FLAGS)

include $(GNUSTEP_MAKEFILES)/bundle.make
