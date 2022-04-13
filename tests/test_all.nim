import ../src/basictypes
import ../src/pfm
import ../src/ldr
import ../src/geometry
import ../src/transformation
import ../src/cameras
import std/options
import std/unittest
import std/streams

#################
#TEST BASICTYPES#
#################

suite "Test basictypes.nim":
  setup:
    var img = newHdrImage(7,4)
    var reference_color = newColor(1.0, 2.0, 3.0)
  test "Test getPixel":
    expect IOError:
      var test = img.getPixel(1,-3)
  test "Test Image Creation":
    check:
      img.width == 7
      img.height == 4
  test "Test validCoordinates":
    check:
      test_valid_coordinates(img, 0, 0)
      test_valid_coordinates(img, 6, 3)
      test_valid_coordinates(img, -1, 0) == false
      test_valid_coordinates(img, 0, -1) == false
      test_valid_coordinates(img, 7, 0) == false
      test_valid_coordinates(img, 0, 4) == false
  test "Test pixelOffset":
    check:
      pixelOffset(img, 0, 0) == 0
      pixelOffset(img, 3, 2) == 17
      pixelOffset(img, 6, 3) == 7 * 4 - 1
  test "Test getPixel/setPixel":
    setPixel(img, 3, 2, reference_color)
    check:
      areClose(reference_color, img.getPixel(3, 2))

##########
#TEST PFM#
##########

proc toString(bytes: openarray[byte]): string =
  result = newString(bytes.len)
  copyMem(result[0].addr, bytes[0].unsafeAddr, bytes.len)

suite "Test pfm.nim":
  setup:
    var img_test = newHdrImage(3,2)
    const le_ref_bytes = [byte 0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x2d, 0x31, 0x2e, 0x30, 0x0a,
      0x00, 0x00, 0xc8, 0x42, 0x00, 0x00, 0x48, 0x43, 0x00, 0x00, 0x96, 0x43,
      0x00, 0x00, 0xc8, 0x43, 0x00, 0x00, 0xfa, 0x43, 0x00, 0x00, 0x16, 0x44,
      0x00, 0x00, 0x2f, 0x44, 0x00, 0x00, 0x48, 0x44, 0x00, 0x00, 0x61, 0x44,
      0x00, 0x00, 0x20, 0x41, 0x00, 0x00, 0xa0, 0x41, 0x00, 0x00, 0xf0, 0x41,
      0x00, 0x00, 0x20, 0x42, 0x00, 0x00, 0x48, 0x42, 0x00, 0x00, 0x70, 0x42,
      0x00, 0x00, 0x8c, 0x42, 0x00, 0x00, 0xa0, 0x42, 0x00, 0x00, 0xb4, 0x42]
    const be_ref_bytes = [byte 0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x31, 0x2e, 0x30, 0x0a, 0x42,
      0xc8, 0x00, 0x00, 0x43, 0x48, 0x00, 0x00, 0x43, 0x96, 0x00, 0x00, 0x43,
      0xc8, 0x00, 0x00, 0x43, 0xfa, 0x00, 0x00, 0x44, 0x16, 0x00, 0x00, 0x44,
      0x2f, 0x00, 0x00, 0x44, 0x48, 0x00, 0x00, 0x44, 0x61, 0x00, 0x00, 0x41,
      0x20, 0x00, 0x00, 0x41, 0xa0, 0x00, 0x00, 0x41, 0xf0, 0x00, 0x00, 0x42,
      0x20, 0x00, 0x00, 0x42, 0x48, 0x00, 0x00, 0x42, 0x70, 0x00, 0x00, 0x42,
      0x8c, 0x00, 0x00, 0x42, 0xa0, 0x00, 0x00, 0x42, 0xb4, 0x00, 0x00]  
  test "Test parseImgSize":
    check:
      parseImgSize("2 3") == (2,3)
    expect InvalidPfmFileFormat:
      var test1 = parseImgSize("-2 3")
      var test2 = parseImgSize("2 2 8")
  test "Test parseEndiannes":
    check:
      parseEndianness("-20.4") == -1.0
      parseEndianness("49.8") == 1.0
    expect InvalidPfmFileFormat:
      var test1 = parseEndianness("")
      var test2 = parseEndianness("0")
  test "Test readPfmImage_le":
    var buffer = toString(le_ref_bytes)
    var stream = newStringStream(buffer)
    var img = readPfmImage(stream)
    check:
      img.width == 3
      img.height == 2
      img.getPixel(0, 0).areClose(newColor(1.0e1, 2.0e1, 3.0e1))
      img.getPixel(1, 0).areClose(newColor(4.0e1, 5.0e1, 6.0e1))
      img.getPixel(2, 0).areClose(newColor(7.0e1, 8.0e1, 9.0e1))
      img.getPixel(0, 1).areClose(newColor(1.0e2, 2.0e2, 3.0e2))
      img.getPixel(1, 1).areClose(newColor(4.0e2, 5.0e2, 6.0e2))
      img.getPixel(2, 1).areClose(newColor(7.0e2, 8.0e2, 9.0e2))
  test "Test readPfmImage_be":
    var buffer = toString(be_ref_bytes)
    var stream = newStringStream(buffer)
    var img = readPfmImage(stream)
    check:
      img.width == 3
      img.height == 2
      img.getPixel(0, 0).areClose(newColor(1.0e1, 2.0e1, 3.0e1))
      img.getPixel(1, 0).areClose(newColor(4.0e1, 5.0e1, 6.0e1))
      img.getPixel(2, 0).areClose(newColor(7.0e1, 8.0e1, 9.0e1))
      img.getPixel(0, 1).areClose(newColor(1.0e2, 2.0e2, 3.0e2))
      img.getPixel(1, 1).areClose(newColor(4.0e2, 5.0e2, 6.0e2))
      img.getPixel(2, 1).areClose(newColor(7.0e2, 8.0e2, 9.0e2))
  test "Test readPfmImage_execption":
    expect InvalidPfmFileFormat :
      let buf = newStringStream("PokoF\n3 2\n-1.0\nstop")
      var img_2 = readPfmImage(buf)
  test "Test writePfmImage":
    img_test.setPixel(0, 0, newColor(1.0e1, 2.0e1, 3.0e1)) 
    img_test.setPixel(1, 0, newColor(4.0e1, 5.0e1, 6.0e1)) 
    img_test.setPixel(2, 0, newColor(7.0e1, 8.0e1, 9.0e1)) 
    img_test.setPixel(0, 1, newColor(1.0e2, 2.0e2, 3.0e2))
    img_test.setPixel(1, 1, newColor(4.0e2, 5.0e2, 6.0e2))
    img_test.setPixel(2, 1, newColor(7.0e2, 8.0e2, 9.0e2))
    var stream = newStringStream("")
    var buffer = be_ref_bytes
    writePfmImage(img_test, stream, 1.0)
    stream.setPosition(0)
    var buffer2: array[sizeof(buffer), byte]
    var stuff = stream.readData(addr(buffer2), sizeof(buffer2)) 
    check:
      buffer2 == buffer

