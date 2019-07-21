#include "idt.h"
#include "isr_handlers.h"
#include "fbuffer.h"

// TODO: why char *exception_messages[] = { "...", ""} doesn't work?
char exception_messages[256][50] = {
    "Division By 0",   
};

void isr_install() {
    idt_set_gate(0, (unsigned)__asm_isr0, 0x08, 0x8E);
    // TOOD: all the 32 interrupts
}

void _fault_handler(struct regs *r) {
    if (r->int_no < 32) {
        char *msg = "Interrupt X triggered: ";
        msg[10] = '0' + r->int_no; // TODO: I still don't have printf, nor strcat :/

        fb_write(msg);
        fb_write(exception_messages[r->int_no]);
        for(;;); // TODO halt the OS
    }
}
