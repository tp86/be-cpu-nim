type
  Signal* = enum
    H, L

func `!`*(signal: Signal): Signal =
  case signal:
  of H:
    result = L
  of L:
    result = H
