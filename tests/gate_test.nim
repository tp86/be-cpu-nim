import std/[sequtils, unittest]
import connection
import signal
import gate

suite "gates":

  test "not gate interface":
    let notGate = newNot()
    check:
      typeOf(notGate.A) is Input
      typeOf(notGate.B) is Output

  test "not gate logic":
    let notGate = newNot()
    let source = newOutput()
    let probe = newInput()
    source.connect(notGate.A)
    notGate.B.connect(probe)
    discard source.propagate(L)
    discard notGate.update
    check probe.signal == H
    discard source.propagate(H)
    discard notGate.update
    check probe.signal == L

