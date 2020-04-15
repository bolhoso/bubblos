OBJECTS = kmain.o fbuffer.o io.o mem.o descriptor_tables.o idt.o isr.o isr_handlers.o loader_util.o
LD = ld
LDFLAGS = -T link.ld -melf_i386
CC = gcc
CFLAGS = -g -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector \
         -nostartfiles -nodefaultlibs -Wall -Wextra -Werror -c
AS = nasm
ASFLAGS = -f elf

all: kernel.elf

kernel.elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o kernel.elf

kernel.bin: kernel.elf
	ld -m elf_i386 -s -Ttext 0x0000 --oformat binary -o kernel.bin kernel.elf

disk.img: loader.bin kernel.bin
	# When booting from Bochs disk, disk image size must be a multiple of 512 byte
	dd if=/dev/zero of=zero.img bs=1 count=`perl -e 'print(512 - ((-s "kernel.bin")%512))'`
	# For now, compile the simple kernel that writes X to video memory
	# it's relocated to 0x9000, where (or more or less where) the booloader will call
	# it by hand
	gcc -ffreestanding -c mykernel.c -o mykernel.o
	ld -o mykernel.bin -Ttext 0x9000 mykernel.o --oformat binary
	cat loader.bin mykernel.bin > disk.img

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

# TODO temporary while I try writing my bootloader
loader.out: loader.s
	as --32 -o loader.o2 loader.s
	$(LD) $(LDFLAGS) -o loader.out loader.o2 -Ttext 0x7c00 # TODO *.o for kmain

loader.bin: loader.out
	objcopy -O binary -j .text loader.out loader.bin

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

clean:
	rm -rf *.out *.bin *.o kernel.elf disk.img log-bochs.txt
