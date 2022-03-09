import ../src/tools

when isMainModule:
    assert newColor(1.0, 2.0, 3.0) + newColor(3.0, 4.0, 5.0) == newColor(4.0, 6.0, 8.0)
    assert newColor(6.0, 4.0, 5.0) - newColor(1.0, 2.0, 3.0) == newColor(5.0, 2.0, 2.0)
