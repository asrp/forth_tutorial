    global _start
%define True 1
%define False 0
%define r1 rax
%define r1byte al
%define r2 rcx
%define r2byte cl
%define r3 rdx
%define r5 rbp
%define stdin 0
%define stdout 1
%define BUFFER_SIZE 4096

%macro pushdata 1
push r1
push r5
mov r5, [data_stack_length]
;; In case we want to do this with a constant or address
mov r1, %1
mov [data_stack + 8*r5], r1
inc qword [data_stack_length]
pop r5
pop r1
%endmacro

%macro popdata 1
push r5
dec qword [data_stack_length]
mov r5, [data_stack_length]
mov %1, [data_stack + 8*r5]
pop r5
%endmacro

%macro  prints 1+
jmp     %%endstr 
%%str:  db %1
%%endstr:
mov eax, 1
mov rdi, stdout
lea rsi, [%%str]
mov rdx, %%endstr-%%str
syscall
%endmacro

%macro retbool 1+
%1
je .true
.false:
pushdata False
ret
.true:
pushdata True
ret
%endmacro

section .data
eol:	db 10
space:	db 32
print_chars: db "0123456789abcdef"

primitive_function: dq push1, print, return
None: dq 0

section .text
_start:
    call next_input
    call strings.address
    call print_string
    call printeol
    call next_input
    call strings.address
    call print_string
    call printeol
exit:
    mov eax, 60
    mov rdi, 0
    syscall

if_else:
    popdata r3
    popdata r1
    popdata r2
    cmp r2, 0
    je .false
    call r1
    ret
    .false:
    call r3
    ret
equal:
    popdata r1
    popdata r2
    retbool cmp r1, r2
add:
    popdata r1
    popdata r2
    add r2, r1
    pushdata r2
    ret
call_primitive:
    popdata r1
    call [primitive_function + 8*r1]
    ret
is_primitive:
    pushdata True
    ret

push1:
    pushdata 1
    ret

print:
    ;; Print value at the top of the stack as an integer in hex.
    ;; Callable without losing register values
    push qword rax
    push qword rcx
    push qword rdx
    push qword rbx
    push qword rbp
    push qword rsi
    push qword rdi
    ;; x = data_stack.pop()
    popdata r3
    mov r1, 8
    dec r1
    .loop8times:
    ;; sys.print(stdout, print_chars[x & 1111b], 1)
    mov r2, r3
    and r2, 1111b
    push qword r1
    push qword r3
    mov eax, 1
    mov rdi, stdout
    lea rsi, [print_chars + 1*r2]
    mov rdx, 1
    syscall
    pop r3
    pop r1
    ;; x >>= 4
    shr r3, 4
    dec r1
    jns .loop8times
    
    mov eax, 1
    mov rdi, stdout
    lea rsi, [space]
    mov rdx, 1
    syscall
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    pop rdx
    pop rcx
    pop rax
    ret
printeol:
    mov eax, 1
    mov rdi, stdout
    lea rsi, [eol]
    mov rdx, 1
    syscall
    ret
printspace:
    mov eax, 1
    mov rdi, stdout
    lea rsi, [space]
    mov rdx, 1
    syscall
    ret

read_stdin:
    prints "> "
    mov eax, 0
    mov rdi, stdin
    lea rsi, [input_buffer]
    mov rdx, BUFFER_SIZE
    syscall
    cmp r1, 0
    je .read_error
    mov qword [input_buffer_length], r1
    ; pushdata r1 ;; Uncomment to return number of characters read
    mov qword [input_buffer_counter], 0
    ret
    .read_error:
    prints "Out of input", 10
    call exit
is_input_end:
    mov r1, [input_buffer_counter]
    retbool cmp r1, [input_buffer_length]
next_char:
    mov r1, [input_buffer_counter]
    movzx r2, byte [input_buffer + 1*r1]
    pushdata r2
    inc qword [input_buffer_counter]
    ret
is_whitespace:
    popdata r1
    cmp r1byte, 10 ; end of line
    je .true
    cmp r1byte, ' '
    je .true
    pushdata False
    ret
    .true:
    pushdata True
    ret
if:
    popdata r1
    popdata r2
    cmp r2, 0
    je .false
    call r1
    .false:
    ret
not:
    popdata r1
    retbool cmp r1, 0
sub:
    popdata r1
    popdata r2
    sub r2, r1
    pushdata r2
    ret
print_string:
    popdata r2
    movzx r3, byte [r2]
    mov eax, 1
    mov rdi, stdout
    lea rsi, [r2 + 1*1]
    ; mov rdx, r3 ;; r3 is already rdx!
    syscall
    ret
