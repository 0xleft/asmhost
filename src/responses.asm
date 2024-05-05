SECTION .data
; if not found
response404 db 'HTTP/1.1 404 Not Found', 0Ah, 'Content-Type: text/html', 0Ah, 'Content-Length: 14', 0Ah, 0Ah, '404 Not Found', 0Ah
response404Len equ $ - response404

response400 db 'HTTP/1.1 400 Bad Request', 0Ah, 'Content-Type: text/html', 0Ah, 'Content-Length: 16', 0Ah, 0Ah, '400 Bad Request', 0Ah
response400Len equ $ - response400

responseStart db 'HTTP/1.1 200 OK', 0Ah, 'Content-Type: text/html', 0Ah, 'Content-Length: '
responseStartLength equ $ - responseStart
responseMiddle db '', 0Ah, 0Ah
responseMiddleLength equ $ - responseMiddle

_writeResponse400:
    push ecx
    push edx
    push eax

    mov edx, response400Len
    mov ecx, response400
    mov eax, 4
    int 0x80

    pop eax
    pop edx
    pop ecx

    ret

_writeResponseStart:
    push ecx
    push edx
    push eax

    mov edx, responseStartLength
    mov ecx, responseStart
    mov eax, 4
    int 0x80

    pop eax
    pop edx
    pop ecx

    ret

_writeResponseMiddle:
    push ecx
    push edx
    push eax

    mov edx, responseMiddleLength
    mov ecx, responseMiddle
    mov eax, 4
    int 0x80

    pop eax
    pop edx
    pop ecx

    ret

; socket descriptor is expected to be in ebx
; length of the buffer is expected to be in edx
; buffer is expected to be in ecx
_commitWrite:
    mov eax, 4
    int 0x80
    ret

; socket descriptor is expected to be in ebx
_writeResponse404:
    push ecx
    push edx
    push eax

    mov edx, response404Len
    mov ecx, response404
    mov eax, 4
    int 0x80
    
    pop eax
    pop edx
    pop ecx
    
    ret