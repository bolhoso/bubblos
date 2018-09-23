#include "fbuffer.h"

#define GENCOLOR(fg,bg) ((bg&0x0F)<<12)|((fg&0x0F)<<8)
#define YX_ADDR(y,x) (y * 80 + x)
#define MKCHAR(c,fg,bg) (c & 0xFF) | GENCOLOR(fg, bg)

void _set_vidmem(char c);

static int _cur_x;
static int _cur_y;
static int _fg;
static int _bg;

void init_fbuffer() {
    _cur_x = 0;
    _cur_y = 0;

    _fg = LIGHT_GREY;
    _bg = BLACK;
}

void putc(char c) {
    // Carriage return & form feed handling
    if (c == '\r' || c == '\n' || c == '\f') {
        _cur_x = 0;

        if (c == '\n' || c == '\f') {
            _cur_y++;
        }

        return;
    }

    // TODO: implement scrolling. For now, avoid writing beyond video
    if (_cur_y > FB_NUM_ROWS) {
        _cur_y = FB_NUM_ROWS - 1;
    }

    _set_vidmem(c);

    // TODO: move cursor one forward
    _cur_x = (_cur_x + 1) % FB_NUM_COLS;
    if (_cur_x == 0) {
        _cur_y++;
    }
}

void setcolor(char fg, char bg) {
    _fg = fg;
    _bg = bg;
}

void kputs (char *str) {
    while (*str) {
        putc(*str++);
    }
}

void _set_vidmem(char c) {
    unsigned short *vidmem = (unsigned short *) 0x00B8000;

    unsigned short mem_char = MKCHAR(c, _fg, _bg);
    vidmem[YX_ADDR(_cur_y, _cur_x)] = mem_char;
}
