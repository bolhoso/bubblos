.code16
.intel_syntax noprefix
.text
.org 0x0
.align 512

# Entry point, should be the first instruction at 0x9000
jmp stage1_bootloader

##################
# GDT Definition #
##################
gdt_start:

gdt_null:				# Mandatory null descriptor
	.int 0x0
	.int 0x0

gdt_code:				# Code segment descriptor
	# Base=0x0, limit=0xFFFFF, with granularity=1 limits x 16^3 which extends to 4gb
	# 1st flags:	(present)1 (privilege)00 (descriptor type)1 -> 1001b
	# Type flags:	(code)1 (conforming)0 (readable)1 (accessed)0 -> 1010b
	# 2nd flags:	(granularity)1 (32bit default)1 (64bit seg)0 (avl)0 -> 1100b
	.word	0xffff			# Limit (bits 0-15)
	.word	0x0					# Base (bits 0-15)
	.byte	0x0					# Base (bits 16-23)
	.byte 0b10011010		# 1st Flags, type flags
	.byte	0b11001111		# 2nd Flags, Limit (bits 16-19)
	.byte	0x0					# Base (bits 24-31)

gdt_data:
	# Define a segment similar to code, overlapping at the 4gb except for type flags
	# Type flags:	(code)0 (expand down)0 (writable)1 (accessed)0 -> 0010b 
	.word	0xffff			# Limit (bits 0-15)
	.word	0x0					# Base (bits 0-15)
	.byte	0x0					# Base (bits 16-23)
	.byte 0b10010010	# 1st Flags, type flags
	.byte	0b11001111	# 2nd Flags, Limit (bits 16-19)
	.byte	0x0					# Base (bits 24-31)

gdt_end:					# We label the end of GDT, so that AS can calculate
									# The size of the GDT for the descriptor below in compile time

##################
# GDT Descriptor #
##################
gdt_descriptor:
	.word	gdt_end - gdt_start - 1	# Size of GDT, minus 1 of the true size (why!?)
	.int	gdt_start								# Start address of GDT, 32bits

# Define some handy constants for the GDT segment descriptor offsets , which
# are what segment registers must contain when in protected mode. For example ,
# when we set DS = 0x10 in PM , the CPU knows that we mean it to use the
# segment described at offset 0x10 ( i.e. 16 bytes ) in our GDT , which in our
# case is the DATA segment (0x0 -> NULL ; 0x08 -> CODE ; 0x10 -> DATA )
.equ CODE_SEG, gdt_code - gdt_start
.equ DATA_SEG, gdt_data - gdt_start
.asciz "AAAAA"


#
# switch_to_protected_mode
#
# Load the 3 GDT entries (null, code, data segment) as a flat memory model and put the 
# processor into 32bit mode
#
.func switch_to_protected_mode
switch_to_protected_mode:
	cli						# turn off interrupts until the kernel sets the Interrupt Vector Handler 

	# Load the GDT using the descriptor (which points to the actual GDT)
	lgdt [gdt_descriptor]

	# Now, tell the processor to go to 32bit mode. Oh man... it's coming!
	mov eax, cr0	# To make the switch, we set bit 0 in CR0 to 1, which intel
	or	eax, 0x1	# tells that the 32bit bit :)
	mov cr0, eax

	# And we do a far jump, so that CPU clear all the pipeline stuff, flush caches
	# of pre-fetched instructions and real mode (16bit) instructions
  # load the code below
	jmp CODE_SEG:start_protected_mode


# here it comes! 32bits!
.code32
start_protected_mode:
	mov ax, DATA_SEG		# Now, let's setup our data and code segments again
	mov	ds, ax					# all based on the GDT segments we defined above
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ebp, 0x90000		# Update the stack TODO: is this the right position?
	mov esp, ebp

	xchg bx, bx

testa20:
  # Test A20 register by setting two different values at an odd and even
  # memory position, then comparing. If A20 is off, both will address to
  # the same location and therefore will be equal. In this case, we try 
  # turning A20 on and loop back to the test again
	mov edi, 0x112345
	mov esi, 0x012345
	mov [esi], esi
	mov [edi], edi
	cmpsd
	je A20_off

  lea ebx, MSG_PROTECTED_MODE
	call print_String_pm
	jmp a20on
	
A20_off:
  lea ebx, MSG_A20_NOTENABLED
	call print_String_pm
	xchg bx, bx

	jmp .

 	in al, 0x92
  or al, 2
  out 0x92, al

	jmp testa20 

a20on:
	# A20 is on, call the kernel
	call kmain
	ret

.endfunc

.func print_String_pm
print_String_pm:
	pusha
	mov edx, 0xb8000

print_pm_loop:
	mov al, [ebx]
	mov ah, 0x0f # White on black

	cmp al, 0
	je done

	mov [edx], ax
	add ebx, 1
	add edx, 2

	jmp print_pm_loop

done: 
	popa
	ret

.endfunc

#
# stage1_bootloader
#
# Entry point running in REAL MODE that will make the switch to 32 bits, set the GDT
# and turn A20 on 
#
# TODO: The A20 is a huge workaround, bogus code for now
# TODO: we're still missing a bunch of other checks and loads coming from NOTES.TXT
#
.code16
stage1_bootloader:
	# TODO: do I need to setup a new stack in here?

	call switch_to_protected_mode

	ret

# Data
.data
MSG_PROTECTED_MODE: .asciz "Welcome to protected mode!"
MSG_A20_NOTENABLED: .asciz "A20 not enabled :("
.asciz "END STAGE1"

.section .textend
.align 512, 0
