#include "fbuffer.h"

void k_main() {
    fb_init();
    fb_clearscreen();

    fb_setcolor(RED, LIGHT_GREEN);

    fb_write("Hello\nworld!");
}
