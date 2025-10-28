.SUFFIXES:

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

TOPDIR 		:= 	$(CURDIR)
include $(DEVKITARM)/3ds_rules

TARGET		:= 	$(notdir $(CURDIR))
PLGINFO 	:= 	3gxlauncher.plgInfo

BUILD		:= 	build
INCLUDES	:= 	include source/ui source/parsing source/loaders $(BUILD)
SOURCES 	:= 	source source/ui source/parsing source/loaders

ARCH		:=	-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft

CFLAGS		:=	$(ARCH) -Os -mword-relocations \
				-fomit-frame-pointer -ffunction-sections -fno-strict-aliasing

CFLAGS		+=	$(INCLUDE) -D__3DS__

ASFLAGS		:=	$(ARCH)
export LDFLAGS		:= -T $(TOPDIR)/3gx.ld $(ARCH) -Os -Wl,--gc-sections,--strip-discarded,--strip-debug

export LIBS		:=  -lconfig -lcitro3d -lctru -lm -lz -ltinyxml2
LIBDIRS		:= 	$(CTRULIB) $(PORTLIBS)

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) $(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
SFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

export LD 		:= 	$(CXX)
export OFILES	:=	$(CFILES:.c=.o) $(SFILES:.s=.o)
export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I $(CURDIR)/$(dir) ) $(foreach dir,$(LIBDIRS),-I $(dir)/include) -I /opt/devkitpro/libctru/include

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L $(dir)/lib) -I /opt/devkitpro/libctru/lib

.PHONY: $(OUTPUT).3gx $(DEPSDIR)

$(OUTPUT).3gx : $(OFILES)

.PRECIOUS: %.elf
%.3gx: %.elf
	@echo creating $(notdir $@)
	@3gxtool -s $(word 1, $^) $(TOPDIR)/$(PLGINFO) $@
