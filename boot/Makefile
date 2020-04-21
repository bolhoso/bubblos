OBJECTS = loader.o loader-stage1.o

LD = ld
LDFLAGS = -T ../link.ld -melf_i386
AS = as
ASFLAGS = --32

all: $(OBJECTS) all-bin

all-bin: loader.bin loader-stage1.bin

loader.bin: loader.o
	$(LD) $(LDFLAGS) -o loader.elf $< -Ttext 0x7c00
	objcopy -O binary -j .text loader.elf $@

loader-stage1.bin: loader-stage1.o
	$(LD) $(LDFLAGS) -o loader-stage1.elf $< -Ttext 0x7c00
	objcopy -O binary -j .text loader-stage1.elf $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -rf *.bin *.img 
	rm -rf *.out  *.o
	rm -rf *.elf
