[ next-input names.set ] next-input bind: names.set
[ push1 print ] bind: foo
foo
[ push: foo names.get call repeat ] bind: bar
bar
