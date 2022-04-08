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
  TD = ref object
    D, EN: Input
    Q, Q̅: Output
  TEdgeH = ref object
    CLK: Input
    Edge: Output
  TDFF = ref object
    D, CLK: Input
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

proc D*(): TD =
  result = TD()
  let
    sr = SR()
    sAnd = And()
    rAnd = And()
    dNot = Not()
    dB = Broadcast()
    enB = Broadcast()
  dB.output ~~ sAnd.A
  dB.output ~~ dNot.A
  dNot.B ~~ rAnd.A
  enB.output ~~ sAnd.B
  enB.output ~~ rAnd.B
  sAnd.C ~~ sr.S
  rAnd.C ~~ sr.R
  result.D = dB.input
  result.EN = enB.input
  result.Q = sr.Q
  result.Q̅ = sr.Q̅
  updateAll dB, enB
TD.getters

import signal
proc EdgeH*(): TEdgeH =
  result = TEdgeH()
  let
    clkB = Broadcast()
    clkNot1 = Not()
    clkNot2 = Not()
    clkNot3 = Not()
    clkAnd = And()
  # for edge detector with one Not gate order of connections would matter!
  # clkB.output ~~ clkAnd.C BEFORE clkB.output ~~ clkNot1.A
  clkB.output ~~ clkNot1.A
  clkNot1.B ~~ clkNot2.A
  clkNot2.B ~~ clkNot3.A
  clkNot3.B ~~ clkAnd.B
  clkB.output ~~ clkAnd.A
  result.CLK = clkB.input
  result.Edge = clkAnd.C
  updateAll clkB
TEdgeH.getters

proc DFF*(): TDFF =
  result = TDFF()
  let
    d = D()
    edge = EdgeH()
  edge.Edge ~~ d.EN
  result.D = d.D
  result.CLK = edge.CLK
  result.Q = d.Q
  result.Q̅ = d.Q̅
TDFF.getters
