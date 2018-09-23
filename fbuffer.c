#include "fbuffer.h"
#include "io.h"

#define GENCOLOR(fg,bg) ((bg&0x0F)<<12)|((fg&0x0F)<<8)
#define YX_ADDR(y,x) (y * 80 + x)
#define MKCHAR(c,fg,bg) (c & 0xFF) | GENCOLOR(fg, bg)

void _set_vidmem(char c, char col, char row);
void _reset_cursor();

static int _cur_x;
static int _cur_y;
static int _fg;
static int _bg;

void init_fbuffer() {
    _reset_cursor();

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
    // put character and move cursor forward
    _set_vidmem(c, _cur_y, _cur_x);
    if (_cur_y > FB_NUM_ROWS) {
        _cur_y = FB_NUM_ROWS - 1;
    }

    _cur_x = (_cur_x + 1) % FB_NUM_COLS;
    if (_cur_x == 0) {
        _cur_y++;
    }

    setxy(_cur_y, _cur_x);
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

/**
 * Moving the cursor of the framebuffer is done via two different I/O ports. 
 * The cursor’s position is determined with a 16 bits integer: 0 means row zero,
 * column zero; 1 means row zero, column one; 80 means row one, column zero and 
 * so on. Since the position is 16 bits large, and the out assembly code 
 * instruction argument is 8 bits, the position must be sent in two turns, first 
 * 8 bits then the next 8 bits.
 */
void setxy (unsigned short row, unsigned short col) {
    unsigned short pos = YX_ADDR(row, col);

    outb(FB_COMMAND_PORT, FB_HIGH_BYTE_COMMAND);
    outb(FB_DATA_PORT,    ((pos >> 8) & 0x00FF));
    outb(FB_COMMAND_PORT, FB_LOW_BYTE_COMMAND);
    outb(FB_DATA_PORT,    (pos & 0x00FF));

    _cur_y = row;
    _cur_x = col;
}

void clearscreen() {
    _reset_cursor();

    for (int x = 0; x < FB_NUM_COLS; x++) {
        for (int y = 0; y < FB_NUM_ROWS; y++) {
            _set_vidmem(' ', y, x);
        }
    }
}

void _reset_cursor() {
    setxy(0, 0);
}

void _set_vidmem(char c, char row, char col) {
    unsigned short *vidmem = (unsigned short *) 0x00B8000;

    unsigned short mem_char = MKCHAR(c, _fg, _bg);
    vidmem[YX_ADDR(row, col)] = mem_char;
}
