import std/unittest
import signal

suite "signals":

  test "negation":
    check:
      !H == L
      !L == H
