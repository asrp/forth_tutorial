from ast import literal_eval
from operators import operators
from pdb import set_trace as bp
memory = ["input goes here", "exit"]
input_buffer = []
data_stack = []
call_stack = []

def return_():
    call_stack.pop()

def exit_():
    del call_stack[:]

def write_memory(data):
    memory.append(data)

def write_loop():
    start = len(memory)
    while True:
        command = next_input()
        if command == "]":
            memory.append("return")
            return (start,)
        memory.append(command)

def bind(index):
    names[next_command()] = index

def if_(condition, index):
    if condition:
        call_stack.append(index)

def repeat():
    call_stack[-1] -= 4

def call(name):
    call_stack.append(names[name])
    
names = {"push1": lambda: (1,),
         "print": lambda x: print(x),
         "return": return_,
         "exit": exit_,
         "[": write_loop,
         "bind:": bind,
         "pushe:": lambda: data_stack.append(literal_eval(next_command())),
         "push:": lambda: data_stack.append(next_command()),
         "if": if_,
         "names.get": lambda x: (names[x],),
         "repeat": repeat,
         "call": call}
names.update(operators)

def main_loop():
    while True:
        if not call_stack:
            return
        #print("call stack: %s\ndata stack: %s\nmemory: %s\n\n" % (call_stack, data_stack, memory))
        #print("names: %s" % names)
        #print("next command: %s" % memory[call_stack[-1]])
        func = names[memory[call_stack[-1]]]  # Steps 1, 2, 3
        call_stack[-1] += 1  # Step 4 
        # Step 5  Python functions are primitives, strings (function names) are non-primitives.
        if callable(func):
            # Deduce number of arguments.
            argindex = len(data_stack) - func.__code__.co_argcount
            args = data_stack[argindex:]
            del data_stack[argindex:]
            data_stack.extend(func(*args) or ())
        else:
            call_stack.append(func)  # Step 6

def next_command():
    if len(call_stack) > 1:
        call_stack[-1] += 1
        return memory[call_stack[-1] - 1]
    else:
        return next_input()

def next_input():
    if not input_buffer:
        input_buffer.extend(input("> ").split())
    return input_buffer.pop(0)
    
def input_loop():
    while True:
        try:
            memory[0] = next_input()
        except EOFError:
            break
        call_stack.append(0)
        main_loop()

if __name__ == "__main__":
    input_loop()
