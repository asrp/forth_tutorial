[ s11 print printeol ] bind: print-top
[ s11 is-primitive push: call-primitive push: call_stack.push if-else
] bind: call

[ label: .loop
  call_stack.len pushe: 0 == goto-if: .end
  call_stack.pop s11 memory.get
  s21 pushe: 1 + call_stack.push
  call
  goto: .loop
  label: .end ] bind: main-loop

[ call_stack.pop s2 ] bind: return

[ is-input-end push: read-stdin if next-char
  s11 is-whitespace ] bind: next-char-is-space
[ push: None
  label: .space-loop s2 next-char-is-space goto-if: .space-loop
  strings.len s21 pushe: 0 strings.append
  label: .word-loop strings.append next-char-is-space not goto-if: .word-loop
  s2 s11 s11 strings.len s21 - pushe: 1 - s21 strings.set_at
] bind: next-input

[ names.keys.index names.values.get ] bind: names.get
[ names.keys.len ] bind: names.len
[ names.keys.append names.values.append ] bind: names.set
[ names.len
  label: .loop
  pushe: 1 - s1212 names.keys.get strings.address
  string_equal goto-if: .found
  s11 goto-if: .loop
  s2 push: None
  label: .found s21 s2 ] bind: names.keys.index

[ next-input memory.append ] bind: raw-write
[ memory.len
  label: .loop
  next-input s11 equal-right-bracket goto-if: .end
  strings.address names.get s11 memory.append
  s11 push: push_index == push: raw-write if
  push: pushi_index == push: raw-write if
  goto: .loop
  label: .end
  s2 push: return-index memory.append
] bind: [

[ label: .loop
  next-input strings.address names.get pushe: 0 memory.set_at
  pushe: 0 call_stack.push main-loop
  goto: .loop ] bind: input-loop

[ call_stack.len push: 1 > goto-if: .read_memory
  next-input ret
  label: .read_memory call_stack.pop s11 push: 1 + call_stack.push memory.get
] bind: next-command
[ next-command strings.address ] bind: push:

[ call_stack.pop push: 5 - call_stack.push ] bind: repeat

[ push: 0 s21 s11 s11 strings.get + s21
  label: .loop ( start+index, start+len, output_sum )
  pushe: 1 +
  s1312 strings.get pushe: '0' - prints( "diff " ) s11 print s21 push: 10 * +
  s231 prints( "index " ) s11 print s1212 == not goto-if: .loop
  s2 s2 printeol ] bind: int
[ next-command int ] bind: pushi

[ setup input-loop exit ] bind: _start
