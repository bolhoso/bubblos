#ifndef INCLUDE_IO_H
#define INCLUDE_IO_H

/**
 * Sends a given data to a given IO port. Defined in io.s
 */
void outb(unsigned short port, unsigned char data);

#endif
