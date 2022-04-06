type
  Signal* = enum
    L, H

using
  s, s1, s2: Signal

func `!`*(s): Signal =
  case s:
  of H: L
  of L: H

func `&`*(s1, s2): Signal =
  result = L
  if s1 == H and s2 == H: return H

func `|`*(s1, s2): Signal =
  result = H
  if s1 == L and s2 == L: return L

func `^`*(s1, s2): Signal =
  result = H
  if s1 == s2: return L

func `!&`*(s1, s2): Signal =
  result = H
  if s1 == H and s2 == H: return L

func `!|`*(s1, s2): Signal =
  result = L
  if s1 == L and s2 == L: return H

func `!^`*(s1, s2): Signal =
  result = H
  if s1 != s2: return L
