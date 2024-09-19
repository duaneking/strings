section .data
    buffer_size equ 1024            ; Size of the read buffer
    min_string_length equ 4         ; Minimum length for a valid string
    buffer times buffer_size db 0   ; Buffer for file reading
    newline db 0xA                  ; Newline character (0xA) for Linux
    error_msg db 'Usage: program <filename>', 0xA, 0  ; Error message for invalid usage

section .bss
    fd resd 1                       ; File descriptor
    bytes_read resd 1               ; Bytes read from file
    current_string_length resd 1    ; Length of the current string
    string_start resd 1             ; Start address of current string

section .text
    global _start

_start:
    ; Check if we have the correct number of arguments
    mov eax, [esp]                  ; Get argc from the stack
    cmp eax, 2                      ; We need exactly 2 arguments (program name and filename)
    jne usage_error                 ; If not, jump to usage error

    ; Get the filename from argv[1]
    mov eax, [esp + 4]              ; argv[1] is the second item on the stack (filename)

    ; Open the file using sys_open
    mov ebx, eax                    ; Filename in ebx
    mov eax, 5                      ; sys_open syscall number
    xor ecx, ecx                    ; O_RDONLY (read-only mode)
    int 0x80                        ; Perform syscall
    test eax, eax                   ; Check if file opened successfully
    js file_open_error              ; Jump if an error occurred
    mov [fd], eax                   ; Store the file descriptor

read_loop:
    ; Read data from the file
    mov eax, 3                      ; sys_read syscall number
    mov ebx, [fd]                   ; File descriptor
    mov ecx, buffer                 ; Buffer to store the data
    mov edx, buffer_size            ; Number of bytes to read
    int 0x80                        ; Perform syscall
    test eax, eax                   ; Check for read success
    js read_error                   ; Jump if read failed
    mov [bytes_read], eax           ; Store number of bytes read
    test eax, eax                   ; Check for EOF
    jz close_file                   ; If zero bytes read, close the file

    ; Process the buffer for printable characters
    mov esi, buffer                 ; Start processing the buffer
    mov ecx, [bytes_read]           ; Set loop counter to bytes read
    xor edi, edi                    ; Reset current string length
    xor edx, edx                    ; Reset string start address

find_printable:
    cmp ecx, 0                      ; Check if done processing buffer
    je check_remaining_string       ; If done, check remaining string

    ; Ensure we don't read past the valid buffer range
    mov eax, esi                    ; Load current buffer pointer into eax
    sub eax, buffer                 ; Calculate offset from start of the buffer
    cmp eax, [bytes_read]           ; Compare with the number of bytes read
    jae check_remaining_string      ; If past the buffer, check remaining string

    lodsb                           ; Load byte into AL from buffer (ESI)

    ; Filter only printable ASCII characters (32 to 126)
    cmp al, 32                      ; Check if character is below 32 (non-printable)
    jb next_char                    ; If below 32, skip to next character
    cmp al, 126                     ; Check if character is above 126 (non-printable)
    ja next_char                    ; If above 126, skip to next character

    ; If printable, track string length
    test edx, edx                   ; Check if string start is set
    jnz string_in_progress          ; If already in a string, continue
    mov [string_start], esi         ; Set string start address
    inc edi                         ; Increment string length
    jmp find_printable

string_in_progress:
    inc edi                         ; Increment string length
    jmp find_printable

next_char:
    ; If a string of sufficient length was found, print it
    cmp edi, min_string_length      ; Check if the string length is sufficient
    jl reset_string                 ; If not, reset and continue

    ; Print the found string
    mov eax, 4                      ; sys_write syscall number
    mov ebx, 1                      ; File descriptor 1 (stdout)
    mov ecx, [string_start]         ; Address of the string start
    mov edx, edi                    ; Length of the string
    int 0x80                        ; Perform syscall

    ; Print a newline after the string to maintain output formatting
    mov eax, 4                      ; sys_write syscall number
    mov ebx, 1                      ; File descriptor 1 (stdout)
    mov ecx, newline                ; Newline character
    mov edx, 1                      ; Length of 1 byte
    int 0x80                        ; Perform syscall

reset_string:
    xor edi, edi                    ; Reset string length
    xor edx, edx                    ; Reset string start pointer
    jmp find_printable

check_remaining_string:
    ; Check if there's a valid string remaining in the buffer
    cmp edi, min_string_length      ; Check if string is long enough
    jl read_loop                    ; If not, continue reading
    mov eax, 4                      ; sys_write syscall number
    mov ebx, 1                      ; File descriptor 1 (stdout)
    mov ecx, [string_start]         ; Start of the string
    mov edx, edi                    ; Length of the string
    int 0x80                        ; Perform syscall

    ; Print newline after the string to maintain formatting
    mov eax, 4                      ; sys_write syscall number
    mov ebx, 1                      ; File descriptor 1 (stdout)
    mov ecx, newline                ; Newline character
    mov edx, 1                      ; Length of 1 byte
    int 0x80                        ; Perform syscall
    jmp read_loop                   ; Continue reading

close_file:
    ; Close the file
    mov eax, 6                      ; sys_close syscall number
    mov ebx, [fd]                   ; File descriptor
    int 0x80                        ; Perform syscall
    jmp exit_program                ; Exit program

usage_error:
    ; Print usage message
    mov eax, 4                      ; sys_write syscall number
    mov ebx, 1                      ; File descriptor 1 (stdout)
    mov ecx, error_msg              ; Error message to print
    mov edx, 24                     ; Length of message
    int 0x80                        ; Perform syscall
    jmp exit_program                ; Exit program

file_open_error:
    ; Handle file open error
    mov eax, 1                      ; sys_exit syscall number
    mov ebx, 1                      ; Exit with error code 1
    int 0x80                        ; Perform syscall

read_error:
    ; Handle read error
    mov eax, 1                      ; sys_exit syscall number
    mov ebx, 2                      ; Exit with error code 2
    int 0x80                        ; Perform syscall

exit_program:
    ; Exit program successfully
    mov eax, 1                      ; sys_exit syscall number
    xor ebx, ebx                    ; Exit with code 0 (success)
    int 0x80                        ; Perform syscall
