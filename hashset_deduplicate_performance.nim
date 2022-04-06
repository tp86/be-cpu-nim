import std/[sets, sequtils, times]

type
  A = ref object

let 
  a = A()
  b = A()

block hashset:
  var s: seq[A] = @[]
  for i in 1..50000:
    s.add a
    s.add b

  assert len(s) == 1E5.int
  let time = cpuTime()
  let h = toHashSet(s)
  echo "Time taken in hashset: ", cpuTime() - time
  assert len(h) == 2

block dedup:
  var s: seq[A] = @[]
  for i in 1..50000:
    s.add a
    s.add b

  assert len(s) == 1E5.int
  let time = cpuTime()
  let d = deduplicate(s)
  echo "Time taken in deduplicate: ", cpuTime() - time
  assert len(d) == 2
