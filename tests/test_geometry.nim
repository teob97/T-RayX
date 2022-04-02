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
  test "Test Vector operations":
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
    var m1_inv : Transformation = m1.inverse()
    var prod_m : Transformation = m1*m1_inv
    var m2 : Transformation = newTransformation(m1.m, m1.invm)
    var m3 : Transformation = newTransformation(m1.m, m1.invm)
    m3.m[10] += 1
    var m4 : Transformation = newTransformation(
                              m = [3.0, 5.0, 2.0, 4.0,
                                   4.0, 1.0, 0.0, 5.0,
                                   6.0, 3.0, 2.0, 0.0,
                                   1.0, 4.0, 2.0, 1.0],
                              invm = [0.4, -0.2, 0.2, -0.6,
                                      2.9, -1.7, 0.2, -3.1,
                                      -5.55, 3.15, -0.4, 6.45,
                                      -0.9, 0.7, -0.2, 1.1])
    var ex : Transformation = newTransformation(
                              m = [33.0, 32.0, 16.0, 18.0,
                                   89.0, 84.0, 40.0, 58.0,
                                   118.0, 106.0, 48.0, 88.0,
                                   63.0, 51.0, 22.0, 50.0],
                              invm = [-1.45, 1.45, -1.0, 0.6,
                                      -13.95, 11.95, -6.5, 2.6,
                                      25.525, -22.025, 12.25, -5.2,
                                      4.825, -4.325, 2.5, -1.1])
    var m5 : Transformation = newTransformation(
                              m = [1.0, 2.0, 3.0, 4.0,
                                   5.0, 6.0, 7.0, 8.0,
                                   9.0, 9.0, 8.0, 7.0,
                                   0.0, 0.0, 0.0, 1.0],
                              invm = [-3.75, 2.75, -1.0, 0.0,
                                      5.75, -4.75, 2.0, 1.0,
                                      -2.25, 2.25, -1.0, -2.0,
                                      0.0, 0.0, 0.0, 1.0])
    var ex_v : Vec = newVec(14.0, 38.0, 51.0)
    var ex_p : Point = newPoint(18.0, 46.0, 58.0)
    var ex_n : Normal = newNormal(-8.75, 7.75, -3.0)
    var tr1 : Transformation = translation(newVec(1.0, 2.0, 3.0))
    var tr2 : Transformation = translation(newVec(4.0, 6.0, 8.0))
    var prod_t : Transformation = tr1*tr2
    var ex_t : Transformation = translation(newVec(5.0, 8.0, 11.0))
    var r1_x : Transformation = rotation_x(0.1)
    var r1_y : Transformation = rotation_y(0.1)
    var r1_z : Transformation = rotation_z(0.1)
    var r2_x : Transformation = rotation_x(90.0)
    var r2_y : Transformation = rotation_y(90.0)
    var r2_z : Transformation = rotation_z(90.0)
    var s1 : Transformation = scaling(newVec(2.0, 5.0, 10.0))
    var s2 : Transformation = scaling(newVec(3.0, 2.0, 4.0))
    var ex_s : Transformation = scaling(newVec(6.0, 10.0, 40.0))

  test "Test isClose":
    check:
      m1.isConsistent() == true
      m3.isConsistent() == false
      m1.isClose(m2) == true
      m1.isClose(m3) == false
  test "Test Multiplication":
    check:
      m4.isConsistent() == true
      ex.isConsistent() == true
      ex.isClose(m1*m4) == true
  test "Test Vec Point Multiplication":
    check:
      ex_v.are_close(m5*newVec(1.0, 2.0, 3.0)) == true
      ex_p.are_close(m5*newPoint(1.0, 2.0, 3.0)) == true
      ex_n.are_close(m5*newNormal(3.0, 2.0, 4.0)) == true
  test "Teste Inverse":
    check:
      m1_inv.isConsistent() == true
      prod_m.isConsistent() == true
      prod_m.isClose(newTransformation()) == true
  test "Test Translations":
    check:
      tr1.isConsistent() == true
      tr2.isConsistent() == true
      prod_t.isConsistent() == true
      prod_t.isClose(ex_t) == true
  test "Test Scaling":
    check:
      s1.isConsistent() == true
      s2.isConsistent() == true
      ex_s.isClose(s1*s2) == true
  test "Test Rotations":
    check:
      r1_x.isConsistent() == true
      r1_y.isConsistent() == true
      r1_z.isConsistent() == true
      are_close(r2_x*VEC_Y, VEC_Z) == true
      are_close(r2_y*VEC_Z, VEC_X) == true
      are_close(r2_z*VEC_X, VEC_Y) == true
