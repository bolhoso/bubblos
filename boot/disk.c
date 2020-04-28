// https://wiki.osdev.org/ATA_read/write_sectors
// https://wiki.osdev.org/ATA_PIO_Mode
// /home/bolhoso/sandbox/example-os/xv6-public/bootmain.c

typedef unsigned char uchar;

static inline uchar inb(int port) {
	uchar data;
	asm volatile("in %1,%0": "=a" (data) : "d" (port));
	return data;
}

static inline void insw(int port, void *buffer, int count) {
	// rep insw => read CX times from port DX into [ES:DI] memory
	asm volatile("rep insw": 
			"=D" (buffer), "=c" (count) :
			"d" (port), "0" (buffer), "1" (count) :
			"memory", "cc");
}

static inline void outb(int port, uchar data) {
	asm volatile("out %0,%1": : "a" (data), "d" (port));
}

void waitdisk() {
	while ((inb(0x1F7) & 0xC0) != 0x40)
		;
	
}

void read_sector(void *dst, int lba) {
	uchar sector_count = 1;

	// Send the read command
	waitdisk();
	outb(0x1F6, 0xE0 | ((lba >> 24) & 0x0F)); // Send 0xE0 for the "master" or 0xF0 for the "slave", ORed with the highest 4 bits of the LBA to port 0x1F6
	outb(0x1F1, 0x0);						// sends nulls bite
	outb(0x1F2, sector_count);	// sends sector count to 0x1F2
	outb(0x1F3, (uchar) lba);						// low 8 bits of LBA to 0x1F3
	outb(0x1F4, (uchar) (lba >> 8));		// next 8 bits of LBA to 0x1F3
	outb(0x1F5, (uchar) (lba >> 16));		// next 8 bits of LBA to 0x1F3
	outb(0x1F7, 0x20);									// send READ SECTOR (0x20) command on control port 0x1F7

	// Wait for disk to be ready and read bytes from bus
	waitdisk();
	insw(0x1F0, dst, 256); // Transfer 256 * 16bits (512 bytes) from port 0x1F0
}

void stage2_main() {
	// TODO: what if the kernel changes size? I need to pass the kernel image size as a -D flag
	for (int i = 0; i < 42; i++) {
		read_sector ((void *)(0x100000+512*i), 6 + i);
	}

//	void (*kernel_entry)(void);
//	kernel_entry = (void(*)(void))(0x100000);
//	kernel_entry();
}
