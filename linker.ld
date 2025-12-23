ENTRY(_start)

MEMORY {
    FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 16K
    RAM (rwx)  : ORIGIN = 0x20000000, LENGTH = 2K
}

SECTIONS {
    .text : {
        KEEP(*(.text.entry))
        *(.text*)
    } > FLASH

    .rodata :
    {
        *(.rodata*)
    } > FLASH

    .data :
    {
        *(.data*)
    } > RAM AT > FLASH

    .bss :
    {
        *(.bss*)
    } > RAM
}
