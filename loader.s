global loader

MAGIC_NUMBER      equ 0x1BADB002 ; the multiboot magic number spec:w
FLAGS             equ 0x0
CHECKSUM          equ -MAGIC_NUMBER
KERNEL_STACK_SIZE equ 4096

extern k_main

; setup the stack
section .bss
align 4
kernel_stack:
    resb KERNEL_STACK_SIZE

section .text
align 4
    dd MAGIC_NUMBER
    dd FLAGS
    dd CHECKSUM

loader:
    mov esp, kernel_stack + KERNEL_STACK_SIZE ; point esp to the start of the
                                              ; stack (end of memory area)

    call k_main

.loop:
    jmp .loop
