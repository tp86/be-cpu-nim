import std/sequtils
import signal

type
  Input* = ref object
    parent: Gate
    sig: Signal
    connected: bool
  Output* = ref object
    connections: seq[Input]
    lastSignal: Signal
  ConnectionError* = object of CatchableError

  GateKind = enum
    gSource
    gSink
    gIn1
  Gate* = ref object
    case kind: GateKind
    of gSource:
      signal: proc (): Signal
      output*: Output
    of gSink:
      input*: Input
    of gIn1:
      signal1: proc (s: Signal): Signal
      a1: Input
      b1: Output
  IO = Input or Output

using
  i: Input
  o: Output
  s: Signal
  g: Gate

proc newInput(g): Input = Input(parent: g)

proc signal*(i): Signal = i.sig

proc newOutput(): Output = Output()

proc `~~`*(o, i) =
  if i.connected:
    raise newException(ConnectionError, "Cannot connect multiple times to the same input")
  o.connections.add i
  i.connected = true

proc propagate(o, s): seq[Gate] =
  result = o.connections.mapIt(it.parent)
  # depends on input's default signal
  if s == o.lastSignal:
    return @[]
  o.lastSignal = s
  for input in o.connections:
    input.sig = s

proc A*(g): IO =
  case g.kind
  of gIn1: g.a1
  else: nil

proc B*(g): IO =
  case g.kind
  of gIn1: g.b1
  else: nil

proc update*(g): seq[Gate] =
  case g.kind
  of gSource:
    g.output.propagate(g.signal())
  of gSink: @[]
  of gIn1:
    let s = g.signal1(g.a1.signal)
    g.b1.propagate(s)

proc newSource*(signal: proc (): Signal): Gate =
  Gate(kind: gSource, signal: signal, output: newOutput())

proc newConstantSource*(s = L): Gate =
  Gate(kind: gSource, signal: proc (): Signal = s, output: newOutput())

proc newSink*(): Gate =
  result = Gate(kind: gSink)
  result.input = newInput(result)

proc newNot*(): Gate =
  result = Gate(kind: gIn1, signal1: `!`, b1: newOutput())
  result.a1 = newInput(result)
