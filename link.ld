ENTRY(loader)

SECTIONS {
    . = 1M; /* code loaded at 1MiB, conventional place for kernels to be loaded */
    
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
}
