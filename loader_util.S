global loader
global __asm_gdt_flush
global __asm_idt_load

MAGIC_NUMBER      equ 0x1BADB002    ; the multiboot magic number spec:w
FLAGS             equ 0x0
CHECKSUM          equ -MAGIC_NUMBER
KERNEL_STACK_SIZE equ 16385         ; 16 KiB

extern kmain

; setup the stack with 16KiB 
section .bss
align 16
stack_bottom:
resb KERNEL_STACK_SIZE
stack_top:

section .text
    align 4
    dd MAGIC_NUMBER
    dd FLAGS
    dd CHECKSUM

; __asm_gdt_flush
; Responsible for loading the GDT
; @param unsigned int gdt pointer
__asm_gdt_flush:
    ;cli
    mov eax, [esp+4]    ; Pointer to the GDT as param
    lgdt [eax]          ; Load GDT pointer content
;
    mov ax, 0x10        ; Offset in the GDT to data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Do a far jump
    jmp 0x08:.flush
.flush:
    ret

; __asm_idt_load
; Responsible for loading the IDT structures
; @param unsigned int IDT pointer
__asm_idt_load
    mov eax, [esp + 4]
    lidt [eax]
    ret

; loader
; The linker script (link.ld) specified "loader" as the entry point
; This is where bootloader will jump right after loading the kernel
loader:
    mov esp, stack_bottom + KERNEL_STACK_SIZE ; point esp to the start of the
                                              ; stack (end of memory area)

    call kmain

    ; If kernel has nothing more to do, put into a loop state by
    ; 1) diasbling interrupts with cli (clear interrupt enable in eflags)
    ; 2) Wait for next interrupt to arrive with hlt. Interrupts are disabled, so this will lock the computer
    ; 3) Jump back to hlt if the computer get awaken by an unmaasked interrupt
halt: 
    hlt
    jmp halt
