#---------------------------------------------------------------------------------
# Clear the implicit built in rules
#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------
ifeq ($(strip $(DEVKITPPC)),)
$(error "Please set DEVKITPPC in your environment. export DEVKITPPC=<path to>devkitPPC")
endif

include $(DEVKITPPC)/wii_rules

LVGL_PATH 		:= 		$(CURDIR)/src/lvgl

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# INCLUDES is a list of directories containing extra header files
#---------------------------------------------------------------------------------
TARGET          :=      wii
BUILD           :=      build
SOURCES         :=      src
DATA            :=      data
INCLUDES        :=		

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------

CFLAGS  = -O2 -Wall $(MACHDEP) $(INCLUDE) `$(PREFIX)pkg-config --cflags sdl2`
CXXFLAGS        =       $(CFLAGS)

LDFLAGS =       -g $(MACHDEP) -Wl,-Map,$(notdir $@).map

#---------------------------------------------------------------------------------
# any extra libraries we wish to link with the project
#---------------------------------------------------------------------------------
LIBS	:=	`$(PREFIX)pkg-config --libs sdl2 SDL2_ttf`

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS := ${DEVKITPRO}/portlibs/ppc

#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT   :=      $(CURDIR)/$(TARGET)

export VPATH    :=      $(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
										$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR  :=      $(CURDIR)/$(BUILD)

#---------------------------------------------------------------------------------
# automatically build a list of object files for our project
#---------------------------------------------------------------------------------
CFILES          :=      $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES        :=      $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
sFILES          :=      $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
SFILES          :=      $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.S)))
BINFILES        :=      $(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*))) 

# LVGL files
CFILES += $(shell find $(LVGL_PATH)/src -type f -name '*.c' | sed 's|^/workspaces/wii/src/||')
# CFILES += $(shell find $(LVGL_PATH)/demos -type f -name '*.c' | sed 's|^/workspaces/wii/src/||')
# CFILES += $(shell find $(LVGL_PATH)/examples -type f -name '*.c' | sed 's|^/workspaces/wii/src/||')
CPPFILES += $(shell find $(LVGL_PATH)/src -type f -name '*.cpp' | sed 's|^/workspaces/wii/src/||')
SFILES += $(shell find $(LVGL_PATH)/src -type f -name '*.S' | sed 's|^/workspaces/wii/src/||')

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
		export LD       :=      $(CC)
else
		export LD       :=      $(CXX)
endif

export OFILES_BIN       :=      $(addsuffix .o,$(BINFILES))
export OFILES_SOURCES := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(sFILES:.s=.o) $(SFILES:.S=.o)
export OFILES := $(OFILES_BIN) $(OFILES_SOURCES)

export HFILES := $(addsuffix .h,$(subst .,_,$(BINFILES)))

#---------------------------------------------------------------------------------
# build a list of include paths
#---------------------------------------------------------------------------------
export INCLUDE  :=      $(foreach dir,$(INCLUDES), -iquote $(CURDIR)/$(dir)) \
										$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
										-I/usr/local/vcpkg/installed/x64-linux/include \
										-I$(CURDIR)/$(BUILD) \
										-I$(LIBOGC_INC) \
										-I$(LVGL_PATH) \
										-I$(LVGL_PATH)/src

#---------------------------------------------------------------------------------
# build a list of library paths
#---------------------------------------------------------------------------------
export LIBPATHS := -L$(LIBOGC_LIB) $(foreach dir,$(LIBDIRS),-L$(dir)/lib)

export OUTPUT   :=      $(CURDIR)/$(TARGET)
.PHONY: $(BUILD) clean

#---------------------------------------------------------------------------------
$(BUILD):
		@[ -d $@ ] || mkdir -p $@
		@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

#---------------------------------------------------------------------------------
clean:
		@echo clean ...
		@rm -fr $(BUILD) $(OUTPUT).elf $(OUTPUT).dol

#---------------------------------------------------------------------------------
run:
		wiiload $(TARGET).dol

#---------------------------------------------------------------------------------
else

DEPENDS := $(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
$(OUTPUT).dol: $(OUTPUT).elf
$(OUTPUT).elf: $(OFILES)

$(OFILES_SOURCES) : $(HFILES)

#---------------------------------------------------------------------------------
# This rule links in binary data with the .jpg extension
#---------------------------------------------------------------------------------
%.jpg.o %_jpg.h :       %.jpg
#---------------------------------------------------------------------------------
		@echo $(notdir $<)
		$(bin2o)

#---------------------------------------------------------------------------------
# Embed TTF files
#---------------------------------------------------------------------------------
%.ttf.o %_ttf.h : %.ttf
		@echo $(notdir $<)
		$(bin2o)

#---------------------------------------------------------------------------------
%.a:
#---------------------------------------------------------------------------------
	$(SILENTMSG) $(notdir $@)
	$(ADD_COMPILE_COMMAND) end
	$(SILENTCMD)rm -f $@
	$(SILENTCMD)$(AR) -rc $@ $^

#---------------------------------------------------------------------------------
%.o: %.cpp
	$(SILENTMSG) $(notdir $<)
	@mkdir -p $(dir $@)
	$(ADD_COMPILE_COMMAND) add $(CC) "$(CPPFLAGS) $(CXXFLAGS) -c $< -o $@" $<
	$(SILENTCMD)$(CXX) -MMD -MP -MF $(DEPSDIR)/$*.d $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@ $(ERROR_FILTER)

#---------------------------------------------------------------------------------
%.o: %.c
	$(SILENTMSG) $(notdir $<)
	@mkdir -p $(dir $@)
	$(ADD_COMPILE_COMMAND) add $(CC) "$(CPPFLAGS) $(CFLAGS) -c $< -o $@" $<
	$(SILENTCMD)$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d $(CPPFLAGS) $(CFLAGS) -c $< -o $@ $(ERROR_FILTER)

#---------------------------------------------------------------------------------
%.o: %.m
	$(SILENTMSG) $(notdir $<)
	@mkdir -p $(dir $@)
	$(ADD_COMPILE_COMMAND) add $(CC) "$(CPPFLAGS) $(OBJCFLAGS) -c $< -o $@" $<
	$(SILENTCMD)$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d $(CPPFLAGS) $(OBJCFLAGS) -c $< -o $@ $(ERROR_FILTER)

#---------------------------------------------------------------------------------
%.o: %.s
	$(SILENTMSG) $(notdir $<)
	@mkdir -p $(dir $@)
	$(ADD_COMPILE_COMMAND) add $(CC) "$(CPPFLAGS) $(ASFLAGS) -c $< -o $@" $<
	$(SILENTCMD)$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d -x assembler-with-cpp $(CPPFLAGS) $(ASFLAGS) -c $< -o $@ $(ERROR_FILTER)

#---------------------------------------------------------------------------------
%.o: %.S
	$(SILENTMSG) $(notdir $<)
	@mkdir -p $(dir $@)
	$(ADD_COMPILE_COMMAND) add $(CC) "$(CPPFLAGS) $(ASFLAGS) -c $< -o $@" $<
	$(SILENTCMD)$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d -x assembler-with-cpp $(CPPFLAGS) $(ASFLAGS) -c $< -o $@ $(ERROR_FILTER)

#---------------------------------------------------------------------------------
# Include dependency files
#---------------------------------------------------------------------------------
-include $(DEPENDS)

#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------
