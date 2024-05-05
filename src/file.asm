; open file
; input: filename at EAX
; output: file descriptor at EAX
openf:
    push ebx
    push ecx
    push edx

    ; open
    mov ecx, 0 ; readonly 
    mov ebx, eax ; filename
    mov eax, 5 ; sys_open
    int 0x80

    pop edx
    pop ecx
    pop ebx
    
    ret

; closes the file in EAX
; input: file descriptor at EAX
closef:
    push ebx

    ; close
    mov ebx, eax ; file descriptor
    mov eax, 6 ; sys_close
    int 0x80

    pop ebx

    ret

; file length
; input: file descriptor at EAX
; output: file length at EAX
lengthf:
    push ebx
    push ecx
    push edx

    ; lseek
    mov ebx, eax ; file descriptor
    mov ecx, 0 ; offset
    mov edx, 2 ; SEEK_END
    mov eax, 19 ; sys_lseek
    int 0x80

    push eax ; length

    ; restore lseek
    mov ecx, 0 ; offset
    mov edx, 0 ; SEEK_SET
    mov eax, 19 ; sys_lseek
    int 0x80

    pop eax

    pop edx
    pop ecx
    pop ebx

    ret