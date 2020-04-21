#include "fbuffer.h"
#include "mem.h"
#include "descriptor_tables.h"
#include "idt.h"
#include "isr_handlers.h"

void screen_test();
void delay(int millis);

void check_a20() {
    fb_write("Checking A20 register is on...");
    asm_is_A20_on() ? fb_write("OK!\n") : fb_write("off\n");

    // TODO: how to turn A20 on on my own bootloader
}

void init_interrupts() {
    fb_write("Enabling IRQs...");
    // TODO: IDT is messing with screen driver idt_install();
    fb_write("OK!\n" );

    fb_write("Installing IRQ handlers...");
    isr_install();
    fb_write("OK!\n" );
}

void check_cpuid() {
    fb_write("Checking CPUID support...");
	if (!asm_check_cpuid()) {
		fb_write("Not supported! Halting");
		asm_halt_processor(); 
	} 
	fb_write("OK!\n");
}

void enable_long_mode() {
    fb_write("Checking long-mode supported...");
	if (!asm_check_long_mode()) {
		fb_write("Not supported! Halting");
		asm_halt_processor();
	}
	fb_write("OK!\n");
}


void init_cpuid() {
	fb_write("Checking CPU capabilities\n");

    check_a20();
    check_cpuid();
    // 32 bits for now:    enable_long_mode();
}

void kmain() {
    init_descriptor_tables();

    fb_init();
    fb_clearscreen();
		fb_write("Welcome to Bubblos 0.00000001\n");
    delay(500);


    init_interrupts();
		init_cpuid();

    screen_test();
    while(1);
}

/* Test filling the whole screen plus scroll */
void screen_test() {
		fb_write("we'll test the screen....");
    delay(500);
		fb_clearscreen();
    
    fb_setcolor(RED, LIGHT_GREEN);
    for (int i = 0; i < 25; i++) {
        for (int j = 0; j < 80; j++) {
            fb_putchar('0' + i % 10);
        }
    }

    delay(1000);

    // now the scroll!
    fb_write("And here we scroll\n2 lines!\n");
    fb_write("and a very long line 111111111111111111111111111111111111111111111111111111111111");
}

void delay(int millis) {
    for (int i = 0; i < 5*millis; i++) {
        for (int j = 0; j < 32767; j++) { }
    }
}
