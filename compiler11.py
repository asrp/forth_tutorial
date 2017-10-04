INDENT = "    "
def indented(lst):
    return ["%s%s" % (INDENT, s) for s in lst]

def compile_(commands, stop=None):
    output = []
    while True:
        try:
            command = next(commands)
        except StopIteration:
            return output
        if command == stop:
            return output
        elif command == "[":
            body = compile_(commands, "]")
            assert(next(commands) == "bind:")
            output.append("%s:" % next(commands))
            output.extend(indented(body + ["ret"]))
        elif command == "comment":
            _ = compile_(commands, ")")
        elif command == "pushe:":
            output.append("push %s" % next(commands))
        elif command == "push":
            next_command = next(commands)
            output.append("push %s" % next_command)
        else:
            output.append("call %s" % command)

if __name__ == "__main__":
    import sys
    commands = open("forth.f" if len(sys.argv) < 2 else sys.argv[1]).read()
    commands = iter(commands.split())
    output = compile_(commands)
    print("\n".join(output))
