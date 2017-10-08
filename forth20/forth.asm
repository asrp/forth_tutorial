global _start
%define r2byte cl
%define strings_init_length 996
%define stdout 1
%define BUFFER_SIZE 4096
%define r5 rbp
%define r1byte al
%define False 0
%define r1 rax
%define r2 rcx
%define r3 rdx
%define return_index 23
%define stdin 0
%define primitive_length 78
%define True 1

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

%macro copyinit 1-2 8
mov r1, [%1_length]
dec r1
%%loop:
mov qword r2, [init_%1 + %2*r1]
mov qword [%1 + %2*r1], r2
dec r1
jns %%loop
%endmacro

section .text
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
    ; prints "Primitive # "
    ; call s11
    ; call print
    ; call printeol
    popdata r1
    call [primitive_function + 8*r1]
    ret
is_primitive:
    popdata r1
    cmp r1, primitive_length
    jge .false
    pushdata True
    ret
    .false:
    pushdata False
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

string_equal:
    popdata rsi
    popdata rdi
    ; compare length
    movzx r1, byte [rsi]
    movzx r2, byte [rdi]
    cmp r1, r2
    jne .false    ;; .false defined in retbool
    ; compare characters
    inc rsi
    inc rdi
    retbool repe cmpsb
equal_right_bracket:
    popdata r1
    movzx r2, byte [strings + 1*r1]
    movzx r1, byte [strings + 1*r1 + 1]
    cmp r2, 1
    jne .false
    retbool cmp r1, ']'

setup:
    mov qword [strings_length], strings_init_length
    mov qword [names.keys_length], primitive_length
    mov qword [names.values_length], primitive_length
    mov qword [memory_length], primitive_length
    mov qword [input_buffer_counter], 0
    copyinit strings, 1
    copyinit names.keys
    copyinit names.values
    pushdata return_index
    pushdata 1
    call memory.set_at
    ret

print_top:
    call s11
    call print
    call printeol
    ret
main_loop:
    .loop:
    call call_stack.len
    pushdata 0
    call equal
    popdata r1
    test r1, r1
    jnz .end
    call call_stack.pop
    call s11
    call memory.get
    call s21
    pushdata 1
    call add
    call call_stack.push
    call s11
    call is_primitive
    pushdata call_primitive
    pushdata call_stack.push
    call if_else
    jmp .loop
    .end:
    ret
return:
    call call_stack.pop
    call s2
    ret
next_char_is_space:
    call is_input_end
    pushdata read_stdin
    call if
    call next_char
    call s11
    call is_whitespace
    ret
next_input:
    pushdata None
    .space_loop:
    call s2
    call next_char_is_space
    popdata r1
    test r1, r1
    jnz .space_loop
    call strings.len
    call s21
    pushdata 0
    call strings.append
    .word_loop:
    call strings.append
    call next_char_is_space
    call not
    popdata r1
    test r1, r1
    jnz .word_loop
    call s2
    call s11
    call s11
    call strings.len
    call s21
    call sub
    pushdata 1
    call sub
    call s21
    call strings.set_at
    ret
names.get:
    call names.keys.index
    call names.values.get
    ret
names.len:
    call names.keys.len
    ret
names.set:
    call names.keys.append
    call names.values.append
    ret
names.keys.index:
    call names.len
    .loop:
    pushdata 1
    call sub
    call s1212
    call names.keys.get
    call strings.address
    call string_equal
    popdata r1
    test r1, r1
    jnz .found
    call s11
    popdata r1
    test r1, r1
    jnz .loop
    call s2
    pushdata None
    .found:
    call s21
    call s2
    ret
write_loop:
    call memory.len
    .loop:
    call next_input
    call s11
    call equal_right_bracket
    popdata r1
    test r1, r1
    jnz .end
    call strings.address
    call names.get
    call memory.append
    jmp .loop
    .end:
    call s2
    pushdata return_index
    call memory.append
    ret
input_loop:
    .loop:
    call next_input
    call strings.address
    call names.get
    pushdata 0
    call memory.set_at
    pushdata 0
    call call_stack.push
    call main_loop
    jmp .loop
    ret
_start:
    call setup
    call input_loop
    call exit
    ret
s11:
    popdata r1
    pushdata r1
    pushdata r1
    ret
s21:
    popdata r1
    popdata r2
    pushdata r1
    pushdata r2
    ret
