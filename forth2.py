from forth1 import *

names["my_func"] = 2
memory.extend(["my_func", "return", "push1", "print", "return"])
call_stack.append(0)
main_loop()
