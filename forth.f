[ pushe: 3 call_stack.pop_many ] bind: exit-main-loop
[ call-primitive ] bind: call-primitive-func
[ s21 call_stack.push ] bind: non-primitive-case
[ call_stack.len pushe: 0 == push: exit-main-loop names.get if
  call_stack.pop s11 memory.get names.get
  s21 pushe: 1 + call_stack.push
  s11 is-primitive s11 not push: non-primitive-case names.get if
  push: call-primitive names.get if ] bind: main-loop-loop
[ push: main-loop-loop call repeat ] bind: main-loop

[ next-input pushe: 2 memory.set_at pushe: 2 call_stack.push main-loop
] bind: input-loop-loop
[ push: input-loop-loop call repeat ] bind: input-loop

[ s2 push: return2 memory.append pushe: 3 call_stack.pop_many ] bind: exit-write-loop
[ next-input 
  s11 pushe: ']' == push: exit-write-loop names.get if
  memory.append ] bind: write-loop-loop
[ memory.len push: write-loop-loop call repeat ] bind: [

input-loop
push1 print [ push1 print ] bind2: foo foo
