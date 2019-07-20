OBJECTS = loader.o kmain.o fbuffer.o io.o mem.o descriptor_tables.o gdt.o
CC = gcc
CFLAGS = -g -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector \
         -nostartfiles -nodefaultlibs -Wall -Wextra -Werror -c
LDFLAGS = -T link.ld -melf_i386
AS = nasm
ASFLAGS = -f elf

all: kernel.elf

kernel.elf: $(OBJECTS)
	ld $(LDFLAGS) $(OBJECTS) -o kernel.elf

os.iso: kernel.elf
	cp kernel.elf iso/boot/kernel.elf
	genisoimage -R                              \
	            -b boot/grub/stage2_eltorito    \
	            -input-charset utf8             \
	            -no-emul-boot                   \
	            -boot-load-size 4               \
	            -boot-info-table \
	            -A os                           \
	            -quiet                          \
	            -o os.iso                       \
	            iso

run: os.iso
	qemu-system-i386 --cdrom os.iso

runb: os.iso
	bochs -f .bochsrc.txt -q

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

clean:
	rm -rf *.o kernel.elf os.iso log-bochs.txt
