#include "fbuffer.h"

void screen_test();

void k_main() {
    fb_init();
    fb_clearscreen();

    screen_test();
}

/* Test filling the whole screen plus scroll */
void screen_test() {
    fb_setcolor(RED, LIGHT_GREEN);
    for (int i = 0; i < 25; i++) {
        for (int j = 0; j < 80; j++) {
            fb_putchar('0' + i % 10);
        }
    }

    // delay of 2 seconds
    for (int i = 0; i < 10000; i++) {
        for (int j = 0; j < 32767; j++) { }
    }

    // now the scroll!
    fb_write("And here we scroll\n2 lines!\n");
    fb_write("and a very long line 111111111111111111111111111111111111111111111111111111111111");
}
