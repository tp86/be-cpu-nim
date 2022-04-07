import std/macros

type
  X = ref object of RootObj
    a, b: int
    c: string
    d: array[1, bool]


# generate getters for fields of X
macro getters(T: untyped) =
  var t = T.getImpl[2]
  if t.kind == nnkRefTy:
    t = t[0]
  result = nnkStmtList.newTree
  for defs in t[2]:
    for field in defs[0..^3]:
      let arg = nskParam.genSym
      let retType = defs[^2]
      result.add quote do:
        proc `field`*(`arg`: `T`): `retType` = `arg`.`field`

X.getters

let x = X(a: 1, b: 2, c: "abc", d: [true])
echo a(x)
echo b(x)
echo c(x)
echo d(x)
