import std/sequtils
import signal

type
  IOKind = enum
    gIn
    gOut
  IO* = ref object
    case kind: IOKind
    of gIn:
      parent: Gate
      sig: Signal
      connected: bool
    of gOut:
      connections: seq[IO]
      lastSignal: Signal
  ConnectionError* = object of CatchableError
  UsageError* = object of CatchableError

  GateKind = enum
    gSource
    gSink
    gIn1
    gIn2
  Gate* = ref object
    case kind: GateKind
    of gSource:
      signal: proc (): Signal
      output*: IO
    of gSink:
      input*: IO
    of gIn1:
      signal1: proc (s: Signal): Signal
      a1: IO
      b1: IO
    of gIn2:
      signal2: proc (s1, s2: Signal): Signal
      a2, b2: IO
      c2: IO

using
  i, o: IO
  s: Signal
  g: Gate

proc isInput*(i): bool =
  i.kind == gIn

proc isOutput*(o): bool =
  o.kind == gOut

proc newInput(g): IO = IO(kind: gIn, parent: g)

proc signal*(i): Signal =
  if i.kind != gIn:
    raise newException(UsageError, "Cannot get signal out of Output")
  i.sig

proc newOutput(): IO = IO(kind: gOut)

proc `~~`*(o, i) =
  if o.kind != gOut and i.kind != gIn:
    raise newException(UsageError, "Only Output ~~ Input connections are allowed")
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
  of gIn2: g.a2
  else: nil

proc B*(g): IO =
  case g.kind
  of gIn1: g.b1
  of gIn2: g.b2
  else: nil

proc C*(g): IO =
  case g.kind
  of gIn2: g.c2
  else: nil

proc update*(g): seq[Gate] =
  case g.kind
  of gSource:
    g.output.propagate(g.signal())
  of gSink: @[]
  of gIn1:
    let s = g.signal1(g.a1.signal)
    g.b1.propagate(s)
  of gIn2:
    let s = g.signal2(g.a2.signal, g.b2.signal)
    g.c2.propagate(s)

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

proc newAnd*(): Gate =
  result = Gate(kind: gIn2, signal2: `&`, c2: newOutput())
  result.a2 = newInput(result)
  result.b2 = newInput(result)
