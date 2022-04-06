type
  Signal* = enum
    L, H

func `!`*(signal: Signal): Signal =
  case signal:
  of H: L
  of L: H

func `&`*(signal1, signal2: Signal): Signal =
  result = L
  if signal1 == H and signal2 == H: return H

func `|`*(signal1, signal2: Signal): Signal =
  result = H
  if signal1 == L and signal2 == L: return L

func `^`*(signal1, signal2: Signal): Signal =
  result = H
  if signal1 == signal2: return L

func `!&`*(signal1, signal2: Signal): Signal =
  result = H
  if signal1 == H and signal2 == H: return L

func `!|`*(signal1, signal2: Signal): Signal =
  result = L
  if signal1 == L and signal2 == L: return H

func `!^`*(signal1, signal2: Signal): Signal =
  result = H
  if signal1 != signal2: return L
