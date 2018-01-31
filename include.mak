# Project-name
PJNAM := ASM_C_combined
#Device and programmer
#DEVICE := atmega328p
DEVICE := atmega8
AVRDUDEDEV := m8
#PROG := -c arduino -P /dev/ttyACM0 -B 115200
PROG := -c avrisp2 -P usb -i 4 -U lfuse:w:0xae:m -U hfuse:w:0xc1:m
#PROG := -c avrisp2 -P usb
#CPU_CLK := 16000000UL
CPU_CLK := 4000000UL
# Compiler
CXX := avr-gcc
CXXFLAGS := -Os -Wall -DF_CPU=$(CPU_CLK) -mmcu=$(DEVICE) -c
INCLUDE := -I
#LDFLAGS := -mmcu=$(DEVICE)
LDFLAGS :=
# Path
AVRLIB := /usr/lib/avr/include
HEADERS := ./src/Header
# Static Code Analysis
SCA := splint
#SCA := cppcheck --force
#SCA := frama-c -cpp-extra-args="-I $(HEADERS)" -cpp-extra-args="-I $(AVRLIB)"
# ELF 2 IHEX
IHEX := avr-objcopy
IHEXFLAGS := -O ihex -R .eeprom
# FLASH
FLASH := avrdude
FLASHFLAGS := -p $(AVRDUDEDEV) $(PROG) -U flash:w:
# Directories / filenames
OBJDIR := obj
BINDIR := bin
DISTDIR := dist
EXEFILE := $(PJNAM).exe
IHEXFILE := $(PJNAM).hex
.SUFFIXES:            # Delete the default suffixes
.SUFFIXES: .c .o .h .sx  # Define our suffix list

objects := $(subst $(SRCDIR),$(OBJDIR),$(cfiles:.c=.o))
objects += $(subst $(SRCDIR),$(OBJDIR),$(sxfiles:.sx=.o))
deps := $(objects:.o=.d)

.PHONY: all clean dist program read doc mem_insights disassembly

all: $(BINDIR)/$(IHEXFILE)

-include $(deps)

$(OBJDIR)/%.d: $(SRCDIR)/%.c
	mkdir -p $(@D)
	$(CXX) $(INCLUDE) $(HEADERS) -MM -MT "$@ $(patsubst %.d,%.o,$@)" -MF $@ $<
$(OBJDIR)/%.d: $(SRCDIR)/%.sx
	mkdir -p $(@D)
	$(CXX) $(INCLUDE) $(HEADERS) -MM -MT "$@ $(patsubst %.d,%.o,$@)" -MF $@ $<

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@echo compiling  $< 
	$(CXX) $(CXXFLAGS) $(INCLUDE) $(HEADERS) $< -o $@
	$(SCA) $(INCLUDE) $(HEADERS) $(INCLUDE) $(AVRLIB) $<
#	$(SCA) $<
$(OBJDIR)/%.o: $(SRCDIR)/%.sx
	@echo compiling  $< 
	$(CXX) $(CXXFLAGS) $(INCLUDE) $(HEADERS) $< -o $@

$(BINDIR)/$(EXEFILE): $(objects)
	mkdir -p $(BINDIR)
	$(CXX) -o $@ $^ $(LDFLAGS)

$(BINDIR)/$(IHEXFILE): $(BINDIR)/$(EXEFILE)
	$(IHEX) $(IHEXFLAGS) $(BINDIR)/$(EXEFILE) $(BINDIR)/$(IHEXFILE)
# Show memory usage
	avr-size -C --mcu=$(DEVICE) $(BINDIR)/$(EXEFILE)

$(DISTDIR)/gepackt.tar.gz: $(BINDIR)/$(IHEXFILE)
	mkdir -p $(DISTDIR)
	tar cvf $(DISTDIR)/gepackt.tar $(BINDIR)/$(EXEFILE) $(BINDIR)/$(IHEXFILE)
	gzip $(DISTDIR)/gepackt.tar

dist: $(DISTDIR)/gepackt.tar.gz

clean:
	$(RM) -rf $(OBJDIR)
	$(RM) -rf $(BINDIR)

ultraclean: clean
	$(RM) -rf $(DISTDIR)

program:
	$(FLASH) $(FLASHFLAGS)$(BINDIR)/$(IHEXFILE):i
#read ihex backup
read:
	$(FLASH) -F -V $(PROG) -p $(AVRDUDEDEV)
doc:
	mkdir -p doc
	doxygen Doxyfile

mem_insights:
#readelf, map
	avr-readelf -a $(BINDIR)/$(EXEFILE) > x.map
#avr-readelf -a led.o
	avr-nm -a $(BINDIR)/$(EXEFILE) > readelf
#avr-nm -a led.o
# Display the contents of the symbol table(s), map file
	avr-objdump -t $(BINDIR)/$(EXEFILE) > symbol.table
disassembly:
# Intermix source code with disassembly, Display assembler contents of executable sections
	avr-objdump -Sd $(BINDIR)/$(EXEFILE) > dis.assembly 

# TODO: change in headerfiles won't trigger rebuilt?
