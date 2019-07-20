global loader

MAGIC_NUMBER      equ 0x1BADB002    ; the multiboot magic number spec:w
FLAGS             equ 0x0
CHECKSUM          equ -MAGIC_NUMBER
KERNEL_STACK_SIZE equ 16385         ; 16 KiB

extern k_main

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

; The linker script (link.ld) specified "loader" as the entry point
; This is where bootloader will jump right after loading the kernel
loader:
    mov esp, stack_bottom + KERNEL_STACK_SIZE ; point esp to the start of the
                                              ; stack (end of memory area)

    call k_main

    ; If kernel has nothing more to do, put into a loop state by
    ; 1) diasbling interrupts with cli (clear interrupt enable in eflags)
    ; 2) Wait for next interrupt to arrive with hlt. Interrupts are disabled, so this will lock the computer
    ; 3) Jump back to hlt if the computer get awaken by an unmaasked interrupt
halt: 
    hlt
    jmp halt
