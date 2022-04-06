import std/[sequtils, tables]
import connection
import signal

type
  GateKind = enum
    gNot
  Gate* = ref object
    case kind: GateKind
    of gNot:
      a: Input
      b: Output
  IO = Input or Output

var
  inputToGate = initTable[Input, Gate]()

proc gates(inputs: seq[Input]): seq[Gate] =
  inputs.mapIt(inputToGate.getOrDefault(it))

proc update*(g: Gate): seq[Gate] =
  case g.kind
  of gNot:
    let s = !g.a.signal
    g.b.propagate(s).gates

proc A*(g: Gate): IO =
  case g.kind
  of gNot: g.a

proc B*(g: Gate): IO =
  case g.kind
  of gNot: g.b

proc newNot*(): Gate =
  result = Gate(kind: gNot, a: newInput(), b: newOutput())
  inputToGate[result.a] = result
