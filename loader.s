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


# read_sector
# Sector   = (LBA mod SectorsPerTrack) + 1
# Cylinder = (LBA / SectorsPerTrack) / NumHeads
# Head     = (LBA / SectorsPerTrack) mod NumHeads
# ax - 


# start
#
start:
  cli
  mov iBootDrive, dl	
  mov ax, cs	 	 	# Cs=0x0, where boot is 0x07c00
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7C00
  sti							# enable interrupts

  # Display loading message
	lea		si, loadmsg
	call	WriteString

  # Prepare floppy drive for use
  mov dl, iBootDrive
  xor ax, ax
  int 0x13
  jc	bootFailure	 	 # show message is carry is set from int 13h

  # Halt for now
loop: jmp loop

bootFailure:
# call ClearScreen

#	xchg bx, bx
  lea		si, diskerror
  call	WriteString
  call	Reboot

loadmsg:		.asciz "Loading OS...\r\n"
diskerror:	.asciz "Disk error. "
rebootmsg:	.asciz "Press any key to reboot\r\n"


# Fill to 512 bytes and 
.fill (510-(.-main)), 1, 0
.byte 0x55
.byte 0xaa
