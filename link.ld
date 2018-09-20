ENTRY(loader)

SECTIONS {
    . = 0x00100000; /* code loaded at 1mb */
    
    .text ALIGN (0x1000) : /* align at 4kb */
    {
        *(.text)            /* all text sections from all files */
    }

    .rodata ALIGN (0x1000) :
    {
        *(.rodata*)         /* all read only sections from all files */
    }

    .data ALIGN (0x1000) :
    {
        *(.data)
    }

    .bss ALIGN (0x1000) :
    {
        *(COMMON)
        *(.bss)
    }
}
