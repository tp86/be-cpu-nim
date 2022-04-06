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
    skip

  test "propagates signal to all connected inputs":
    skip

  test "returns inputs to which signal was propagated":
    skip
