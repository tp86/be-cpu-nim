import std/tables
import std/macros
type
  R = ref object of RootObj
  I* = ref object of R
    x: int
  O* = ref object of R
    y: string
  C* = ref object
    rs: Table[string, R]

proc newI*(x: int): I = I(x: x)
proc newO*(y: string): O = O(y: y)

template `.=`*(c: C, n: untyped, r: R) =
  c.rs[astToStr(n)] = r

template `.`*(c: C, n: untyped): untyped =
  let r = astToStr(n)
  c.rs[r]

proc x*(i: I): int = i.x

proc y*(o: O): string = o.y

converter toI*(r: R): I = I(r)
converter toO*(r: R): O = O(r)

proc someProc*(c: C) = echo "proc"
