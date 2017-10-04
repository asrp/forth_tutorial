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

section .data
eol:	db 10
space:	db 32
print_chars: db "0123456789abcdef"

primitive_function: dq push1, print, return
memory: dq 0, 1, 0, 1, 2

section .bss
call_stack_length: resq 1
call_stack: resq 10000
data_stack_length: resq 1
data_stack: resq 10000

section .text
_start:
    ;; Start at memory[0]
    pushdata 0
    call call_stack.push
    prints "Running main loop"
    call printeol
    call main_loop
exit:
    mov eax, 60
    mov rdi, 0
    syscall

call_stack.len:
    pushdata [call_stack_length]
    ret
call_stack.push:
    popdata r1
    mov r2, [call_stack_length]
    mov [call_stack + 8*r2], r1
    inc qword [call_stack_length]
    ret
call_stack.pop:
    dec qword [call_stack_length]
    mov r1, [call_stack_length]
    mov r1, [call_stack + 8*r1]
    pushdata r1
    ret
memory.get:
    popdata r1
    mov r1, [memory + 8*r1]
    pushdata r1
    ret

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
    cmp r1, r2
    je .true
    .false:
    pushdata False
    ret
    .true:
    pushdata True
    ret
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
