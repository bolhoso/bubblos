#!/bin/bash

make all
exec qemu-system-i386 -s -S --cdrom os.iso
