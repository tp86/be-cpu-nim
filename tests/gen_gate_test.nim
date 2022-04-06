import std/unittest
import signal as s
import gen_gate

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
