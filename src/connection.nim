import signal

type
  Input* = ref object
    sig: Signal
    connected: bool
  Output* = ref object
    connections: seq[Input]
  ConnectionError* = object of CatchableError

proc newInput*(): Input = Input(sig: L)

proc signal*(input: Input): Signal = input.sig

proc newOutput*(): Output = Output()

proc connect*(output: Output, input: Input) =
  if input.connected:
    raise newException(ConnectionError, "Cannot connect multiple times to the same input")
  output.connections.add input
  input.connected = true
