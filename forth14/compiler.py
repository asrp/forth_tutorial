INDENT = "    "
def indented(lst):
    return ["%s%s" % (INDENT, s) for s in lst]

def stack_swap(indices):
    max_index = int(max(indices))
    return ["s%s:" % indices] +\
           indented("popdata r%s" % (i+1) for i in range(max_index)) +\
           indented("pushdata r%s" % i for i in reversed(indices)) +\
           indented(["ret"])

new_names = {"+": "add", "-": "sub", "==": "equal", "[": "write-loop",
             "(": "comment", ">": "greater", "push:": "push"}
old_names = {v: k for k, v in new_names.items()}
def rename(s):
    return new_names.get(s, s).replace("-", "_")

def compile_(commands, stop=None):
    output = []
    while True:
        try:
            command = rename(next(commands))
        except StopIteration:
            return output
        if command == stop:
            return output
        elif command == "write_loop":
            body = compile_(commands, "]")
            assert(next(commands) == "bind:")
            output.append("%s:" % rename(next(commands)))
            output.extend(indented(body + ["ret"]))
        elif command == "comment":
            _ = compile_(commands, ")")
        elif command == "prints(":
            next_command = next(commands)
            inner = []
            while next_command != ")":
                inner.append(next_command)
                next_command = next(commands)
            output.append('prints %s' % " ".join(inner))
        elif command == "pushe:":
            output.append("pushdata %s" % rename(next(commands)))
        elif command == "push":
            next_command = next(commands)
            output.append("pushdata %s" % rename(next_command))
        elif command == "label:":
            output.append("%s:" % rename(next(commands)))
        elif command == "goto:":
            output.append("jmp %s" % rename(next(commands)))
        elif command == "goto_if:":
            output.extend(["popdata r1", "test r1, r1",
                           "jnz %s" % rename(next(commands))])
        elif command == "ret":
            output.append("ret")
        else:
            output.append("call %s" % command)

if __name__ == "__main__":
    import sys
    commands = open("forth.f" if len(sys.argv) < 2 else sys.argv[1]).read()
    commands = iter(commands.split())
    output = compile_(commands)
    output += [line for indices in ["11", "21", "2"]
               for line in stack_swap(indices)]
    print(open("header.asm").read())
    print("\n".join(output))
