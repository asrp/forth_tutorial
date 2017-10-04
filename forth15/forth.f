[ label: .loop
  call_stack.len pushe: 0 == goto-if: .end
  call_stack.pop s11 memory.get
  s21 pushe: 1 + call_stack.push
  s11 is-primitive push: call-primitive push: call_stack.push if-else
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
