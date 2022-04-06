import std/unittest
import signal
import gate

suite "gate connections":

  setup:
    let
      source = newConstantSource()
      sink = newSink()

  test "gates can be connected":
    source.output ~~ sink.input

  test "gate input may be connected to only once":
    let source2 = newConstantSource()
    source.output ~~ sink.input
    expect(ConnectionError):
      source2.output ~~ sink.input

  test "gate output may be connected to multiple inputs":
    let sink2 = newSink()
    source.output ~~ sink.input
    source.output ~~ sink2.input

  test "output cannot be connected to output":
    let source2 = newConstantSource()
    expect(ConnectionError):
      source.output ~~ source2.output

  test "input cannot be connected to output":
    expect(ConnectionError):
      sink.input ~~ source.output

  test "input cannot be connected to input":
    let sink2 = newSink()
    expect(ConnectionError):
      sink.input ~~ sink2.input

suite "gate signal propagation":

  test "default (unconnected) input signal value is low":
    let sink = newSink()
    check sink.input.signal == L

  test "source gate propagates signal change on update":
    var signal = L
    let
      source = newSource(proc(): Signal = signal)
      sink1 = newSink()
      sink2 = newSink()

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
      source = newConstantSource(H)
      sink1 = newSink()
      sink2 = newSink()

    source.output ~~ sink1.input
    source.output ~~ sink2.input
    check:
      sink1.input.signal == L
      sink2.input.signal == L
    discard source.update
    check:
      sink1.input.signal == H
      sink2.input.signal == H

  test "source gate returns connected gates on changed signal propagation":
    let
      source = newConstantSource(H)
      sink1 = newSink()
      sink2 = newSink()

    source.output ~~ sink1.input
    source.output ~~ sink2.input
    let gates = source.update
    check gates == @[sink1, sink2]

  test "gate does not propagate signal on connection":
    let
      source = newConstantSource(H)
      sink = newSink()

    source.output ~~ sink.input
    check sink.input.signal == L

suite "gates":

  test "not gate interface":
    let notGate = newNot()
    discard notGate.A.Input
    discard notGate.B.Output
    check:
      notGate.A != nil
      notGate.B != nil

  test "not gate logic":
    var signal: Signal
    let
      source = newSource(proc(): Signal = signal)
      notGate = newNot()
      sink = newSink()

    source.output ~~ notGate.A
    notGate.B ~~ sink.input
    signal = L
    discard source.update
    discard notGate.update
    check sink.input.signal == H
    signal = H
    discard source.update
    discard notGate.update
    check sink.input.signal == L

  test "and gate interface":
    let andGate = newAnd()
    discard andGate.A.Input
    discard andGate.B.Input
    discard andGate.C.Output
    check:
      andGate.A != nil
      andGate.B != nil
      andGate.C != nil

  proc check(gateConstructor: proc (): Gate,
             testCases: openarray[tuple[a, b, expected: Signal]]) =
    var signalA, signalB: Signal
    let
      sourceA = newSource(proc(): Signal = signalA)
      sourceB = newSource(proc(): Signal = signalB)
      sink = newSink()
      gate = gateConstructor()

    sourceA.output ~~ gate.A
    sourceB.output ~~ gate.B
    gate.C ~~ sink.input

    for signals in testCases:
      signalA = signals.a
      signalB = signals.b
      discard sourceA.update
      discard sourceB.update
      discard gate.update
      check sink.input.signal == signals.expected

  test "and gate logic":
    check(newAnd, [
      (L, L, L),
      (L, H, L),
      (H, L, L),
      (H, H, H),
    ])
