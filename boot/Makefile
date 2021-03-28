OBJECTS = loader.o loader-stage1.o
STAGE1_OBJECTS = loader-stage1.o disk.o 
CC = gcc
CFLAGS = -g -m32 -nostdlib -nostdinc -fno-pie -fno-builtin -fno-stack-protector \
         -nostartfiles -nodefaultlibs -Wall -Wextra -Werror -c
LD = ld
LDFLAGS = -T link.ld -melf_i386
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

loader-stage1.bin: $(STAGE1_OBJECTS)
	$(LD) $(LDFLAGS) -Ttext 0x9000 -o loader-stage1.elf $(STAGE1_OBJECTS)
	objcopy -O binary -j .text loader-stage1.elf loader-stage1-temp.bin 
	dd if=/dev/zero of=stage1-padding.img bs=1 count=`perl -e 'print($(STAGE1_SIZE_BYTES) - ((-s "loader-stage1-temp.bin")%512))'`
	cat loader-stage1-temp.bin stage1-padding.img > $@
	rm loader-stage1-temp.bin stage1-padding.img

%.o: %.S
	$(AS) $(ASFLAGS) $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@


.PHONY: clean
clean:
	rm -rf *.bin *.img 
	rm -rf *.out  *.o
	rm -rf *.elf
