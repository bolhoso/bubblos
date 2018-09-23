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

void init_fbuffer();
void setcolor(char fg, char bg);
void clearscreen();

void putc(char c);
void kputs(char *str);

#endif
