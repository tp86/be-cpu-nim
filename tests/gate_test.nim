import std/[sequtils, unittest]
import signal as s
import gate

var signal = L
proc getSignal(): Signal = signal
var output: Signal
proc setResult(s: Signal) = output = s

suite "connections":

  setup:
    let
      source = Source(getSignal)
      sink = Sink()

  test "gates can be connected":
    source.output ~~ sink.input

  test "gate input may be connected to only once":
    let source2 = Source(getSignal)
    source.output ~~ sink.input
    expect(ConnectionError):
      source2.output ~~ sink.input

  test "gate output may be connected to multiple inputs":
    let sink2 = Sink()
    source.output ~~ sink.input
    source.output ~~ sink2.input

suite "signal propagation":

  test "default (unconnected) input signal value is low":
    let sink = Sink(setResult)
    updateAll sink
    check output == L

  test "source gate propagates signal change on update":
    let
      source = Source(getSignal)
      sink1 = Sink(setResult)

    signal = L
    updateAll sink1
    check output == L
    source.output ~~ sink1.input
    updateAll source
    check output == L
    signal = H
    updateAll source
    check output == H

  test "source gate propagates signal on update to all connected inputs":
    var
      out1, out2: Signal
    let
      source = Source(getSignal)
      sink1 = Sink(proc(s: Signal) = out1 = s)
      sink2 = Sink(proc(s: Signal) = out2 = s)

    source.output ~~ sink1.input
    source.output ~~ sink2.input
    updateAll sink1, sink2
    check:
      out1 == L
      out2 == L
    signal = H
    updateAll source
    check:
      out1 == H
      out2 == H

#[
  test "source gate returns connected gates on changed signal propagation":
    let
      source = Source(getSignal)
      sink1 = Sink()
      sink2 = Sink()

    source.output ~~ sink1.input
    source.output ~~ sink2.input
    let gates = source.update
    check gates.len == 2
]#

  test "gate propagates signal on connection":
    let
      source = Source(getSignal)
      sink = Sink(setResult)

    signal = H
    updateAll source
    source.output ~~ sink.input
    check output == H

#[
  test "source gate always propagates on first update":
    let
      source = Source(getSignal)
      sink = Sink()

    source.output ~~ sink.input
    var next = source.update
    check next.len > 0
    next = source.update
    check next.len == 0
]#

suite "broadcast":

  setup:
    let g = Broadcast()

  test "interface":
    check:
      g.input is Input
      g.output is Output

  test "logic":
    let
      source = Source(getSignal)
      sink = Sink(setResult)
    source.output ~~ g.input
    g.output ~~ sink.input

    signal = L
    updateAll source
    check output == L

    signal = H
    updateAll source
    check output == H

suite "not":

  setup:
    let g = Not()

  test "interface":
    check:
      g.A is Input
      g.B is Output

  test "logic":
    let
      source = Source(getSignal)
      sink = Sink(setResult)
    source.output ~~ g.A
    g.B ~~ sink.input

    signal = L
    updateAll source
    check output == H

    signal = H
    updateAll source
    check output == L

template testLogic(g: untyped, cases: openarray[(array[2, Signal], Signal)]) =
  var signalA, signalB: Signal
  let
    sourceA = Source(proc(): Signal = signalA)
    sourceB = Source(proc(): Signal = signalB)
    sink = Sink(setResult)
  sourceA.output ~~ g.A
  sourceB.output ~~ g.B
  g.C ~~ sink.input

  for (inputs, expected) in cases:
    signalA = inputs[0]
    signalB = inputs[1]
    updateAll sourceA, sourceB
    check output == expected

suite "and":

  setup:
    let g = And()

  test "interface":
    check:
      g.A is Input
      g.B is Input
      g.C is Output

  test "logic":
    let cases = [
      ([L, L], L),
      ([L, H], L),
      ([H, L], L),
      ([H, H], H),
    ]
    testLogic g, cases

suite "or":

  setup:
    let g = Or()

  test "interface":
    check:
      g.A is Input
      g.B is Input
      g.C is Output

  test "logic":
    let cases = [
      ([L, L], L),
      ([L, H], H),
      ([H, L], H),
      ([H, H], H),
    ]
    testLogic g, cases

suite "xor":

  setup:
    let g = Xor()

  test "interface":
    check:
      g.A is Input
      g.B is Input
      g.C is Output

  test "logic":
    let cases = [
      ([L, L], L),
      ([L, H], H),
      ([H, L], H),
      ([H, H], L),
    ]
    testLogic g, cases

suite "nand":

  setup:
    let g = Nand()

  test "interface":
    check:
      g.A is Input
      g.B is Input
      g.C is Output

  test "logic":
    let cases = [
      ([L, L], H),
      ([L, H], H),
      ([H, L], H),
      ([H, H], L),
    ]
    testLogic g, cases

suite "nor":

  setup:
    let g = Nor()

  test "interface":
    check:
      g.A is Input
      g.B is Input
      g.C is Output

  test "logic":
    let cases = [
      ([L, L], H),
      ([L, H], L),
      ([H, L], L),
      ([H, H], L),
    ]
    testLogic g, cases

suite "nxor":

  setup:
    let g = Nxor()

  test "interface":
    check:
      g.A is Input
      g.B is Input
      g.C is Output

  test "logic":
    let cases = [
      ([L, L], H),
      ([L, H], L),
      ([H, L], L),
      ([H, H], H),
    ]
    testLogic g, cases
