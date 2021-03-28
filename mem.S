global asm_check_cpuid
global asm_check_long_mode
global asm_halt_processor
global asm_is_A20_on

asm_check_cpuid:
  pushfd        ; Save original EFLAGS

  pushfd        ; Store EFLAGS -> stack
  xor dword [esp], 0x00200000  ; Invert the ID bit in EFLAGS (bit 22), at top of stack
  popfd        ; Load stored eflags with ID bit inverted

  pushfd         ; Store it again, so that we see if the bit was modified
  pop eax        ; Get modified eflags into EAX to test for CPUID
  xor eax, [esp] ; check for CPU ID bit from the original eflags

  popfd        ; restore original EFLAGS
  and eax, 0x00200000    ; eax == 0 if ID bit can't be changed
  ret
  
asm_halt_processor:
  hlt

asm_check_long_mode:
    mov eax, 0x80000001    ; Set the A-register to 0x80000001.
    cpuid                  ; CPU identification.
    test edx, 1 << 29      ; Test if the LM-bit, which is bit 29, is set in the D-register.
    jz NoLongMode          ; They aren't, there is no long mode.
  mov eax, 1
  ret
NoLongMode:
  mov eax, 0
  ret

; Check A20 line
; Returns to caller if A20 gate is cleared.
; Continues to A20_on if A20 line is set.
; Written by Elad Ashkcenazi 
asm_is_A20_on:   
  pushad
  mov edi,0x112345  ;odd megabyte address.
  mov esi,0x012345  ;even megabyte address.
  mov [esi],esi     ;making sure that both addresses contain diffrent values.
  mov [edi],edi     ;(if A20 line is cleared the two pointers would point to the address 0x012345 that would contain 0x112345 (edi)) 
  cmpsd             ;compare addresses to see if the're equivalent.
  popad
  jne A20_on        ;if not equivalent , A20 line is set.
    mov eax, 0
  ret               ;if equivalent , the A20 line is cleared.
   
  A20_on:
  mov eax, 1
    ret
