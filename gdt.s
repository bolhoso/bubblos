global __asm_gdt_flush

__asm_gdt_flush:
    cli
    mov eax, [esp+4]    ; Pointer to the GDT as param
    lgdt [eax]          ; Load GDT pointer content
;
    mov ax, 0x10        ; Offset in the GDT to data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    jmp 0x08:.flush
.flush:

    ret
