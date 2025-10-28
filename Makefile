.SUFFIXES:

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

TOPDIR 		:= $(CURDIR)
TARGET		:= $(notdir $(TOPDIR))
PLGINFO 	:= 3gxlauncher.plgInfo
BUILD		:= build

include $(DEVKITARM)/3ds_rules

INCLUDES	:= include source/ui source/parsing source/loaders $(BUILD)
SOURCES 	:= source source/ui source/parsing source/loaders
LIBDIRS		:= $(CTRULIB) $(PORTLIBS)

ARCH		:= -march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft

CFLAGS		:= $(ARCH) -Os -mword-relocations \
				-fomit-frame-pointer -ffunction-sections -fno-strict-aliasing

export INCLUDE	:= $(foreach dir,$(INCLUDES),-I $(TOPDIR)/$(dir)) \
					$(foreach dir,$(LIBDIRS),-I $(dir)/include) \
					-I /opt/devkitpro/libctru/include
CFLAGS		+= $(INCLUDE) -D__3DS__ -DVERSION=\"$(VERSTRING)\"

ASFLAGS		:= $(ARCH)

export LIBPATHS	:= $(foreach dir,$(LIBDIRS),-L $(dir)/lib) \
					-L /opt/devkitpro/libctru/lib

export LDFLAGS	:= -T $(TOPDIR)/3gx.ld $(ARCH) -Os \
					-Wl,--gc-sections,--strip-discarded,--strip-debug

export LIBS		:= -lconfig -lcitro3d -lctru -lm -lz -ltinyxml2

export OUTPUT	:= $(TOPDIR)/$(TARGET)
export VPATH	:= $(foreach dir,$(SOURCES),$(TOPDIR)/$(dir)) \
					$(foreach dir,$(DATA),$(TOPDIR)/$(dir))

export DEPSDIR	:= $(TOPDIR)/$(BUILD)

CFILES		:= $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
SFILES		:= $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

export OFILES	:= $(CFILES:.c=.o) $(SFILES:.s=.o)

export LD 		:= $(CXX)

.PHONY: $(OUTPUT).3gx

$(OUTPUT).3gx : $(OFILES)

.PRECIOUS: %.elf
%.3gx: %.elf
	@echo creating $(notdir $@)
	@3gxtool -s $(word 1, $^) $(TOPDIR)/$(PLGINFO) $@
