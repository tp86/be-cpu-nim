import std/[macros, sequtils]
import signal as sig

type
  Input* = ref object
    parent: Parent
    signal: Signal
    connected: bool
  Output* = ref object
    connections: seq[Input]
    lastSignal: Signal
    propagated: bool
  ConnectionError* = object of CatchableError

  Parent {.inheritable.} = ref object 
    update: proc(p: Parent): seq[Parent]
  Nat = static[Natural]

  SignalReceiver[N: Nat] = ref object of Parent
    inputs: array[N, Input]

  TSink = SignalReceiver[1]

  SignalUpdater = proc(_: varargs[Signal]): Signal
  Gate[N: Nat] = ref object of SignalReceiver[N]
    output: Output

  TSource = ref object of Gate[0]

  TBroadcast = ref object of Gate[1]

proc newInput(parent: Parent): Input = Input(parent: parent)
proc newOutput(): Output = Output()

proc update(p: Parent): seq[Parent] =
  p.update(p)

proc `~~`*(output: Output, input: Input) =
  if input.connected:
    raise newException(ConnectionError,
  "Cannot connect multiple times to the same input")
  input.connected = true
  output.connections.add input
  input.signal = output.lastSignal
  discard update(input.parent)

proc propagate(output: Output, signal: Signal): seq[Parent] =
  result = output.connections.mapIt(it.parent)
  if output.propagated:
    if signal == output.lastSignal:
      return @[]
  else:
    output.propagated = true
  output.lastSignal = signal
  for input in output.connections:
    input.signal = signal

proc updateNoDownstream(T: typedesc, fn: proc(_: varargs[Signal]), p: Parent): seq[Parent] =
  result = @[]
  let gate = T(p)
  fn(gate.inputs.mapIt(it.signal))
proc updateDownstream(T: typedesc, fn: SignalUpdater, gate: Parent): seq[Parent] =
  let gate = T(gate)
  let s = fn(gate.inputs.mapIt(it.signal))
  result = gate.output.propagate(s)
template addUpdateField(parent: Parent, fn: SignalUpdater) =
  parent.update = proc(p: Parent): seq[Parent] =
    updateDownstream(parent.typeOf, fn, p)

proc updateAll*(fromElements: varargs[Parent]) =
  var elements = @fromElements
  while elements.len > 0:
    var next: seq[Parent] = @[]
    for element in elements.deduplicate:
      next.add update(element)
    elements = next

proc output*(source: TSource): Output = source.output

proc input*(b: TBroadcast): Input = b.inputs[0]
proc output*(b: TBroadcast): Output = b.output

proc input*(sink: TSink): Input = sink.inputs[0]

proc A*[N: static[range[1..high(int)]]](receiver: SignalReceiver[N]): Input =
  receiver.inputs[0]

proc B*[N: static[range[2..high(int)]]](receiver: SignalReceiver[N]): Input =
  receiver.inputs[1]
proc B*(gate: Gate[1]): Output = gate.output

proc C*(gate: Gate[2]): Output = gate.output

proc Sink*(updateFn: proc(_: varargs[Signal]) = proc(_: varargs[Signal]) = discard): TSink =
  let sink = TSink()
  result = sink
  result.inputs = [newInput(result)]
  result.update = proc(p: Parent): seq[Parent] =
    updateNoDownstream(sink.typeOf, updateFn, p)

proc Source*(updateFn: proc(): Signal): TSource =
  result = TSource()
  result.inputs = []
  result.output = newOutput()
  proc wrap(fn: proc(): Signal): SignalUpdater =
    result = proc(_: varargs[Signal]): Signal =
      fn()
  result.addUpdateField wrap(updateFn)

macro declareGate[N: Nat](T: typedesc[Gate[N]]) =
  var inputs = newTree(nnkBracket)
  for i in 0..<N:
    inputs.add nnkCall.newTree(ident("newInput"), ident("result"))
  quote do:
    result = `T`(output: newOutput())
    result.inputs = `inputs`

proc Broadcast*(): TBroadcast =
  declareGate(TBroadcast)
  let updateFn = proc(s: varargs[Signal]): Signal = s[0]
  result.addUpdateField updateFn

macro createGate(name: untyped, updater: proc) =
  let typeName = ident("T" & name.repr)
  # get number of `updater` args
  var nArgs: int
  for defs in updater.getImpl[3][1..^1]:
    nArgs += defs.len - 2
  let updaterId = genSym(nskProc)
  let s = genSym(nskParam)
  let call = newTree(nnkCall)
  call.add nnkAccQuoted.newTree(ident($updater))
  for i in 0..<nArgs:
    call.add newTree(nnkBracketExpr, s, newLit(i))
  quote do:
    type
      `typeName` = ref object of Gate[`nArgs`]
    proc `name`*(): `typeName` =
      declareGate(`typeName`)
      proc `updaterId`(`s`: varargs[Signal]): Signal = `call`
      result.addUpdateField `updaterId`

createGate(Not,  sig.`!`)
createGate(And,  sig.`&`)
createGate(Or,   sig.`|`)
createGate(Xor,  sig.`^`)
createGate(Nand, sig.`!&`)
createGate(Nor,  sig.`!|`)
createGate(Nxor, sig.`!^`)
