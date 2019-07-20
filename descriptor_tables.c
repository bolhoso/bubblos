#include "descriptor_tables.h"

extern void __asm_gdt_flush(unsigned int);
static void init_gdt();
static void gdt_set_gate(int, unsigned int, unsigned int, unsigned char, unsigned char);

gdt_entry_t gdt_entries[3];
gdt_ptr_t   gdt_ptr;
//idt_entry_t idt_entries[24];
//idt_ptr_t idt_ptr;

// 10010010b 0x92 - Access
// 10011010b 0x9A - Access
// ⎢⎢⎢⎢⎢⎢⎢⎣ P: Is Segment Present
// ⎢⎢⎢⎢⎢⎢⎣_ DPL: Descriptor privilege ring (0 kernel, 3 application)
// ⎢⎢⎢⎢⎢⎣__ DPL
// ⎢⎢⎢⎢⎣___ DT: Descriptor Type
// ⎢⎢⎢⎣____ Type: Segment type: code/data
// ⎢⎢⎣_____ Type
// ⎢⎣______ Type
// ⎣_______ Type

// 11001111b 0xCF - Granularity
// ⎢⎢⎢⎢⎢⎢⎢⎣ G: Granularity 0=1 byte, 1=1KiB
// ⎢⎢⎢⎢⎢⎢⎣_ D: Operand size 0=16bit, 1=32bit
// ⎢⎢⎢⎢⎢⎣__ 0: 0, constant
// ⎢⎢⎢⎢⎣___ A: Available for system use (always 0)
// ⎢⎢⎢⎣____ Segment Length:
// ⎢⎢⎣_____ Segment Length:
// ⎢⎣______ Segment Length:
// ⎣_______ Segment Length:

/*
 * Inits GDT with flat 4gb memory model
 * kernel code and data segment share the same ring 0, no separation
 */
void init_descriptor_tables() {
    init_gdt();
}

static void init_gdt() {
    gdt_ptr.limit = (sizeof(gdt_entry_t) * 5) - 1;
    gdt_ptr.base  = (unsigned int)&gdt_entries;

    gdt_set_gate(0, 0, 0, 0, 0);                // Null segment, mandatory to avoid processor fault
    gdt_set_gate(1, 0, 0xFFFFFFFF, 0x9A, 0xCF); // Code segment, kernel mode
    gdt_set_gate(2, 0, 0xFFFFFFFF, 0x92, 0xCF); // Data segment, kernel mode

    __asm_gdt_flush((unsigned int)&gdt_ptr);
}


static void gdt_set_gate(int num, unsigned int base, unsigned int limit, 
                         unsigned char access, unsigned char granularity) {

    gdt_entries[num].base_low     = (base & 0xFFFF);
    gdt_entries[num].base_middle  = (base >> 16) & 0xFF;
    gdt_entries[num].base_high    = (base >> 24) & 0xFF;

    gdt_entries[num].limit_low   = (limit & 0xFFFF);
    gdt_entries[num].granularity = (limit >> 16) & 0x0F;

    gdt_entries[num].granularity |= granularity & 0xF0;
    gdt_entries[num].access      = access;
}
