#include "fbuffer.h"

void k_main() {
    init_fbuffer();
    setcolor(RED, LIGHT_GREEN);
    kputs("Hello\nworld!");
}
