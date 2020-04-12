OBJECTS = loader.o kmain.o fbuffer.o io.o mem.o descriptor_tables.o idt.o isr.o isr_handlers.o
LD = ld
LDFLAGS = -T link.ld -melf_i386
CC = gcc
CFLAGS = -g -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector \
         -nostartfiles -nodefaultlibs -Wall -Wextra -Werror -c
AS = nasm
ASFLAGS = -f bin

all: kernel.elf

kernel.elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o kernel.elf
	objcopy -O binary -j .text kernel.elf kernel.bin

disk.img: loader.bin # TODO: kernel.elf
	cp loader.bin disk.img

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
loader.o: loader.s
	as --32 -o loader.o loader.s
	$(LD) $(LDFLAGS) -o loader.out loader.o -Ttext 0x7c00

loader.bin: loader.o
	objcopy -O binary -j .text loader.out loader.bin

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

clean:
	rm -rf *.o kernel.elf disk.img log-bochs.txt
