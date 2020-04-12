################################################################################ 
# attempt.s
# 
# Experimenting with memory indexing, printing string, etc
################################################################################ 
.code16
.intel_syntax noprefix
.text
.org 0x0

.globl main

main:
	# Stack from 0x7C00 to 0x8C00, 4k in total
	mov bp, 0x8C00
	mov sp, bp
	
# in ATT syntax $palavra gives me the address
#.att_syntax
#	push $palavra
#.intel_syntax noprefix
	lea si, palavra
	push si
	call printstr
	add sp, 2    # return stack 2 bytes, 16 bits

  # signal end of program
	mov ah, 0x0e
	mov al, '#'
	int 0x10

  # Halt for now
loop: jmp loop

.func printstr
printstr:
	push bp
	mov bp, sp

	# get first variable
	mov bx, sp
	add bx, 4
	mov bx, [bx]

	mov ah, 0x0e # print char

printchar:
	mov al, [bx]
	cmp al, 0
	je endprintchar
	int 0x10

	inc bx 
	jmp printchar

endprintchar:

	pop bp
	ret
.endfunc

.fill (499-(.-main)), 1, 0
palavra: .asciz "ola mundo!"


# Fill to 512 bytes and 
#.fill (510-(.-main)), 1, 0
.byte 0x55
.byte 0xaa
