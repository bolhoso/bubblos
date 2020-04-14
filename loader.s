.code16
.intel_syntax noprefix
.text
.org 0x0

.globl main

/*******************************************************************************

 This is the bootloader for my toy operating systems. Below is the main BIOS, 
 Loader and Kernel memory organization as it stands now.

	 |================| 0x100000 (1mb boundary)
	 |   BIOS 256k    |
	 |================| 0xC0000
	 | Vid Mem (128k) |
	 |================| 0xA0000
	 | Ext. BIOS Data |
	 |  Area (639kb)  |
	 |================| 0x9fc00
	 |                |
	 |  Free (638kb)  |
	 |                |
	 |                |
	 +----------------+ <To Be Defined>
	 |  Kernel Load   |
	 |     Area       |
	 +----------------+ 0x9000
	 |   <Not Used>   |
	 +----------------+ 0x7f00
	 | Stack(256byte) |       >> Remember stack grows downward
	 +----------------+ 0x7e00
	 |  Boot  Sector  |
	 |   (512 bytes)  |
	 |================| 0x7c00
	 |                |
	 |================| 0x500
	 | Bios Data Area |
	 |================| 0x400
	 | Int Vect Table |
	 |     (1kb)      |
	 |================| 0x0

 Lines with === are defined by IBM PC Architecture and --- by this bootloader
 and/or kernel organization

*******************************************************************************/

main:
  jmp short start
  nop

# variables
iBootDrive: .byte 0

#
# 
.func ClearScreen
ClearScreen:
  push	bp
  mov		bp, sp
  pusha

  mov		ah, 0x07 # Scroll down
  mov		al, 0x00 # clear window
  mov		bh, 0x07 # white on black
  mov		cx, 0x00 # top left is 0, 0
  mov		dh, 0x18 # 24 rows
  mov		dl, 0x4f # 79 cols
  int		0x10

  popa
  mov		sp, bp
  pop		bp
  retw
.endfunc

# WriteString
# si -> pointer to string
#
.func WriteString
WriteString:
	push bp
	mov bp, sp
	pusha

  mov		ah, 0x0e	# 0xe, int 10h => print char
  mov		bx, 0x09  # fg and page 0

char:
  mov		al, [si]

  cmp		al, 0
  je		writestring_done

  int	 0x10
  add		si, 1
  jmp		char

writestring_done:
	popa
	pop bp
  retw
.endfunc

.func Reboot
Reboot:
  lea			si, rebootmsg
  call		WriteString
  xor			ax, ax
  int			0x16				# read any key (int 16h, ax=0)

  .byte 0xEA	 	 	 	 	 	 		# machine lang to jump to FFFF:0000 (reboot)
  .word 0x0000
  .word 0xFFFF
.endfunc

# 
# printw_hex
#	 dx - word to print
.func printw_hex
printw_hex:
	push bp
	mov bp, sp

	mov ah, 0xe # print char
	mov al, '0'
	int 0x10
	mov al, 'x'
	int 0x10
printw_loop:
	mov bx, dx
	and dh, 0xF0 # DL & 0011b
	shr dh, 4		 # move the higher 4 to the lower part

	# Char to print: AL < 10? Add '0' ASCII
	mov al, dh
	cmp al, 10
	jl  add_0

	# AL >= 10, add A for hex
	sub al, 10
	add al, 'A'
	jmp print_digit

add_0:
	add al, '0'

print_digit:
	int 0x10

	# Restore digit to print (DX) and shift 2bits to get next 2 to show
	mov dx, bx
	shl dx, 4
	cmp dx, 0
	jne printw_loop

	mov al, ' '
	int 0x10
	
	pop bp
	ret
.endfunc

#
# read_sector
#		dh - number of sectors to read
#		dl - drive to read
#	  es:bx - memory region to store
.func read_sector
read_sector:
	push bp
	mov bp, sp

	push dx				# Store dx to recall how many sectors we wanted to read

	mov ah, 0x02	# Bios read function
	mov al, dh		# NoF Sectors: Read DH sectors from the starting point
	mov ch, 0x00	# Cylinder:    0
	mov dh, 0x00	# Head/Track:  head 0
	mov cl, 0x01	# Sector:      1st sector on the track, starts at 1

	int 0x13
	jc disk_error

  # Restore Dx and compare number of sectors intenteded vs read
	pop dx
	cmp dh, al		# Did we read as many sectors as we wanted?
	jne disk_error

	lea si, disk_success
	call WriteString

	pop bp
	ret

disk_error:
  lea		si, diskerror
  call	WriteString
  call	Reboot
.endfunc

#
# start
#
start:
  cli
  mov iBootDrive, dl	
  mov ax, cs	 	 	# Cs=0x0, where boot is 0x7c00
  mov ds, ax      # DS=0 ES=0 SS=0
  mov es, ax
  mov ss, ax
  mov sp, 0x7F00  # 256 bytes of stack, after 0x7E00
	mov bp, sp
  sti							# enable interrupts

  # Display loading message
	lea		si, loadmsg
	call	WriteString

  # Prepare floppy drive for use
  mov dl, [iBootDrive]
  xor ax, ax
  int 0x13
  jc	bootFailure	 	 # show message is carry is set from int 13h

######### TEST DISK: read 42 sectors, including boot sector and put at 0x9000
# TODO to boot the kernel, I should not read the first sector
	mov bx, 0x9000
	mov dl, [iBootDrive]	# The boot drive, stored from BIOS
	mov dh, 42						# 64 sectors of 512 bytes, beware this is highly coupled with 
												# Makefile creating disk image of enough size
	call read_sector

  # bios boot singature 0xAA55
	mov dx, [0x9000 + 0x1fe]
	call printw_hex

  # multiboot signature print #1BadBOOT
	mov dx, [0x9000 + 512] # offset 0x200 on disk.img
	call printw_hex
	mov dx, [0x9000 + 514] # offset 0x202
	call printw_hex

#	00003220  44 69 76 69 73 69 6f 6e  20 42 79 20 30 00 00 00  |Division By 0...|
	mov dx, [0x9000 + 0x500] # ffbe
	call printw_hex

	mov dx, [0x9000 + 0xa00] # 660c
	call printw_hex

	mov dx, [0x9000 + 0xde0] # 241c
	call printw_hex

	mov dx, [0x9000 + 0x1200] # 6843
	call printw_hex

	mov dx, [0x9000 + 0x1500] # 0xf1ac
	call printw_hex

	mov dx, [0x9000 + 0x1720] # 0x6202
	call printw_hex

	mov dx, [0x9000 + 0x3220] # 6944
	call printw_hex

	mov dx, [0x9000 + 0x3222] # 0x6976
	call printw_hex

	mov dx, [0x9000 + 0x322B] # 0x3020
	call printw_hex

	mov si, 0x9000 + 0x3220
	call WriteString
######### TEST DISK

  # Halt for now
	jmp .

bootFailure:
  call ClearScreen

  lea		si, diskerror
  call	WriteString
  call	Reboot

loadmsg:			.asciz "Loading OS...\r\n"
diskerror:		.asciz "Disk error. "
rebootmsg:		.asciz "Press any key to reboot\r\n"
disk_success: .asciz "Read from disk!"

# Fill to 512 bytes and 
.fill (510-(.-main)), 1, 0
.byte 0x55
.byte 0xaa
