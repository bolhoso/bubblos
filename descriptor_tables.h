#ifndef INCLUDE_DESCRIPTOR_TABLES_H
#define INCLUDE_DESCRIPTOR_TABLES_H

// This structure contains the value of one GDT entry.
// We use the attribute 'packed' to tell GCC not to change
// any of the alignment in the structure.
// Access Byte format: P(1), DPL(2), DT(1), TYPE(4)
// Granularity Byte format: G(1), D(1), 0, A(1), Segment Length(4)
struct gdt_entry_struct {
   unsigned short limit_low;           // The lower 16 bits of the limit.

   unsigned short base_low;            // The lower 16 bits of the base.
   unsigned char  base_middle;         // The next 8 bits of the base.
   unsigned char  access;              // Access flags, determine ring this segment can be used in.
   unsigned char  granularity;
   unsigned char  base_high;           // The last 8 bits of the base.
} __attribute__((packed));
typedef struct gdt_entry_struct gdt_entry_t;

struct gdt_ptr_struct {
    unsigned short limit;
    unsigned int base;
} __attribute__((packed));
typedef struct gdt_ptr_struct gdt_ptr_t;

// defined in loader.s
extern void __asm_gdt_flush(unsigned int);

// GDT public initialization function
void init_descriptor_tables();

#endif
