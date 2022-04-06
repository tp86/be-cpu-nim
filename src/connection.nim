import signal

type
  Input* = ref object
    sig: Signal
    connected: bool
  Output* = ref object
    connections: seq[Input]
    lastSignal: Signal
  ConnectionError* = object of CatchableError

using
  i: Input
  o: Output
  s: Signal

proc newInput*(): Input = Input()

proc signal*(i): Signal = i.sig

proc newOutput*(): Output = Output()

proc connect*(o, i) =
  if i.connected:
    raise newException(ConnectionError, "Cannot connect multiple times to the same input")
  o.connections.add i
  i.connected = true

proc propagate*(o, s): seq[Input] =
  result = o.connections
  # depends on input's default signal
  if s == o.lastSignal:
    return @[]
  o.lastSignal = s
  for input in o.connections:
    input.sig = s
