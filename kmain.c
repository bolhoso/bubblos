void kprintf(char*);

void k_main() {
    char *vidmem = (char *) 0xb8000;
    for (int i = 0; i < 80 * 25 * 2; i++) {
        vidmem[i] = ' ';
    }

    kprintf("hello world!");
}

void kprintf (char *str) {
    char *vidmem = (char *) 0xb8000;
    int i = 0;
    while (*str) {
        vidmem[(5+i)*10] = *str;
        i++;
        str++;
    }
}
