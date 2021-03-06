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
   +----------------+ Kernel image top place
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

.code16
.intel_syntax noprefix
.text
.org 0x0
.align 512

.globl main


main:
  jmp short start
  nop

# 
# Constants definition
.equ STAGE2_MEMORY_LOCATION, 0x9000

#
# Some variables
iBootDrive:   .byte 0
loadmsg:      .asciz "Loading OS...\r\n"
diskerror:    .asciz "Disk error. "
rebootmsg:    .asciz "Press any key to reboot\r\n"

#
# ClearScreen
#
.func ClearScreen
ClearScreen:
  push   bp
  mov    bp, sp
  pusha

  mov    ah, 0x07 # Scroll down
  mov    al, 0x00 # clear window
  mov    bh, 0x07 # white on black
  mov    cx, 0x00 # top left is 0, 0
  mov    dh, 0x18 # 24 rows
  mov    dl, 0x4f # 79 cols
  int    0x10

  popa
  pop    bp
  retw
.endfunc

# WriteString
# si -> pointer to string
#
.func WriteString
WriteString:
  push   bp
  mov    bp, sp

  mov    ah, 0x0e  # 0xe, int 10h => print char
  mov    bx, 0x09  # fg and page 0

char:
  mov    al, [si]

  cmp    al, 0
  je     writestring_done

  int    0x10
  add    si, 1
  jmp    char

writestring_done:
  pop    bp
  retw
.endfunc

.func Reboot
Reboot:
  lea      si, rebootmsg
  call     WriteString
  xor      ax, ax
  int      0x16        # read any key (int 16h, ax=0)

  .byte 0xEA           # machine lang to jump to FFFF:0000 (reboot)
  .word 0x0000
  .word 0xFFFF
.endfunc

# 
# printw_hex
#   dx - word to print
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
  shr dh, 4    # move the higher 4 to the lower part

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
#    dh - number of sectors to read
#    dl - drive to read
#    es:bx - memory region to store
.func read_sector
read_sector:
  nop
  push bp
  mov bp, sp

  push dx        # Store dx to recall how many sectors we wanted to read

  mov ah, 0x02  # Bios read function
  mov al, dh    # NoF Sectors: Read DH sectors from the starting point
  mov ch, 0x00  # Cylinder:    0
  mov dh, 0x00  # Head/Track:  head 0
  mov cl, 0x02  # Sector:      1st sector on the track, starts at 1

  int 0x13
  jc disk_error

  # Restore Dx and compare number of sectors intenteded vs read
  pop dx
  cmp dh, al    # Did we read as many sectors as we wanted?
  jne disk_error

  pop bp
  ret

disk_error:
  lea   si, diskerror
  call  WriteString
  call  Reboot
.endfunc

.func read_stage2
read_stage2:
  push bp
  mov bp, sp

  mov bx, STAGE2_MEMORY_LOCATION
  mov dl, [iBootDrive]  # The boot drive, stored from BIOS

  # TODO we can read at most 18 sectors in floppies
  mov dh, STAGE1_SIZE_SECTOR  # Read X sectors of 512 bytes, where X is defined in the Makefile and
                              # Padded in loader-stage1.bin generation
  call read_sector

  pop bp
  ret
.endfunc

#
# start
#
start:
  cli
  mov iBootDrive, dl  # Save the boot-drive that BIOS put into DL to iBootDrive
  mov ax, cs          # Cs=0x0, where boot is 0x7c00
  mov ds, ax          # Initialize all segment registers DS=0 ES=0 SS=0
  mov es, ax
  mov ss, ax

  # Allocates 1kb for bootloader stack, at 0x7E00 + 1kb
  mov sp, 0x7E00 + 0x400
  mov bp, sp
  sti                  # re-enable interrupts

  # Display loading message
  lea     si, loadmsg
  call    WriteString

  # Prepare floppy drive for use
  mov dl, [iBootDrive]
  xor ax, ax
  int 0x13
  jc  bootFailure      # show message is carry is set from int 13h

  # Read stage2 from the disk, right after stage 1 
  call read_stage2

  # Call bootloader Stage 2 to prepare environment for Kernel
  call STAGE2_MEMORY_LOCATION

bootFailure:
  call ClearScreen

  lea   si, diskerror
  call  WriteString
  call  Reboot

# Fill to 512 bytes and 
.fill (510-(.-main)), 1, 0
.byte 0x55
.byte 0xaa
