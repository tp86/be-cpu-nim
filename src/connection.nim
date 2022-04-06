import signal

type
  Input* = ref object
    sig: Signal
    connected: bool
  Output* = ref object
    connections: seq[Input]
    lastSignal: Signal
  ConnectionError* = object of CatchableError

proc newInput*(): Input = Input()

proc signal*(input: Input): Signal = input.sig

proc newOutput*(): Output = Output()

proc connect*(output: Output, input: Input) =
  if input.connected:
    raise newException(ConnectionError, "Cannot connect multiple times to the same input")
  output.connections.add input
  input.connected = true

proc propagate*(output: Output, signal: Signal): seq[Input] =
  result = output.connections
  # depends on input's default signal
  if signal == output.lastSignal:
    return @[]
  output.lastSignal = signal
  for input in output.connections:
    input.sig = signal
