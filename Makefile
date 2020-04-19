OBJECTS = loader-stage1.o kmain.o fbuffer.o io.o mem.o descriptor_tables.o idt.o isr.o isr_handlers.o loader_util.o
LD = ld
LDFLAGS = -T link.ld -melf_i386
CC = gcc
CFLAGS = -g -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector \
         -nostartfiles -nodefaultlibs -Wall -Wextra -Werror -c
AS = nasm
ASFLAGS = -f elf

# TODO: there's GAS and NASM mixed files.... what do I do?! 0.0 :/

all: kernel.elf

kernel.elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o kernel.elf

kernel.bin: kernel.elf
	ld -T link.ld -m elf_i386 -s -Ttext 0x9000 --oformat binary -o kernel.bin kernel.elf

disk.img: loader.bin kernel.bin
	# When booting from Bochs disk, disk image size must be a multiple of 512 byte
	# dd if=/dev/zero of=zero.img bs=1 count=`perl -e 'print(512 - ((-s "kernel.bin")%512))'`
	cat loader.bin kernel.bin > disk.img

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

loader.o: loader.s
	as --32 -o $@ $<

loader.bin: loader.o
	$(LD) $(LDFLAGS) -o loader.out loader.o -Ttext 0x7c00
	objcopy -O binary -j .text loader.out loader.bin

loader-stage1.o: loader-stage1.s
	as --32 -o $@ $<

call.o: call.s
	as --32 -o call.o call.s

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

clean:
	rm -rf *.img *.out *.bin *.o kernel.elf disk.img log-bochs.txt