##########
#TEST LDR#
##########

suite "Test ldr.nim":
  setup:
    let c1 = newColor(1.0, 2.0, 3.0)
    let c2 = newColor(9.0, 5.0, 7.0)
    var img : HdrImage = newHdrImage(2, 1)
  test "Test luminosity":
    check:
      luminosity(c1) == 2.0
      luminosity(c2) == 7.0
  test "Test averageLuminosity":
    setPixel(img, 0, 0, newColor(5.0, 10.0, 15.0))
    setPixel(img, 1, 0, newColor(500.0, 1000.0, 1500.0))
    check:
      averageLuminosity(img, delta=0.0) == 100.0
  test "Test normalizeImage":
    setPixel(img, 0, 0, newColor(5.0, 10.0, 15.0))
    setPixel(img, 1, 0, newColor(500.0, 1000.0, 1500.0))
    normalizeImage(img, factor=1000.0, luminosity=some(100.0))
    check:
      areClose(getPixel(img, 0, 0), newColor(0.5e2, 1.0e2, 1.5e2))
      areClose(getPixel(img, 1, 0), newColor(0.5e4, 1.0e4, 1.5e4))
  test "Test clampImage":
    setPixel(img, 0, 0, newColor(0.5e1, 1.0e1, 1.5e1))
    setPixel(img, 1, 0, newColor(0.5e3, 1.0e3, 1.5e3))
    clampImage(img)
    for pixel in img.pixels:
      check:
        (pixel.r >= 0) and (pixel.r <= 1)
        (pixel.g >= 0) and (pixel.g <= 1)
        (pixel.b >= 0) and (pixel.b <= 1)

###############
#TEST GEOMETRY#
###############

