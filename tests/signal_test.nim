import std/unittest
import signal

suite "signals":

  test "negation":
    check:
      !H == L
      !L == H

  test "and logic":
    check:
      L & L == L
      L & H == L
      H & L == L
      H & H == H

  test "or logic":
    check:
      L | L == L
      L | H == H
      H | L == H
      H | H == H

  test "xor logic":
    check:
      L ^ L == L
      L ^ H == H
      H ^ L == H
      H ^ H == L

  test "nand logic":
    check:
      L !& L == H
      L !& H == H
      H !& L == H
      H !& H == L

  test "nor logic":
    check:
      L !| L == H
      L !| H == L
      H !| L == L
      H !| H == L

  test "nxor logic":
    check:
      L !^ L == H
      L !^ H == L
      H !^ L == L
      H !^ H == H
