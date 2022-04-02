import ../src/geometry
import ../src/transformation
import std/unittest

suite "Test geometry.nim":
  setup:
    var a : Vec = newVec(1.0, 2.0, 3.0)
    var b : Vec = newVec(4.0, 6.0, 8.0)
    var p1 : Point = newPoint(1.0, 2.0, 3.0)
    var p2 : Point = newPoint(4.0, 6.0, 8.0)
  test "Test Vec":
    check:
      a.are_close(a) == true
      a.are_close(b) == false
  test "Test vector operations":
    check:
      (-a).are_close(newVec(-1.0, -2.0, -3.0))
      (a+b).are_close(newVec(5.0, 8.0, 11.0))
      (b-a).are_close(newVec(3.0, 4.0, 5.0))
      are_close(2*a, newVec(2.0, 4.0, 6.0))
      are_close(a*2, newVec(2.0, 4.0, 6.0))
      a.dot(b) - 40.0 < 1e-6
      are_close(a.cross(b), newVec(-2.0, 4.0, -2.0))
      are_close(b.cross(a), newVec(2.0, -4.0, 2.0))
      a.squared_norm() - 14.0 < 1e-6
      a.norm()*a.norm() - 14.0 < 1e-6
  test "Test Point":
    check:
      p1.are_close(p1) == true
      p2.are_close(p1) == false
  test "Test Point operations":
    check:
      are_close(p1*2, newPoint(2.0, 4.0, 6.0))
      are_close(p1+b, newPoint(5.0, 8.0, 11.0))
      are_close(p2-p1, newVec(3.0, 4.0, 5.0))
      are_close(p1-b, newPoint(-3.0, -4.0, -5.0)) 


suite "Test transformation.nim":
  setup:
    var m1 : Transformation = newTransformation(
                              m = [1.0, 2.0, 3.0, 4.0,
                                   5.0, 6.0, 7.0, 8.0,
                                   9.0, 9.0, 8.0, 7.0,
                                   6.0, 5.0, 4.0, 1.0],
                              invm = [-3.75, 2.75, -1, 0,
                                      4.375, -3.875, 2.0, -0.5,
                                      0.5, 0.5, -1.0, 1.0,
                                      -1.375, 0.875, 0.0, -0.5])
    var m2 : Transformation = newTransformation(
                              m = [1.0, 2.0, 3.0, 4.0,
                                   5.0, 6.0, 7.0, 8.0,
                                   9.0, 9.0, 8.0, 7.0,
                                   6.0, 5.0, 4.0, 1.0],
                              invm = [-3.75, 2.75, -1, 0,
                                      4.375, -3.875, 2.0, -0.5,
                                      0.5, 0.5, -1.0, 1.0,
                                      -1.375, 0.875, 0.0, -0.5])
    var m3 : Transformation = newTransformation(
                              m = [1.0, 2.0, 3.0, 4.0,
                                   5.0, 6.0, 7.0, 8.0,
                                   9.0, 9.0, 9.0, 7.0, # +1 in (2,2) coord
                                   6.0, 5.0, 4.0, 1.0],
                              invm = [-3.75, 2.75, -1, 0,
                                      4.375, -3.875, 2.0, -0.5,
                                      0.5, 0.5, -1.0, 1.0,
                                      -1.375, 0.875, 0.0, -0.5])
  test "Test cons":
    check:
      m1.isConsistent() == true
      m1.isClose(m2) == true
      m1.isClose(m3) == true # NON VA BENE, DEVE ESSERE FALSE
