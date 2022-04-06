import std/sequtils
import signal

type
  IO* = ref object of RootObj # needed for A, B, C, ... accessors varying in return type
  Input* = ref object of IO
    parent: Gate
    signal: Signal
    connected: bool
  Output* = ref object of IO
    connections: seq[Input]
    lastSignal: Signal
  ConnectionError* = object of CatchableError

  GateKind = enum
    gSource
    gSink
    gIn1
    gIn2
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
    of gIn2:
      signal2: proc (s1, s2: Signal): Signal
      a2, b2: Input
      c2: Output

using
  i: Input
  o: Output
  s: Signal
  g: Gate

proc newInput(g): Input = Input(parent: g)

method signal(io: IO): Signal {.base.} = discard

method signal*(i): Signal = i.signal

proc newOutput(): Output = Output()

proc `~~`*(output, input: IO) =
  let
    o = try: output.Output
        except ObjectConversionDefect:
          raise newException(ConnectionError, "Connection must begin with Output")
    i = try: input.Input
        except ObjectConversionDefect:
          raise newException(ConnectionError, "Connection must end with Input")
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
    input.signal = s

func A*(g): IO =
  case g.kind
  of gIn1: g.a1
  of gIn2: g.a2
  else: nil

func B*(g): IO =
  case g.kind
  of gIn1: g.b1
  of gIn2: g.b2
  else: nil

func C*(g): IO =
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

proc newGateIn2(p: proc (s1, s2: Signal): Signal): Gate =
  result = Gate(kind: gIn2, signal2: p, c2: newOutput())
  result.a2 = newInput(result)
  result.b2 = newInput(result)

proc newAnd*(): Gate = newGateIn2(`&`)
