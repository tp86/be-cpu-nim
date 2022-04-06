import std/unittest
import connection

suite "connections":
  setup:
    let
      input = newInput()
      output = newOutput()

  test "output connects to input":
    output.connect(input)

  test "only one connection to input":
    output.connect(input)
    expect(ConnectionError):
      output.connect(input)

  test "output multiple connections":
    let input2 = newInput()
    output.connect(input)
    output.connect(input2)

import signal

suite "input":
  setup:
    let input = newInput()

  test "input has a signal value":
    check:
      typeOf(input.signal) is Signal

  test "default signal value is low":
    check:
      input.signal == L

  test "has parent (gate)":
    skip

suite "output":
  setup:
    let output = newOutput()

  test "propagates signal change":
    # this test would not be correct if output propagated signal on connection as well
    let input = newInput()
    output.connect(input)
    discard output.propagate(L)
    check input.signal == L
    discard output.propagate(H)
    check input.signal == H
    let input2 = newInput()
    output.connect(input2)
    # this should not be propagated as signal didn't change
    discard output.propagate(H)
    # input2 should still have default signal
    check input2.signal == L

  test "propagates signal to all connected inputs":
    let
      input1 = newInput()
      input2 = newInput()
    output.connect(input1)
    output.connect(input2)
    discard output.propagate(H)
    check:
      input1.signal == H
      input2.signal == H

  test "returns inputs to which signal was propagated":
    let
      input1 = newInput()
      input2 = newInput()
    output.connect(input1)
    output.connect(input2)
    let inputs = output.propagate(H)
    check inputs == @[input1, input2]

  test "does not propagate signal on connection":
    # connections are not meant to be made dynamically
    let input = newInput()
    output.connect(input)
    discard output.propagate(H)
    let input2 = newInput()
    output.connect(input2)
    check input2.signal == L
