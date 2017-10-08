[ next-input names.set ] next-input bind: names.set
[ push1 print ] bind: foo
foo push: foo names.get call
push: push1 names.get call push: print names.get call
