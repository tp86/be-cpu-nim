import std/sequtils
import std/macros
import signal

type
  Input = ref object
    parent: Parent
    signal: Signal
    connected: bool
  Output = ref object
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

  TNot = ref object of Gate[1]
  TAnd = ref object of Gate[2]
  TOr = ref object of Gate[2]
  TXor = ref object of Gate[2]
  TNand = ref object of Gate[2]
  TNor = ref object of Gate[2]
  TNxor = ref object of Gate[2]

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
  if output.propagated:
    if signal == output.lastSignal:
      return @[]
  else:
    output.propagated = true
  output.lastSignal = signal
  for input in output.connections:
    input.signal = signal

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

proc update(p: Parent): seq[Parent] = @[]
proc update(T: typedesc, fn: SignalUpdater, gate: Parent): seq[Parent] =
  let gate = T(gate)
  let s = fn(gate.inputs.mapIt(it.signal))
  result = gate.output.propagate(s)
template makeUpdate(parent: Parent, fn: SignalUpdater) =
  parent.update = proc(p: Parent): seq[Parent] =
    update(parent.typeOf, fn, p)
template update*(p: Parent): untyped =
  p.update(p)

proc Sink*(): TSink =
  result = TSink()
  result.inputs = [newInput(result)]
  result.update = update

proc Source*(updateFn: SignalUpdater): TSource =
  result = TSource()
  result.inputs = []
  result.output = newOutput()
  result.makeUpdate updateFn

macro makeGate[N: Nat](T: typedesc[Gate[N]]) =
  var inputs = newTree(nnkBracket)
  for i in 0..<N:
    var input = newTree(nnkCall)
    input.add ident("newInput")
    input.add ident("result")
    inputs.add input
  quote do:
    result = `T`(output: newOutput())
    result.inputs = `inputs`

macro asSignalUpdater(f: proc): untyped =
  let impl = f.getImpl
  var n: int
  for child in impl.children:
    if child.kind == nnkFormalParams:
      for param in child.children:
        if param.kind == nnkIdentDefs:
          for arg in param.children:
            if arg.kind == nnkSym:
              inc n
  var call = newTree(nnkCall)
  var quoted = newTree(nnkAccQuoted)
  quoted.add ident($f)
  call.add quoted
  for i in 0..<n:
    call.add newTree(nnkBracketExpr, ident("s"), newLit(i))
  result = newTree(nnkLambda,
    newEmptyNode(),
    newEmptyNode(),
    newEmptyNode(),
    newTree(nnkFormalParams,
      ident("Signal"),
      newTree(nnkIdentDefs,
        ident("s"),
        newTree(nnkBracketExpr,
          ident("openarray"),
          ident("Signal")),
        newEmptyNode())),
    newEmptyNode(),
    newEmptyNode(),
    newStmtList(call))

proc Broadcast*(): TBroadcast =
  makeGate(TBroadcast)
  let updateFn = proc(s: openarray[Signal]): Signal = s[0]
  result.makeUpdate updateFn

proc Not*(): TNot =
  makeGate(TNot)
  result.makeUpdate signal.`!`.asSignalUpdater

proc And*(): TAnd =
  makeGate(TAnd)
  result.makeUpdate signal.`&`.asSignalUpdater

proc Or*(): TOr =
  makeGate(TOr)
  result.makeUpdate signal.`|`.asSignalUpdater

proc Xor*(): TXor =
  makeGate(TXor)
  result.makeUpdate signal.`^`.asSignalUpdater

proc Nand*(): TNand =
  makeGate(TNand)
  result.makeUpdate signal.`!&`.asSignalUpdater

proc Nor*(): TNor =
  makeGate(TNor)
  result.makeUpdate signal.`!|`.asSignalUpdater

proc Nxor*(): TNxor =
  makeGate(TNxor)
  result.makeUpdate signal.`!^`.asSignalUpdater
