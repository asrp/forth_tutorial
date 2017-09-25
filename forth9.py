from ast import literal_eval
from operators import operators
from pdb import set_trace as bp
memory = ["input goes here", "exit", "second input goes here", "exit2", "push1", "print", "exit"]
input_buffer = []
data_stack = []
call_stack = []
call_stack2 = []

def return_():
    call_stack.pop()

def return2():
    call_stack2.pop()

def exit_():
    del call_stack[:]

def exit2():
    del call_stack2[:]

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

def bind2(index):
    names[next_command2()] = index

def if_(condition, index):
    if condition:
        if callable(index):
            call_primitive(index)
        else:
            call_stack.append(index)

# Needed if we want to avoid the auxiliary call-primitive-func call
def if2(condition, index):
    if condition:
        if callable(index):
            call_primitive(index)
        else:
            call_stack2.append(index)

def repeat():
    call_stack[-1] -= 4

def call(name):
    call_stack.append(names[name])

def call_stack_pop_many(i):
    del call_stack[-i:]

def call_stack2_pop_many(i):
    del call_stack[-i:]

def call_primitive(func):
    if not callable(func):
        assert(func == names['['])
        call_stack.append(func)
        return
    argindex = len(data_stack) - func.__code__.co_argcount
    args = data_stack[argindex:]
    del data_stack[argindex:]
    data_stack.extend(func(*args) or ())

def main_loop():
    while True:
        if not call_stack:
            return
        #print("call stack: %s\ndata stack: %s\nmemory: %s\n\n" % (call_stack, data_stack, memory))
        #print("names: %s" % names)
        print("call stack: %s" % call_stack)
        print("call stack2: %s" % call_stack2)
        print("data stack: %s" % data_stack)
        try:
            print("next command: %s" % memory[call_stack[-1]])
        except:
            pass
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

def next_command2():
    if len(call_stack2) > 1:
        call_stack2[-1] += 1
        return memory[call_stack2[-1] - 1]
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

names = {"push1": lambda: (1,),
         "print": lambda x: print(x),
         "return": return_,
         "return2": return2,
         "exit": exit_,
         "exit2": exit2,
         "[": write_loop,
         "bind:": bind,
         "bind2:": bind2,
         "pushe:": lambda: data_stack.append(literal_eval(next_command())),
         "push:": lambda: data_stack.append(next_command()),
         "if": if_,
         "repeat": repeat,
         "call": call,
         "s11": lambda x: (x, x),
         "s21": lambda x, y: (y, x),
         "s2": lambda x: None,
         "call_stack.len": lambda: (len(call_stack2),),
         "call_stack.push": lambda x: call_stack2.append(x),
         "call_stack.pop": lambda: (call_stack2.pop(),),
         "call_stack.pop_many": call_stack_pop_many,
         "memory.get": lambda x: (memory[x],),
         "memory.set_at": lambda i, x: memory.__setitem__(x, i),
         "memory.len": lambda: (len(memory),),
         "memory.append": lambda x: memory.append(x),
         "names.get": lambda x: (names[x],),
         "is-primitive": lambda x: (callable(x) or x == names.get('['),),
         "call-primitive": call_primitive,
         "next-input": lambda: (next_input(),),
         "next-command": lambda: (next_command(),),
         "bp": lambda: bp(),
}
names.update(operators)

if __name__ == "__main__":
    input_buffer.extend(open("forth.f").read().split())
    call_stack2.append(2)
    input_loop()
