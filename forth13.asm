    global _start
%define True 1
%define False 0
%define r1 rax
%define r2 rcx
%define r3 rdx
%define r5 rbp
%define stdin 0
%define stdout 1

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

_start:
    prints "Hello world"
    call printeol
    prints "1000 in hex and reversed is: "
    pushdata 1000
    call print
    call printeol
    pushdata 2000
    pushdata 3000
    popdata r1
    call print
    pushdata r1
    call print
    mov eax, 60
    mov rdi, 0
    syscall
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

section .data
eol:	db 10
space:	db 32
print_chars: db "0123456789abcdef"

section .bss
data_stack_length: resq 1
data_stack: resq 10000
