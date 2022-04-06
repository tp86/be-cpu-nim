import std/macros

type
  X = ref object
    a, b: int

# generate getters for fields of X
macro getters(T: untyped) =
  echo T.getImpl.treerepr

X.getters
