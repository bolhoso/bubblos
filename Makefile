OBJECTS = call.o kmain.o fbuffer.o io.o mem.o descriptor_tables.o idt.o isr.o isr_handlers.o loader_util.o
LD = ld
LDFLAGS = -T link.ld -melf_i386
CC = gcc
CFLAGS = -g -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector \
         -nostartfiles -nodefaultlibs -Wall -Wextra -Werror -c
AS = nasm
ASFLAGS = -f elf

# TODO: there's GAS and NASM mixed files.... what do I do?! 0.0 :/

all: kernel.elf disk.img

#
# Kernel targets
#
kernel.elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o kernel.elf

call.o: call.s
	as --32 -o call.o call.s

kernel.bin: kernel.elf
	ld -T link.ld -m elf_i386 -s -Ttext 0x9000 --oformat binary -o kernel.bin kernel.elf

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

#
# Disk Image
#
disk.img: bootloader kernel.bin
	# When booting from Bochs disk, disk image size must be a multiple of 512 byte
	# dd if=/dev/zero of=zero.img bs=1 count=`perl -e 'print(512 - ((-s "kernel.bin")%512))'`
	cat boot/loader.bin boot/loader-stage1.bin kernel.bin > disk.img

.PHONY: bootloader
bootloader:
	$(MAKE) -C boot/

#
# Running/Testing Targets
#
run: disk.img
	qemu-system-i386 disk.img

# Remote debug. In GDB, use to connect: 
# target remote localhost:1234
debug: disk.img
	qemu-system-i386 -s -S disk.img &
	gdb kernel.elf -ex "target remote localhost:1234"

eclipse-debug: disk.img
	qemu-system-i386 -gdb pipe:lala -S disk.img &

runb: disk.img # doesn't stop at beggining
	bochs -f .bochsrc.txt -q -rc .bochsrc-debugger.rc

rundbg: disk.img # with debugger stop at beggining
	bochs -f .bochsrc.txt -q

#
# Clean
#
.PHONY: clean
clean:
	rm -rf *.img *.out *.bin *.o kernel.elf disk.img log-bochs.txt
	$(MAKE) -C boot/ clean
