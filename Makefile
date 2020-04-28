OBJECTS = call.o kmain.o fbuffer.o io.o mem.o descriptor_tables.o idt.o isr.o isr_handlers.o loader_util.o
LD = ld
LDFLAGS = -T link-kernel.ld -melf_i386
CC = gcc
CFLAGS = -g -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector \
         -nostartfiles -nodefaultlibs -Wall -Wextra -Werror -c
AS = nasm
ASFLAGS = -f elf

# TODO: there's GAS and NASM mixed files.... what do I do?! 0.0 :/

all: kernel.elf bubblos.img

#
# Kernel targets
#
kernel.elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o kernel.elf

call.o: call.s
	as --32 -o call.o call.s

kernel.bin: kernel.elf
	$(LD) $(LDFLAGS) -s --oformat binary -o kernel.bin kernel.elf

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

#
# Disk Image
#
bubblos.img: bootloader kernel.bin
	# When booting from Bochs disk, disk image size must be a multiple of 512 byte
	dd if=/dev/zero of=padding.img bs=1 count=`perl -e 'print(512 - ((-s "kernel.bin")%512))'`
	cat boot/loader.bin boot/loader-stage1.bin kernel.bin padding.img > disk.tmp.img
	dd if=/dev/zero of=zero.img bs=512 count=`perl -e 'print((10653696 - (-s "disk.tmp.img"))/512)'`
	cat disk.tmp.img zero.img > bubblos.img
	rm disk.tmp.img zero.img


.PHONY: bootloader
bootloader:
	$(MAKE) -C boot/

#
# Running/Testing Targets
#
run: bubblos.img
	qemu-system-i386 bubblos.img

# Remote debug. In GDB, use to connect: 
# target remote localhost:1234
debug: bubblos.img
	qemu-system-i386 -s -S bubblos.img &
	gdb kernel.elf -ex "target remote localhost:1234" -ex "symbol-file boot/loader-stage1.elf"

eclipse-debug: bubblos.img
	qemu-system-i386 -gdb pipe:lala -S bubblos.img &

runb: bubblos.img # doesn't stop at beggining
	bochs -f .bochsrc.txt -q -rc .bochsrc-debugger.rc

rundbg: bubblos.img # with debugger stop at beggining
	bochs -f .bochsrc.txt -q

#
# Clean
#
.PHONY: clean
clean:
	rm -rf *.img *.out *.bin *.o kernel.elf bubblos.img log-bochs.txt
	$(MAKE) -C boot/ clean
