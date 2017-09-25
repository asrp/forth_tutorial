memory = ["input goes here", "exit"]
data_stack = []
call_stack = []

def return_():
    call_stack.pop()

def exit_():
    del call_stack[:]
    
names = {"push1": lambda: (1,),
         "print": lambda x: print(x),
         "return": return_,
         "exit": exit_}

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

def input_loop():
    while True:
        for command in input("> ").split():
            memory[0] = command
            call_stack.append(0)
            main_loop()

if __name__ == "__main__":
    input_loop()
