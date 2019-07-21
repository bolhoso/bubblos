#include "idt.h"

#define NUM_IDT_ENTRIES 256
struct idt_entry idt[NUM_IDT_ENTRIES];
struct idt_ptr idtp;

void idt_set_gate(unsigned char num, unsigned long base, unsigned short sel, unsigned char flags) {

    idt[num].base_lo = (base & 0xFFFF);
    idt[num].base_hi = (base >> 16) & 0xFFFF;

    idt[num].sel     = sel;
    idt[num].always0 = 0;
    idt[num].flags   = flags;
}

void idt_install() {
    // Sets the idtp pointer
    idtp.limit = (sizeof (struct idt_entry) * NUM_IDT_ENTRIES) - 1; 
    idtp.base = (unsigned int) &(idt[0]);

    // TODO: implement memset
    // TODO: pointer size is machien specific
    for (unsigned int i = 0; i < sizeof(struct idt_entry) * NUM_IDT_ENTRIES; i++) {
        *((unsigned int *)&idt + i) = 0;
    }

    __asm_idt_load((unsigned int)&idtp);
}
