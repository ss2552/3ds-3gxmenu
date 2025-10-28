.SUFFIXES:

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

include $(DEVKITARM)/3ds_rules

TOPDIR 		?= 	$(CURDIR)
TARGET		:= 	$(notdir $(CURDIR))
PLGINFO 	:= 	3gxlauncher.plgInfo
SOURCES 	:= 	source source/ui source/parsing source/loaders
INCLUDES	:= 	$(SOURCES)
ARCH		:=	-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft
CFLAGS		:=	$(ARCH) -Os -mword-relocations -fomit-frame-pointer -ffunction-sections -fno-strict-aliasing
CFLAGS		+=	$(INCLUDE) -D__3DS__
ASFLAGS		:=	$(ARCH)
LDFLAGS		:= -T $(TOPDIR)/3gx.ld $(ARCH) -Os -Wl,--gc-sections,--strip-discarded,--strip-debug
export LD			:=	$(CC)

LIBS		:= -lctru
LIBDIRS		:= 	$(CTRULIB) $(PORTLIBS)

CFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
SFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

OFILES	:=	$(CFILES:.c=.o) $(SFILES:.s=.o)
INCLUDE	:=	$(foreach dir,$(INCLUDES),-I $(CURDIR)/$(dir) ) $(foreach dir,$(LIBDIRS),-I $(dir)/include) -I $(CURDIR)

LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L $(dir)/lib)

.PHONY: default.3gx

default.3gx : $(OFILES)
	@[ -d $@ ] || mkdir -p $@

.PRECIOUS: %.elf
%.3gx: %.elf
	@echo creating $(notdir $@)
	@3gxtool -s $(word 1, $^) $(TOPDIR)/$(PLGINFO) $@
