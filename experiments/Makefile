attempt.o: attempt.s
	as --no-pad-sections --32 -o attempt.o attempt.s 

# GAS generates at offset 0, we have to use LD to move offset to 0x7c00
attempt.bin: attempt.o
	ld -m elf_i386 -s -Ttext 0x7c00 --oformat binary -o attempt.bin attempt.o 
run-attempt:
	qemu-system-i386 attempt.bin

# Nasm generates binary using org 0x7c00 directly
attempt-nasm.bin: attempt-nasm.s
	nasm attempt-nasm.s -f bin -o attempt-nasm.bin
run-attempt-nasm:
	qemu-system-i386 attempt-nasm.bin

