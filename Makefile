.SUFFIXES:

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

TOPDIR ?= $(CURDIR)

PORTLIBS	:=	$(DEVKITPRO)/portlibs/3ds
CTRULIB	?=	$(DEVKITPRO)/libctru
export PATH := $(DEVKITPRO)/portlibs/3ds/bin:$(PATH)
include $(DEVKITPRO)/devkitARM//base_rules

export VERSTRING	:=	$(shell git describe --tags --match "v[0-9]*" --abbrev=7 | sed 's/-[0-9]*-g/-/')

BUILD		:=	build
SOURCES		:=	source source/ui source/parsing source/loaders

ARCH	:=	-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft

CFLAGS	:=	-g -Wall -O2 -mword-relocations \
			-fno-math-errno -ffunction-sections \
			$(ARCH)

export INCLUDE	:=	$(foreach dir,$(SOURCES),-I$(CURDIR)/$(dir)) \
			$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
			-I$(CURDIR)/$(BUILD)

CFLAGS	+=	$(INCLUDE) -D__3DS__ -DVERSION=\"$(VERSTRING)\"

CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11

ASFLAGS	:=	-g $(ARCH)

LIBS	:= -lconfig -lcitro3d -lctru -lm -lz -ltinyxml2

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:= $(PORTLIBS) $(CTRULIB)


#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir))

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
PICAFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.v.pica)))
SHLISTFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.shlist)))

export LD	:=	$(CC)

#---------------------------------------------------------------------------------

export OFILES_SOURCES 	:=	$(CFILES:.c=.o) $(SFILES:.s=.o)

export OFILES_BIN	:= $(PICAFILES:.v.pica=.shbin.o) $(SHLISTFILES:.shlist=.shbin.o)

export OFILES := $(OFILES_BIN) $(OFILES_SOURCES)

export HFILES	:=	$(PICAFILES:.v.pica=_shbin.h) $(SHLISTFILES:.shlist=_shbin.h)

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
			$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
			-I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

.PHONY: all

#---------------------------------------------------------------------------------
all: $(BUILD)
	@$(MAKE) -C $(BUILD) -f $(CURDIR)/Makefile

$(BUILD):
	@mkdir -p $@
	
#---------------------------------------------------------------------------------
else

.PRECIOUS	:	%.shbin
%.shbin.o %_shbin.h : %.shbin
	$(SILENTMSG) $(notdir $<)
	$(bin2o)

DEPENDS	:=	$(OFILES:.o=.d)

$(OUTPUT).3gx	:	$(OUTPUT).elf

$(OFILES_SOURCES) : $(HFILES)

$(OUTPUT).elf	:	$(OFILES)
	$(SILENTMSG) linking $(notdir $@)
	$(ADD_COMPILE_COMMAND) end
	$(LD) -T $(TOPDIR)/3gx.ld -g $(ARCH) -Wl,-Map,$(notdir $*.map) \
		$(OFILES) $(LIBPATHS) $(LIBS) -o $@
	$(NM) -CSn $@ > $(notdir $*.lst)

%.3gx: %.elf
	@echo creating $(notdir $@)
	@3gxtool -s $^ 3gxLauncher.plgInfo $(OUTPUT).3gx

-include $(DEPENDS)
