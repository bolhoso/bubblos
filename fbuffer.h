#ifndef _FBUFFER_H
#define _FBUFFER_H

/*
Bit: | 15 14 13 12 11 10 9 8 | 7 6 5 4 | 3 2 1 0 |
     | ASCII                 | FG      | BG      |
*/
#define BLACK         0
#define RED           4
#define DARK_GREY     8
#define LIGHT_RED     12
#define BLUE          1
#define MAGENTA       5
#define LIGHT_BLUE    9
#define LIGHT_MAGENTA 13
#define GREEN         2
#define BROWN         6
#define LIGHT_GREEN   10
#define LIGHT_BROWN   14
#define CYAN          3
#define LIGHT_GREY    7
#define LIGHT_CYAN    11
#define WHITE         15

// framebuffer size
#define FB_NUM_COLS 80
#define FB_NUM_ROWS 25 

// IO Ports for framebuffer
#define FB_COMMAND_PORT      0x3D4
#define FB_DATA_PORT         0x3D5

// IO Ports commands
#define FB_HIGH_BYTE_COMMAND 14
#define FB_LOW_BYTE_COMMAND  15

typedef unsigned short ushort;

void fb_init();
void fb_setcolor(unsigned char fg, unsigned char bg);

void fb_clearscreen();
void fb_gotoxy (ushort row, ushort col);

void fb_putchar(char c);
void fb_write(char *str);

#endif
