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
    pushdata 0x100
    pushdata 23
    call names.set
    pushdata 0x200
    pushdata 36
    call names.set
    pushdata 23
    call names.get
    call print
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
    pushdata r1
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
    call equal
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
