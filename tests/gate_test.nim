import std/[sequtils, unittest]
import signal as s
import gate

var signal = L
proc getSignal(_: varargs[Signal]): Signal = signal

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
    let sink = Sink()
    check sink.input.signal == L

  test "source gate propagates signal change on update":
    let
      source = Source(getSignal)
      sink1 = Sink()
      sink2 = Sink()

    check sink1.input.signal == L
    source.output ~~ sink1.input
    discard source.update
    check sink1.input.signal == L
    signal = H
    discard source.update
    check sink1.input.signal == H
    source.output ~~ sink2.input
    # not propagated on connection
    check sink2.input.signal == L
    discard source.update
    # not propagated since signal hasn't changed
    check sink2.input.signal == L
    signal = L
    discard source.update
    check sink2.input.signal == L
    signal = H
    discard source.update
    check sink2.input.signal == H

  test "source gate propagates signal on update to all connected inputs":
    let
      source = Source(getSignal)
      sink1 = Sink()
      sink2 = Sink()

    source.output ~~ sink1.input
    source.output ~~ sink2.input
    check:
      sink1.input.signal == L
      sink2.input.signal == L
    signal = H
    discard source.update
    check:
      sink1.input.signal == H
      sink2.input.signal == H

  test "source gate returns connected gates on changed signal propagation":
    let
      source = Source(getSignal)
      sink1 = Sink()
      sink2 = Sink()

    source.output ~~ sink1.input
    source.output ~~ sink2.input
    let gates = source.update
    check gates.len == 2

  test "gate does not propagate signal on connection":
    let
      source = Source(getSignal)
      sink = Sink()

    signal = H
    source.output ~~ sink.input
    check sink.input.signal == L

  test "source gate always propagates on first update":
    let
      source = Source(getSignal)
      sink = Sink()

    source.output ~~ sink.input
    var next = source.update
    check next.len > 0
    next = source.update
    check next.len == 0

proc updateAll(fromElements: varargs[Element]) =
  var elements = @fromElements
  while elements.len > 0:
    var next: seq[Element] = @[]
    for element in elements:
      next.add element.update
    elements = next.deduplicate

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
      sink = Sink()
    source.output ~~ g.input
    g.output ~~ sink.input

    signal = L
    updateAll source
    check sink.input.signal == L

    signal = H
    updateAll source
    check sink.input.signal == H

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
      sink = Sink()
    source.output ~~ g.A
    g.B ~~ sink.input

    signal = L
    updateAll source
    check sink.input.signal == H

    signal = H
    updateAll source
    check sink.input.signal == L

template testLogic(g: Element, cases: openarray[(array[2, Signal], Signal)]) =
  var signalA, signalB: Signal
  let
    sourceA = Source(proc(_: varargs[Signal]): Signal = signalA)
    sourceB = Source(proc(_: varargs[Signal]): Signal = signalB)
    sink = Sink()
  sourceA.output ~~ g.A
  sourceB.output ~~ g.B
  g.C ~~ sink.input

  for (inputs, expected) in cases:
    signalA = inputs[0]
    signalB = inputs[1]
    updateAll sourceA, sourceB
    check sink.input.signal == expected

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
