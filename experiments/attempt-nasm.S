[org 0x7c00]

main:
	; Stack from 0x7C00 to 0x8C00, 4k in total
	mov bp, 0x8C00
	mov sp, bp

	lea bx, [palavra]
;	sub bx, 0x7c00
	push bx
	call printstr
	add sp, 2    ; return stack 2 bytes, 16 bits

  ; signal end of program
	mov ah, 0x0e
	mov al, '#'
	int 0x10

  ; Halt for now
loop: jmp loop

printstr:
	push bp
	mov bp, sp

	; get first variable
	mov bx, sp
	add bx, 4
	mov bx, [bx]

	mov ah, 0x0e ; print char

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

times 499-($-$$) db 0
palavra: db "ola mundo!", 0

; Fill to 512 bytes and 
;times 499-($-$$) db 0
db 0x55
db 0xaa
