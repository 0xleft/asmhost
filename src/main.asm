%include "utils.asm"
%include "file.asm"
%include "responses.asm"

SECTION .data
BUFFER_SIZE equ 1024

; for sending files

indexFilename db 'index.html', 0h
indexFilenameLength equ $ - indexFilename
failedToBindErrorString db 'Failed to bind', 0h
number404 db '404', 0h
intro db 'Listening on port ', 0h
defaultIntro db 'Listening on port 9001', 0h
badPort db 'Invalid port', 0h

number200 db '200', 0h
number400 db '400', 0h
space db ' ', 0h

logLine db '/', 0h
logLineLength equ $ - logLine

newline db 0Ah, 0h
newlineLength equ $ - newline

SECTION .bss
requestBuffer resb 1024, ; for request
requestFilename resb 1024,
fileBuffer resb BUFFER_SIZE, ; for file content
lengthBufferLength resb 4, ; for length buffer

SECTION .text
global _start


_start:
	xor eax, eax ; init
	xor ebx, ebx
	xor edi, edi
	xor esi, esi

_socket:
    push byte 6
    push byte 1
    push byte 2
    mov ecx, esp
    mov ebx, 1 ; socket subroutine
    mov eax, 102
    int 0x80

    pop ebx
    pop ebx
    pop ebx

    cmp eax, 0 ; check if the socket was created
    jl .error

    jmp _bind

.error:
    mov eax, failedToBindErrorString
    call sprint
    call quit

_bind:
    pop ecx ; argc

    cmp ecx, 2 ; check if there is an argument
    je .nonDefaultPort ; if there is

    jmp .defaultPort ; if there isn't

.nonDefaultPort:
    pop edx ; get the port
    pop edx
    push eax ; save the socket descriptor
    mov eax, intro
    call sprint
    mov eax, edx ; move the port into eax
    call sprint
    mov eax, newline
    call sprint
    mov ebx, edx ; move the port into eax
    call atoi
    cmp eax, 0
    jl .badPort
    cmp eax, 65535
    jg .badPort

    jmp .goodPort

.badPort:
    mov eax, badPort
    call sprint
    mov eax, newline
    call sprint
    call quit

.goodPort:
    pop edx ; restore the socket descriptor

    mov edi, edx ; move the socket descriptor into edi
    push dword 0x00000000 ;
    rol ax, 8 ; swap the lower bytes
    push word ax ; push the port
    push word 2
    mov ecx, esp
    push byte 16
    push ecx
    push edi
    mov ecx, esp
    mov ebx, 2 ; bind subroutine
    mov eax, 102
    int 0x80
    
    jmp _listen

.defaultPort:
    push eax ; save the socket descriptor
    mov eax, defaultIntro
    call sprint
    mov eax, newline
    call sprint
    pop eax
    mov     edi, eax ;
    push    dword 0x00000000 ; 0.0.0.0
    push    word 0x2923 ; port 9001
    push    word 2
    mov     ecx, esp
    push    byte 16
    push    ecx ; pointer to the sockaddr_in struct
    push    edi
    mov     ecx, esp
    mov     ebx, 2 ; bind subroutine
    mov     eax, 102
    int     0x80

_listen:
 
    push    byte 1
    push    edi
    mov     ecx, esp
    mov     ebx, 4 ; listen subroutine
    mov     eax, 102
    int     0x80

_accept:
	push byte 0
	push byte 0
	push edi
	mov ecx, esp
	mov ebx, 5 ; accept subroutine
	mov eax, 102 ; syscall
	int 0x80

_fork:
    mov esi, eax
    mov eax, 2
    int 0x80
    cmp eax, 0 ; if child then jump to _read
    jz _read

	jmp _accept ; go back

_read:
    mov edx, 1024 ; number of bytes to read
    mov ecx, requestBuffer
    mov ebx, esi ; move esi into ebx (accepted socket file descriptor)
    mov eax, 3 ; read subroutine
    int 0x80

    mov eax, requestBuffer
    xor edx, edx ; letter counter
    xor edi, edi ; space counter

; to find the space and fill the requestFilename with the filename which is the second word in the requestBuffer
.parseloop:
    cmp edi, 0 ; if have 0 spaces
    je .normal

    cmp byte [eax], 0x2F
    je .firstslash

    ; if its a newline
    cmp byte [eax], 0x0A
    je .foundname ; jump to foundname
    
    cmp byte [eax], 0x0D
    je .foundname ; jump to foundname

    cmp byte [eax], 0x20 ; check if it's a space
    jne .add ; if it's not a space, jump to add

    jmp .normal

.firstslash:
    cmp edx, 0
    jne .add

    jmp .normal

.add:
    push ebx
    mov bl, [eax] ; move the byte into ebx
    mov byte [requestFilename + edx], bl
    pop ebx
    
    inc edx ; add 1 to the counter
.normal:
    cmp byte [eax], 0x0 ; get the byte at the pointer + counter
    je .foundname ; if it is, we're done

    cmp byte [eax], 0x20 ; check if it's a space
    je .foundspace ; if its a space, jump to foundspace

    inc eax ; add 1 to the counter
    jmp .parseloop ; loop again
    
