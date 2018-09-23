global outb

; outb - send a byte to an IO port
; stack: [esp + 8] data byte
;        [esp + 4] IO port
;        [esp    ] return address
outb:
    mov al, [esp + 8]
    mov dx, [esp + 4]
    out dx, al
    ret