s2:
    popdata r1
    popdata r2
    pushdata r2
    ret
s1212:
    popdata r1
    popdata r2
    pushdata r2
    pushdata r1
    pushdata r2
    pushdata r1
    ret
call_stack.len:
    pushdata [call_stack_length]
    ret
call_stack.push:
call_stack.append:
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
call_stack.get:
    popdata r1
    mov r1, [call_stack + 8*r1]
    pushdata r1
    ret
call_stack.set_at:
    popdata r1
    popdata r2
    mov [call_stack + 8*r1], r2
    ret
call_stack.address:
    popdata r1
    lea r1, [call_stack + 8*r1]
    pushdata r1
    ret
memory.len:
    pushdata [memory_length]
    ret
memory.push:
memory.append:
    popdata r1
    mov r2, [memory_length]
    mov [memory + 8*r2], r1
    inc qword [memory_length]
    ret
memory.pop:
    dec qword [memory_length]
    mov r1, [memory_length]
    mov r1, [memory + 8*r1]
    pushdata r1
    ret
memory.get:
    popdata r1
    mov r1, [memory + 8*r1]
    pushdata r1
    ret
memory.set_at:
    popdata r1
    popdata r2
    mov [memory + 8*r1], r2
    ret
memory.address:
    popdata r1
    lea r1, [memory + 8*r1]
    pushdata r1
    ret
names.keys.len:
    pushdata [names.keys_length]
    ret
names.keys.push:
names.keys.append:
    popdata r1
    mov r2, [names.keys_length]
    mov [names.keys + 8*r2], r1
    inc qword [names.keys_length]
    ret
names.keys.pop:
    dec qword [names.keys_length]
    mov r1, [names.keys_length]
    mov r1, [names.keys + 8*r1]
    pushdata r1
    ret
names.keys.get:
    popdata r1
    mov r1, [names.keys + 8*r1]
    pushdata r1
    ret
names.keys.set_at:
    popdata r1
    popdata r2
    mov [names.keys + 8*r1], r2
    ret
names.keys.address:
    popdata r1
    lea r1, [names.keys + 8*r1]
    pushdata r1
    ret
names.values.len:
    pushdata [names.values_length]
    ret
names.values.push:
names.values.append:
    popdata r1
    mov r2, [names.values_length]
    mov [names.values + 8*r2], r1
    inc qword [names.values_length]
    ret
names.values.pop:
    dec qword [names.values_length]
    mov r1, [names.values_length]
    mov r1, [names.values + 8*r1]
    pushdata r1
    ret
names.values.get:
    popdata r1
    mov r1, [names.values + 8*r1]
    pushdata r1
    ret
names.values.set_at:
    popdata r1
    popdata r2
    mov [names.values + 8*r1], r2
    ret
names.values.address:
    popdata r1
    lea r1, [names.values + 8*r1]
    pushdata r1
    ret
strings.len:
    pushdata [strings_length]
    ret
strings.push:
strings.append:
    popdata r1
    mov r2, [strings_length]
    mov byte [strings + 1*r2], r1byte 
    inc qword [strings_length]
    ret
strings.pop:
    dec qword [strings_length]
    mov r1, [strings_length]
    movzx r1, byte [strings + 1*r1]
    pushdata r1
    ret
strings.get:
    popdata r1
    movzx r1, byte [strings + 1*r1]
    pushdata r1
    ret
strings.set_at:
    popdata r1
    popdata r2
    mov [strings + 1*r1], r2byte 
    ret
strings.address:
    popdata r1
    lea r1, [strings + 1*r1]
    pushdata r1
    ret
input_buffer.len:
    pushdata [input_buffer_length]
    ret
input_buffer.push:
input_buffer.append:
    popdata r1
    mov r2, [input_buffer_length]
    mov byte [input_buffer + 1*r2], r1byte 
    inc qword [input_buffer_length]
    ret
input_buffer.pop:
    dec qword [input_buffer_length]
    mov r1, [input_buffer_length]
    movzx r1, byte [input_buffer + 1*r1]
    pushdata r1
    ret
input_buffer.get:
    popdata r1
    movzx r1, byte [input_buffer + 1*r1]
    pushdata r1
    ret
input_buffer.set_at:
    popdata r1
    popdata r2
    mov [input_buffer + 1*r1], r2byte 
    ret
