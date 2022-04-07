import std/macros
import gate

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

type
  TSR = ref object
    S, R: Input
    Q, Q̅: Output

proc SR*(): TSR =
  result = TSR()
  let
    sNor = Nor()
    rNor = Nor()
  rNor.C ~~ sNor.A
  sNor.C ~~ rNor.B
  result.R = rNor.A
  result.S = sNor.B
  result.Q̅ = sNor.C
  result.Q = rNor.C
  updateAll sNor, rNor

TSR.getters
