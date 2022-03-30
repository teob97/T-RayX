import ../src/geometry
import std/unittest

suite "Test geometry.nim":
  setup:
    var a : Vec = newVec(1.0, 2.0, 3.0)
    var b : Vec = newVec(4.0, 6.0, 8.0)
  test "Test Vec":
    check:
      a.are_close(a) == true
    check:
      a.are_close(b) == false
  test "Test vector operations":
    check:
      (a.neg).are_close(newVec(-1.0, -2.0, -3.0))
    check:
      (a+b).are_close(newVec(5.0, 8.0, 11.0))
    check:
      (b-a).are_close(newVec(3.0, 4.0, 5.0))
    check:
      are_close(2*a, newVec(2.0, 4.0, 6.0))
    check:
      are_close(a*2, newVec(2.0, 4.0, 6.0))
    check:
      a.dot(b) - 40.0 < 1e-6

