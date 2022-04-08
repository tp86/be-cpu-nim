import std/unittest
import component
import gate
import signal

suite "SR latch":

  setup:
    var q, q̅: Signal
    let
      sr = SR()
      sinkQ = Sink(proc(s: varargs[Signal]) = q = s[0])
      sinkQ̅ = Sink(proc(s: varargs[Signal]) = q̅ = s[0])

  test "interface":
    check:
      sr.S is Input
      sr.R is Input
      sr.Q is Output
      sr.Q̅ is Output

  test "init":
    let source = Source(proc(): Signal = L)

    source.output ~~ sr.S
    source.output ~~ sr.R
    sr.Q ~~ sinkQ.input
    sr.Q̅ ~~ sinkQ̅.input

    updateAll source
    check:
      q == L
      q̅ == H

  test "logic":
    var
      signals = (S: L, R: L)
    let
      sourceS = Source(proc(): Signal = signals.S)
      sourceR = Source(proc(): Signal = signals.R)

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
        q == c.Q
        q̅ == c.Q̅

suite "D latch":

  setup:
    var q, q̅: Signal
    let
      d = D()
      sinkQ = Sink(proc(s: varargs[Signal]) = q = s[0])
      sinkQ̅ = Sink(proc(s: varargs[Signal]) = q̅ = s[0])

  test "interface":
    check:
      d.D is Input
      d.EN is Input
      d.Q is Output
      d.Q̅ is Output

  test "init":
    let source = Source(proc(): Signal = L)

    source.output ~~ d.D
    source.output ~~ d.EN
    d.Q ~~ sinkQ.input
    d.Q̅ ~~ sinkQ̅.input

    updateAll source
    check:
      q == L
      q̅ == H

  test "logic":
    var
      signals = (D: L, EN: L)
    let
      sourceD = Source(proc(): Signal = signals.D)
      sourceEN = Source(proc(): Signal = signals.EN)

    sourceD.output ~~ d.D
    sourceEN.output ~~ d.EN
    d.Q ~~ sinkQ.input
    d.Q̅ ~~ sinkQ̅.input

    let cases = [
      (D: L, EN: L, Q: L, Q̅: H),
      (D: H, EN: L, Q: L, Q̅: H),
      (D: L, EN: L, Q: L, Q̅: H),
      (D: L, EN: H, Q: L, Q̅: H),
      (D: L, EN: L, Q: L, Q̅: H),
      (D: H, EN: L, Q: L, Q̅: H),
      (D: H, EN: H, Q: H, Q̅: L),
      (D: H, EN: L, Q: H, Q̅: L),
      (D: L, EN: L, Q: H, Q̅: L),
      (D: L, EN: H, Q: L, Q̅: H),
      (D: H, EN: H, Q: H, Q̅: L),
      (D: L, EN: H, Q: L, Q̅: H),
      (D: L, EN: L, Q: L, Q̅: H),
    ]
    for c in cases:
      signals.D = c.D
      signals.EN = c.EN
      updateAll sourceD, sourceEN
      check:
        q == c.Q
        q̅ == c.Q̅
