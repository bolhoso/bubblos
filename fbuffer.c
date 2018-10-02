#include "fbuffer.h"
#include "io.h"

#define GENCOLOR(fg,bg) ((bg&0x0F)<<12)|((fg&0x0F)<<8)
#define YX_ADDR(y,x) (y * 80 + x)
#define MKCHAR(c,fg,bg) (c & 0xFF) | GENCOLOR(fg, bg)

#define FB_DEFAULT_FG LIGHT_GREY
#define FB_DEFAULT_BG BLACK

void _set_vidmem(char c, ushort row, ushort col, char fg, char bg);
void _set_vidmem_byte(ushort char_byte, ushort row, ushort col);
ushort _get_vidmem(ushort row, ushort col);
void _reset_cursor();
void _scroll_lines();

static unsigned char _cur_x;
static unsigned char _cur_y;
static unsigned char _fg;
static unsigned char _bg;

void fb_init() {
    _reset_cursor();

    _fg = FB_DEFAULT_FG;
    _bg = FB_DEFAULT_BG;
}

void fb_putchar(char c) {
    // Carriage return & form feed handling
    if (c == '\r' || c == '\n' || c == '\f') {
        _cur_x = 0;

        if (c == '\n' || c == '\f') {
            _cur_y++;
        }

        return;
    }

    // Scroll all lines
    if (_cur_y >= FB_NUM_ROWS) {
        _scroll_lines();
        _cur_y = FB_NUM_ROWS - 1;
    }
    _set_vidmem(c, _cur_y, _cur_x, _fg, _bg);

    _cur_x = (_cur_x + 1) % FB_NUM_COLS;
    if (_cur_x == 0) {
        _cur_y++;
    }

    fb_gotoxy(_cur_y, _cur_x);
}

void _scroll_lines() {
    // move all lines one up, from top to bottom
    for (int line = 0; line < FB_NUM_ROWS - 1; line++) {
        for (int col = 0; col < FB_NUM_COLS; col++) {
            ushort c = _get_vidmem(line + 1, col);
            _set_vidmem_byte(c, line, col);
        }
    }

    // clear the last line
    for (int i = 0; i < FB_NUM_COLS; i++) {
        _set_vidmem(' ', FB_NUM_ROWS - 1, i, FB_DEFAULT_FG, FB_DEFAULT_BG);
    }
}

void fb_setcolor(unsigned char fg, unsigned char bg) {
    _fg = fg;
    _bg = bg;
}

void fb_write(char *str) {
    while (*str) {
        fb_putchar(*str++);
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
void fb_gotoxy(ushort row, ushort col) {
    ushort pos = YX_ADDR(row, col);

    outb(FB_COMMAND_PORT, FB_HIGH_BYTE_COMMAND);
    outb(FB_DATA_PORT,    ((pos >> 8) & 0x00FF));
    outb(FB_COMMAND_PORT, FB_LOW_BYTE_COMMAND);
    outb(FB_DATA_PORT,    (pos & 0x00FF));

    _cur_y = row;
    _cur_x = col;
}

void fb_clearscreen() {
    _reset_cursor();

    for (int x = 0; x < FB_NUM_COLS; x++) {
        for (int y = 0; y < FB_NUM_ROWS; y++) {
            _set_vidmem(' ', y, x, _fg, _bg);
        }
    }
}

void _reset_cursor() {
    fb_gotoxy(0, 0);
}

inline void _set_vidmem_byte(ushort char_byte, ushort row, ushort col) {
    ushort *vidmem = (ushort *) 0x00B8000;
    vidmem[YX_ADDR(row, col)] = char_byte;
}

inline void _set_vidmem(char c, ushort row, ushort col, char fg, char bg) {
    ushort *vidmem = (ushort *) 0x00B8000;

    ushort mem_char = MKCHAR(c, fg, bg);
    vidmem[YX_ADDR(row, col)] = mem_char;
}

inline ushort _get_vidmem(ushort row, ushort col) {
    ushort *vidmem = (ushort *) 0x00B8000;
    return vidmem[YX_ADDR(row, col)];
}
