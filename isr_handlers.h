#ifndef INCLUDE_ISR_HANDLERS_H
#define INCLUDE_ISR_HANDLERS_H

extern void __asm_isr0();
// TODO ... all 32 interrupts

struct regs {
    unsigned int gs, fs, es, ds;
    unsigned int edi, esi, ebp, esp, ebx, edx, ecx, eax;
    unsigned int int_no, err_code;
    unsigned int eip, cs, eflags, useresp, ss;
};

/*
 * Configure all ISR for this operating system
 */
void isr_install();

#endif
