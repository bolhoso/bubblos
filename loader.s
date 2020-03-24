bits 16
org 0x7c00

global main
global WriteString
global Reboot

main:
  jmp short start
  nop


ClearScreen:
	push	bp
	mov		bp, sp
	pusha

	mov		ah, 0x07 ; Scroll down
	mov		al, 0x00 ; clear window
	mov		bh, 0x07 ; white on black
	mov		cx, 0x00 ; top left is 0, 0
	mov		dh, 0x18 ; 24 rows
	mov		dl, 0x4f ; 79 cols
	int		0x10

	popa
	mov		sp, bp
	pop		bp
	ret

; si -> pointer to string
WriteString:
  mov		ah, 0x0e  ; 0xe, int 10h => print char
  mov		bx, 0x09  ; fg and page 0

char:
	mov		al, [si]

	cmp		al, 0
	je		WriteString_done

	int   0x10
	add		si, 1
	jmp		char

WriteString_done:
  ret

start:
  cli
  mov [iBootDrive], dl  
  mov ax, cs          ; Cs=0x0, where boot is 0x07c00
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7C00
  sti                  ; enable interrupts

  ; Prepare floppy drive for use
  mov dl, iBootDrive
  xor ax, ax
  int 0x13
  jc bootFailure      ; show message is carry is set from int 13h

bootFailure:
	call ClearScreen

;	xchg bx, bx
  mov   si, diskerror
	call	WriteString
  call	Reboot

Reboot:
  mov			si, rebootmsg
  call    WriteString
  xor     ax, ax
  int     0x16            ; read any key (int 16h, ax=0)

  db 0xEA                      ; machine lang to jump to FFFF:0000 (reboot)
  dw 0x0000
  dw 0xFFFF
	ret


# Data
loadmsg:    db "Loading OS...", 13, 10, 0
diskerror:  db "Disk error. ", 0
rebootmsg:  db "Press any key to reboot", 13, 10, 0
iBootDrive: db 0

times 510-($-$$) db 0
dw 0xAA55