.foundspace:
    cmp edi, 1
    je .foundname ; if we have 2 spaces, we're done

    inc edi ; add 1 to the space counter
    inc eax ; add 1 to the counter
    jmp .parseloop ; loop again

.foundname:
    ; ; null terminate the requestFilename
    mov byte [requestFilename + edx], 0x0
    mov eax, requestFilename
    
_checkfilename:
    xor edx, edx ; clear edx

.loop:
    cmp byte [eax + edx], 0x0
    je .continueFilename

    cmp byte [eax + edx], 0x2E ; check if contains .
    je .dotMaybeInvalid

    cmp byte [eax + edx], 0x7E ; check if contains ~ because we dont want to allow it initially but later on its ok
    je .tildaMaybeInvalid

    ; check if it is ascii
    cmp byte [eax + edx], 0x20 ; ascii bottom
    jl _invalidRequest

    cmp byte [eax + edx], 0x7E ; ascii top
    jg _invalidRequest

    inc edx
    jmp .loop

.dotMaybeInvalid:
    cmp byte [eax + edx + 1], 0x2E ; front
    je _invalidRequest

    cmp byte [eax + edx - 1], 0x2E ; back
    je _invalidRequest

    inc edx
    jmp .loop

.tildaMaybeInvalid:
    cmp edx, 0
    je _invalidRequest

    inc edx
    jmp .loop

.continueFilename:
    cmp byte [eax], 0x0 ; if the filename is empty
    je .emptyfilename ; jump to emptyfilename

    jmp _sendfile ; jump to sendfile

.emptyfilename:
    mov eax, indexFilename
    jmp _sendfile

    ; debug
    ;call sprint

_sendfile:
    ; ebx now holds the socket file descriptor
    push ebx
    push eax

    ; open the file
    mov ecx, 0 ; readonly
    mov ebx, eax ; filename
    mov eax, 5 ; sys_open
    int 0x80

    cmp eax, 0
    jl .fileNotFound
    mov edx, eax ; file descriptor

    pop eax
    ; log the request
    push eax
    mov eax, logLine
    call sprint
    pop eax
    push eax
    call sprint
    mov eax, space
    call sprint
    mov eax, number200; 200
    call sprint
    mov eax, newline
    call sprint
    pop eax

    mov eax, edx ; file descriptor

    pop ebx
    call _writeResponseStart
    push ebx

    push eax
    call lengthf
    call sendi
    pop eax

    pop ebx
    call _writeResponseMiddle
    push ebx

    mov ebx, eax ; file descriptor
    xor ecx, ecx


; read file in a loop until the end of the file by storing the file content in fileBuffer and readsize to ecx
; no using external function to read the file
.readfile:
    push ecx ; save the file content size to ecx

	mov edx, BUFFER_SIZE
    mov ecx, fileBuffer
    mov eax, 3 ; read syscall
    int 0x80

    pop ecx ; restore the file content size to ecx
    add ecx, eax ; add the readsize to the file content size
    cmp eax, 0 ; if the readsize is 0, then it is the end of the file
    je .endreadfile ; jump to endreadfile

    ; ecx -> what we have read so far
    ; ebx -> file descriptor
    ; top of the stack -> socket file descriptor

    mov edx, eax ; file content size

    pop eax ; socket dc
    push ebx ; file dc

    push ecx

    mov ebx, eax ; socket file descriptor
    mov ecx, fileBuffer ; file content
    call _commitWrite

    pop ecx
    
    pop eax
    push ebx
    mov ebx, eax

    mov eax, edx ; readsize
    mov edx, 0 ; SEEK_SET
    mov eax, 19 ; sys_lseek
    int 0x80

    push ecx ; save the file content size to ecx

    ; clear fileBuffer
    mov edi, fileBuffer
    mov ecx, BUFFER_SIZE
    xor eax, eax
    rep stosb ; clear the fileBuffer

    pop ecx ; restore the file content size to ecx

	jmp .readfile ; jump to readfile

.endreadfile:
	mov eax, ebx ; file descriptor
	call closef ; close the file

    jmp _close

.fileNotFound:
    pop eax
    ; log the request
    push eax
    mov eax, logLine
    call sprint
    pop eax
    push eax
    call sprint
    mov eax, space
    call sprint
    mov eax, number404
    call sprint
    mov eax, newline
    call sprint
    pop eax

    pop ebx
    call _writeResponse404
    jmp _close.main

_invalidRequest:
    mov eax, logLine
    call sprint
    mov eax, requestFilename
    call sprint
    mov eax, space
    call sprint
    mov eax, number400
    call sprint
    mov eax, newline
    call sprint

    call _writeResponse400
    jmp _close.main

_close:
    pop ebx ; socket file descriptor

.main:

    ; send a few newlines
    mov ecx, newline
    mov edx, 1
    call _commitWrite
    call _commitWrite
    call _commitWrite
    call _commitWrite

    mov eax, 48
    mov ecx, 2
    int 0x80
    
    mov eax, 6
    int 0x80

	call quit