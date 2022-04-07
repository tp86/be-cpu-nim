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

  test "logic":
    var
      signals = (S: L, R: L)
    let
      sourceS = Source(proc(): Signal = signals.S)
      sourceR = Source(proc(): Signal = signals.R)
      sinkQ = Sink()
      sinkQ̅ = Sink()

    sourceS.output ~~ sr.S
    sourceR.output ~~ sr.R
    sr.Q ~~ sinkQ.input
    sr.Q̅ ~~ sinkQ̅.input

    let cases = [
      (S: L, R: L, Q: L, Q̅: H),
      (S: L, R: H, Q: L, Q̅: H),
      (S: L, R: L, Q: L, Q̅: H),
      (S: H, R: L, Q: H, Q̅: L),
      (S: L, R: L, Q: H, Q̅: L),
      (S: H, R: L, Q: H, Q̅: L),
      (S: L, R: L, Q: H, Q̅: L),
      (S: L, R: H, Q: L, Q̅: H),
      (S: L, R: L, Q: L, Q̅: H),
    ]
    for c in cases:
      signals.S = c.S
      signals.R = c.R
      updateAll sourceS, sourceR
      check:
        sinkQ.input.signal == c.Q
        sinkQ̅.input.signal == c.Q̅
