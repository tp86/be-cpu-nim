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
    check:
      notGate.A.isInput
      notGate.A != nil
      notGate.B.isOutput
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
    check:
      andGate.A.isInput
      andGate.A != nil
      andGate.B.isInput
      andGate.B != nil
      andGate.C.isOutput
      andGate.C != nil
