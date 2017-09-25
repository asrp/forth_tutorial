memory = []
data_stack = []
call_stack = []

def return_():
    call_stack.pop()

names = {"push1": lambda: (1,),
         "print": lambda x: print(x),
         "return": return_}

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

if __name__ == "__main__":
    memory.extend(["push1", "print", "return"])
    call_stack.append(0)
    main_loop()
