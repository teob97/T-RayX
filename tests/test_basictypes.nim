import ../src/tools.nim

when isMainModule:
    assert Color(1.0, 2.0, 3.0) + Color(3.0, 4.0, 5.0) == Color(5.0, 6.0, 8.0)
    assert Color(6.0, 4.0, 5.0) - Color(1.0, 2.0, 3.0) == Color(7.0, 2.0, 2.0)
