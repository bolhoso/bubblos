OBJECTS = loader.o loader-stage1.o
LD = ld
LDFLAGS = -T ../link.ld -melf_i386
AS = as
ASFLAGS = --32 --defsym STAGE1_SIZE_BYTES=$(STAGE1_SIZE_BYTES) \
					--defsym STAGE1_SIZE_SECTOR=$(STAGE1_SIZE_SECTOR)

# Stage 1 has 4 sectors fixed
STAGE1_SIZE_SECTOR=4
STAGE1_SIZE_BYTES=2048

all: $(OBJECTS) all-bin

all-bin: loader.bin loader-stage1.bin

loader.bin: loader.o
	$(LD) $(LDFLAGS) -o loader.elf $< -Ttext 0x7c00
	objcopy -O binary -j .text loader.elf $@

loader-stage1.bin: loader-stage1.o
	$(LD) $(LDFLAGS) -o loader-stage1.elf $< -Ttext 0x9000
	objcopy -O binary -j .text loader-stage1.elf $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -rf *.bin *.img 
	rm -rf *.out  *.o
	rm -rf *.elf
