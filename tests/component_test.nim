import std/unittest
import component
import gate
import signal

suite "SR latch":

  setup:
    let sr = SR()

  test "interface":
    check:
      sr.S is Input
      sr.R is Input
      sr.Q is Output
      sr.Q̅ is Output

  test "init":
    let
      source = Source(proc(): Signal = L)
      sinkQ = Sink()
      sinkQ̅ = Sink()

    source.output ~~ sr.S
    source.output ~~ sr.R
    sr.Q ~~ sinkQ.input
    sr.Q̅ ~~ sinkQ̅.input

    updateAll source
    check:
      sinkQ.input.signal == L
      sinkQ̅.input.signal == H
