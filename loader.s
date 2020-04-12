.code16
.intel_syntax noprefix
.text
.org 0x0

.globl main

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
	
	pop bp
	ret
.endfunc


# read_sector
# Sector   = (LBA mod SectorsPerTrack) + 1
# Cylinder = (LBA / SectorsPerTrack) / NumHeads
# Head     = (LBA / SectorsPerTrack) mod NumHeads
.func read_sector
read_sector:
	push bp
	mov bp, sp

	mov ah, 0x02
	mov dl, [iBootDrive]			# Boot drive
	mov ch, 3			# Cylinder 3
	mov dh, 1			# Track on the 2nd side of floppy, 0 is the first
	mov cl, 4			# 4th sector on the track, starts at 1
	mov al, 5			# read 5 sectors from the starting point

	# Set the address bios should the sector to
	# BIOS expect to find it in ES:BX
  # 0xa000:0x1234 --> 0xA1234 physical
	mov bx, 0xa000
	mov es, bx
	mov bx, 0x1234

	int 0x13
	jc disk_error

disk_success:
	.asciz "Read good!"
	lea si, disk_success
	call WriteString

	pop bp
	ret

disk_error:
  lea		si, diskerror
  call	WriteString
  call	Reboot
.endfunc


# start
#
start:
  cli
  mov iBootDrive, dl	
  mov ax, cs	 	 	# Cs=0x0, where boot is 0x07c00
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x9C00  # stck starts at 0x9c00 and shrinks until 0x7c00, that's 0x2000 (8kb) of size
  sti							# enable interrupts

  # Display loading message
	lea		si, loadmsg
	call	WriteString

  # Prepare floppy drive for use
  mov dl, iBootDrive
  xor ax, ax
  int 0x13
  jc	bootFailure	 	 # show message is carry is set from int 13h

  # Read kernel from disk
	call read_sector

  # Halt for now
loop: jmp loop

bootFailure:
  call ClearScreen

  lea		si, diskerror
  call	WriteString
  call	Reboot

loadmsg:		.asciz "Loading OS...\r\n"
diskerror:	.asciz "Disk error. "
rebootmsg:	.asciz "Press any key to reboot\r\n"
newline:	.asciz "\r\n"


# Fill to 512 bytes and 
.fill (510-(.-main)), 1, 0
.byte 0x55
.byte 0xaa