input_buffer.address:
    popdata r1
    lea r1, [input_buffer + 1*r1]
    pushdata r1
    ret

section .data
init_strings: db 4, "exit", 7, "if-else", 2, "==", 1, "+", 14, "call-primitive", 12, "is-primitive", 5, "push1", 5, "print", 8, "printeol", 10, "printspace", 10, "read-stdin", 12, "is-input-end", 9, "next-char", 13, "is-whitespace", 2, "if", 3, "not", 1, "-", 12, "print-string", 12, "string-equal", 19, "equal-right-bracket", 5, "setup", 9, "print-top", 9, "main-loop", 6, "return", 18, "next-char-is-space", 10, "next-input", 9, "names.get", 9, "names.len", 9, "names.set", 16, "names.keys.index", 1, "[", 10, "input-loop", 3, "s11", 3, "s21", 2, "s2", 5, "s1212", 14, "call-stack.len", 15, "call-stack.push", 17, "call-stack.append", 14, "call-stack.pop", 14, "call-stack.get", 17, "call-stack.set-at", 18, "call-stack.address", 10, "memory.len", 11, "memory.push", 13, "memory.append", 10, "memory.pop", 10, "memory.get", 13, "memory.set-at", 14, "memory.address", 14, "names.keys.len", 15, "names.keys.push", 17, "names.keys.append", 14, "names.keys.pop", 14, "names.keys.get", 17, "names.keys.set-at", 18, "names.keys.address", 16, "names.values.len", 17, "names.values.push", 19, "names.values.append", 16, "names.values.pop", 16, "names.values.get", 19, "names.values.set-at", 20, "names.values.address", 11, "strings.len", 12, "strings.push", 14, "strings.append", 11, "strings.pop", 11, "strings.get", 14, "strings.set-at", 15, "strings.address", 16, "input-buffer.len", 17, "input-buffer.push", 19, "input-buffer.append", 16, "input-buffer.pop", 16, "input-buffer.get", 19, "input-buffer.set-at", 20, "input-buffer.address"
init_names.keys: dq 0, 5, 13, 16, 18, 33, 46, 52, 58, 67, 78, 89, 102, 112, 126, 129, 133, 135, 148, 161, 181, 187, 197, 207, 214, 233, 244, 254, 264, 274, 291, 293, 304, 308, 312, 315, 321, 336, 352, 370, 385, 400, 418, 437, 448, 460, 474, 485, 496, 510, 525, 540, 556, 574, 589, 604, 622, 641, 658, 676, 696, 713, 730, 750, 771, 783, 796, 811, 823, 835, 850, 866, 883, 901, 921, 938, 955, 975
init_names.values: dq 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77
primitive_function: dq exit, if_else, equal, add, call_primitive, is_primitive, push1, print, printeol, printspace, read_stdin, is_input_end, next_char, is_whitespace, if, not, sub, print_string, string_equal, equal_right_bracket, setup, print_top, main_loop, return, next_char_is_space, next_input, names.get, names.len, names.set, names.keys.index, write_loop, input_loop, s11, s21, s2, s1212, call_stack.len, call_stack.push, call_stack.append, call_stack.pop, call_stack.get, call_stack.set_at, call_stack.address, memory.len, memory.push, memory.append, memory.pop, memory.get, memory.set_at, memory.address, names.keys.len, names.keys.push, names.keys.append, names.keys.pop, names.keys.get, names.keys.set_at, names.keys.address, names.values.len, names.values.push, names.values.append, names.values.pop, names.values.get, names.values.set_at, names.values.address, strings.len, strings.push, strings.append, strings.pop, strings.get, strings.set_at, strings.address, input_buffer.len, input_buffer.push, input_buffer.append, input_buffer.pop, input_buffer.get, input_buffer.set_at, input_buffer.address
None: dq 0
eol: db 10
space: db 32
print_chars: db "0123456789abcdef"

section .bss
call_stack_length: resq 1
call_stack: resq 10000
memory_length: resq 1
memory: resq 10000
names.keys_length: resq 1
names.keys: resq 10000
names.values_length: resq 1
names.values: resq 10000
strings_length: resq 1
strings: resb 10000
input_buffer_length: resq 1
input_buffer: resb 10000
input_buffer_counter: resq 1
data_stack_length: resq 1
data_stack: resq 10000
