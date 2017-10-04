[ label: .loop
  call_stack.len pushe: 0 == goto-if: .end
  call_stack.pop s11 memory.get
  s21 pushe: 1 + call_stack.push
  s11 is-primitive push: call-primitive push: call_stack.push if-else
  goto: .loop
  label: .end ] bind: main-loop

[ call_stack.pop s2 ] bind: return