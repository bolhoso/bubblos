ENTRY(loader)

SECTIONS {
    . = 0x9000; /* bootloader cdoe location, see loader.S for the mem organization */
    
    /* First the multiboot header in the beggining of the kernle file */
    .text ALIGN (4K) :
    {
        *(.text)            /* all text sections from all files */
    }

    .rodata ALIGN (4K) :
    {
        *(.rodata*)         /* all read only sections from all files */
    }

    .data ALIGN (4K) :
    {
        *(.data)
    }

    .bss ALIGN (4K) :
    {
        *(COMMON)
        *(.bss)
    }

    /* First the multiboot header in the beggining of the kernle file */
    .text ALIGN (512) :
    {
        *(.text2)            /* all text sections from all files */
    }

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame)
    }
}
