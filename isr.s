global __asm_isr0
extern _fault_handler

; Exception Description                               Error Code?
; 0         Division By Zero Exception                No
; 1         Debug Exception                           No
; 2         Non Maskable Interrupt Exception          No
; 3         Breakpoint Exception                      No
; 4         Into Detected Overflow Exception          No
; 5         Out of Bounds Exception                   No
; 6         Invalid Opcode Exception                  No
; 7         No Coprocessor Exception                  No
; 8         Double Fault Exception                    Yes
; 9         Coproc Segment Overrun Exception          No
; 10        Bad TSS Exception                         Yes
; 11        Segment Not Present Exception             Yes
; 12        Stack Fault Exception                     Yes
; 13        General Protectn Fault Exception          Yes
; 14        Page Fault Exception                      Yes
; 15        Unknown Interrupt Exception               No
; 16        Coprocessor Fault Exception               No
; 17        Alignment Check Exception (486+)          No
; 18        Machine Check Exception (Pentium/586+)    No
; 19 to 31  Reserved Exceptions                       No

; ISR 0: Divide by zero exception
__asm_isr0:
    cli
    push byte 0 ; A normal ISR stub that pops a dummy error code to keep the stack uniform
    push byte 0 ; As this one has no error code (table above)
    jmp isr_common_stub

; isr_common_stub
; Saves the processor state, sets kernel mode segments, call the C-level handler
; and restore the stack frame
isr_common_stub:
    pusha           ; Pushes all general purp registers
    push ds
    push es
    push fs
    push gs
    mov ax, 0x10    ; Kernel Data Segment descriptor (TODO: what is this?)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov eax, esp
    push eax

    mov eax, _fault_handler  ; Call C fault_handler, preserving EIP reg
    call eax
    
    ; Restore the stack and general purpose registers
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    popa

    add esp, 8  ; cleans the pushed error code (4 bytes) and the ISR number (4 bytes)
    iret        ; Exit from interrupt, pops 5 CS, EIP, EFLAGS, SS and ESP

