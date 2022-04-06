import std/sequtils
import signal

type
  Input = ref object
    parent: Parent
    signal: Signal
    connected: bool
  Output = ref object
    connections: seq[Input]
    lastSignal: Signal
  ConnectionError = object of CatchableError

  Parent = ref object {.inheritable.}
  Nat = static[Natural]

  SignalReceiver[N: Nat] = ref object of Parent
    inputs: array[N, Input]

  Sink = SignalReceiver[1]

  SignalUpdater = proc (_: varargs[Signal]): Signal

  Gate[N: Nat] = ref object of SignalReceiver[N]
    updateFn: SignalUpdater
    output: Output

  Source = ref object of Gate[0]

  Broadcast = ref object of Gate[1]

  Not = ref object of Gate[1]
  And = ref object of Gate[2]
  Or = ref object of Gate[2]
  Xor = ref object of Gate[2]
  Nand = ref object of Gate[2]
  Nor = ref object of Gate[2]
  Nxor = ref object of Gate[2]

proc newInput(parent: Parent): Input = Input(parent: parent)
proc newOutput(): Output = Output()

proc signal*(input: Input): Signal = input.signal

proc `~~`*(output: Output, input: Input) =
  if input.connected:
    raise newException(ConnectionError,
      "Cannot connect multiple times to the same input")
  input.connected = true
  output.connections.add input

proc propagate(output: Output, signal: Signal): seq[Parent] =
  result = output.connections.mapIt(it.parent)
  # depends on default signal value
  if signal == output.lastSignal:
    return @[]
  output.lastSignal = signal
  for input in output.connections:
    input.signal = signal

proc output*(source: Source): Output = source.output

proc input*(b: Broadcast): Input = b.inputs[0]
proc output*(b: Broadcast): Output = b.output

proc input*(sink: Sink): Input = sink.inputs[0]

proc A*[N: static[range[1..high(int)]]](receiver: SignalReceiver[N]): Input =
  receiver.inputs[0]

proc B*[N: static[range[2..high(int)]]](receiver: SignalReceiver[N]): Input =
  receiver.inputs[1]
proc B*(gate: Gate[1]): Output = gate.output

proc C*(gate: Gate[2]): Output = gate.output

proc update*[N: Nat](_: SignalReceiver): seq[Parent] = @[]
proc update*[N: Nat](gate: Gate[N]): seq[Parent] =
  let s = gate.updateFn(gate.inputs.mapIt(it.signal))
  gate.output.propagate(s)

proc newSink(): Sink =
  result = Sink()
  result.inputs = [newInput(result)]

proc newSource(updateFn: SignalUpdater): Source =
  Source(inputs: [], updateFn: updateFn, output: newOutput())

when isMainModule:
  var sig = H
  let
    source = newSource(proc(_: varargs[Signal]): Signal = sig)
    sink = newSink()
  source.output ~~ sink.input
  let next = source.update
  assert next[0] == sink
  echo sink.input.signal