suite "Test geometry.nim":
  setup:
    var a : Vec = newVec(1.0, 2.0, 3.0)
    var b : Vec = newVec(4.0, 6.0, 8.0)
    var p1 : Point = newPoint(1.0, 2.0, 3.0)
    var p2 : Point = newPoint(4.0, 6.0, 8.0)
  test "Test Vec":
    check:
      a.areClose(a) == true
      a.areClose(b) == false
  test "Test Vector Operations":
    check:
      (-a).areClose(newVec(-1.0, -2.0, -3.0))
      (a+b).areClose(newVec(5.0, 8.0, 11.0))
      (b-a).areClose(newVec(3.0, 4.0, 5.0))
      areClose(2*a, newVec(2.0, 4.0, 6.0))
      areClose(a*2, newVec(2.0, 4.0, 6.0))
      a.dot(b) - 40.0 < 1e-6
      areClose(a.cross(b), newVec(-2.0, 4.0, -2.0))
      areClose(b.cross(a), newVec(2.0, -4.0, 2.0))
      a.squared_norm() - 14.0 < 1e-6
      a.norm()*a.norm() - 14.0 < 1e-6
  test "Test Point":
    check:
      p1.areClose(p1) == true
      p2.areClose(p1) == false
  test "Test Point Operations":
    check:
      areClose(p1*2, newPoint(2.0, 4.0, 6.0))
      areClose(p1+b, newPoint(5.0, 8.0, 11.0))
      areClose(p2-p1, newVec(3.0, 4.0, 5.0))
      areClose(p1-b, newPoint(-3.0, -4.0, -5.0)) 

#####################
#TEST TRANSFOTMATION#
#####################

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
  test "Test Is Close":
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
      ex_v.areClose(m5*newVec(1.0, 2.0, 3.0)) == true
      ex_p.areClose(m5*newPoint(1.0, 2.0, 3.0)) == true
      ex_n.areClose(m5*newNormal(3.0, 2.0, 4.0)) == true
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
      areClose(r2_x*VEC_Y, VEC_Z) == true
      areClose(r2_y*VEC_Z, VEC_X) == true
      areClose(r2_z*VEC_X, VEC_Y) == true

##############
#TEST CAMERAS#
##############

proc areClose(a,b : float): bool = 
  return abs(a-b)<1e-5

suite "Test cameras.nim":
  setup:
    var
      ray1 : Ray = newRay(origin = newPoint(1.0, 2.0, 3.0), dir = newVec(5.0, 4.0, -1.0))
      ray2 : Ray = newRay(origin = newPoint(1.0, 2.0, 3.0), dir = newVec(5.0, 4.0, -1.0))
      ray3 : Ray = newRay(origin = newPoint(5.0, 1.0, 4.0), dir = newVec(3.0, 9.0, 4.0))
      ray4 : Ray = newRay(origin = newPoint(1.0, 2.0, 4.0), dir = newVec(4.0, 2.0, 1.0))
      ray5 : Ray = newRay(origin = newPoint(1.0, 2.0, 3.0), dir = newVec(6.0, 5.0, 4.0))
      transformation : Transformation = translation(newVec(10.0, 11.0, 12.0)) * rotation_x(90.0)
      transformed : Ray = ray5 * transformation
      cam : OrthogonalCamera = newOrthogonalCamera(aspect_ratio = 2.0)
      ray1f : Ray = cam.fireRay(0.0, 0.0)
      ray2f : Ray = cam.fireRay(1.0, 0.0)
      ray3f : Ray = cam.fireRay(0.0, 1.0)
      ray4f : Ray = cam.fireRay(1.0, 1.0)
      image : HdrImage = newHdrImage(width = 4, height = 2)
      tracer : ImageTracer = newImageTracer(image = image, camera = cam)
      ray1t : Ray = tracer.fire_ray(0, 0, u_pixel = 2.5, v_pixel = 1.5)
      ray2t : Ray = tracer.fire_ray(2, 1, u_pixel = 0.5, v_pixel = 0.5)
  test "Test Ray":
    check:
      areClose(ray1, ray2)
      areClose(ray1, ray3) == false 
      areClose(ray4.at(0.0), ray4.origin)
      areClose(ray4.at(1.0), newPoint(5.0, 4.0, 5.0))
      areClose(ray4.at(2.0), newPoint(9.0, 6.0, 6.0))
      areClose(transformed.origin, newPoint(11.0, 8.0, 14.0))
      areClose(transformed.dir, newVec(6.0, -4.0, 5.0))
  test "Test OrthogonalCamera":
    check:
      #verify that the rays are parallel
      areClose(0.0, ray1f.dir.cross(ray2f.dir).squared_norm())
      areClose(0.0, ray1f.dir.cross(ray3f.dir).squared_norm())
      areClose(0.0, ray1f.dir.cross(ray4f.dir).squared_norm())
      #verify that the ray hitting the corners have the right coordinates
      areClose(ray1f.at(1.0), newPoint(0.0, 2.0, -1.0))
      areClose(ray2f.at(1.0), newPoint(0.0, -2.0, -1.0))
      areClose(ray3f.at(1.0), newPoint(0.0, 2.0, 1.0))
      areClose(ray4f.at(1.0), newPoint(0.0, -2.0, 1.0))
  test "Test ImageTracer":
    check:
      areClose(ray1t, ray2t)
