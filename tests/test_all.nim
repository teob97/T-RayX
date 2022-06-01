import std/[unittest, options, streams, tables]
import ../src/basictypes
import ../src/pfm
import ../src/ldr
import ../src/geometry
import ../src/transformation
import ../src/cameras
import ../src/imagetracer
import ../src/shapes
import ../src/materials
import ../src/pcg
import ../src/renderer
import ../src/scenefiles

#################
#TEST BASICTYPES#
#################

suite "Test basictypes.nim":
  setup:
    var
      img = newHdrImage(7,4)
      reference_color = newColor(1.0, 2.0, 3.0)
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
      not test_valid_coordinates(img, -1, 0)
      not test_valid_coordinates(img, 0, -1)
      not test_valid_coordinates(img, 7, 0)
      not test_valid_coordinates(img, 0, 4)
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
      var
        test1 = parseImgSize("-2 3")
        test2 = parseImgSize("2 2 8")
  test "Test parseEndiannes":
    check:
      parseEndianness("-20.4") == -1.0
      parseEndianness("49.8") == 1.0
    expect InvalidPfmFileFormat:
      var
        test1 = parseEndianness("")
        test2 = parseEndianness("0")
  test "Test readPfmImage_le":
    var
      buffer = toString(le_ref_bytes)
      stream = streams.newStringStream(buffer)
      img = readPfmImage(stream)
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
    var
      buffer = toString(be_ref_bytes)
      stream = streams.newStringStream(buffer)
      img = readPfmImage(stream)
    check:
      img.width == 3
      img.height == 2
      img.getPixel(0, 0).areClose(newColor(1.0e1, 2.0e1, 3.0e1))
      img.getPixel(1, 0).areClose(newColor(4.0e1, 5.0e1, 6.0e1))
      img.getPixel(2, 0).areClose(newColor(7.0e1, 8.0e1, 9.0e1))
      img.getPixel(0, 1).areClose(newColor(1.0e2, 2.0e2, 3.0e2))
      img.getPixel(1, 1).areClose(newColor(4.0e2, 5.0e2, 6.0e2))
      img.getPixel(2, 1).areClose(newColor(7.0e2, 8.0e2, 9.0e2))
    stream.close()
  test "Test readPfmImage_execption":
    expect InvalidPfmFileFormat :
      let buf = streams.newStringStream("PokoF\n3 2\n-1.0\nstop")
      var img_2 = readPfmImage(buf)
  test "Test writePfmImage":
    img_test.setPixel(0, 0, newColor(1.0e1, 2.0e1, 3.0e1)) 
    img_test.setPixel(1, 0, newColor(4.0e1, 5.0e1, 6.0e1)) 
    img_test.setPixel(2, 0, newColor(7.0e1, 8.0e1, 9.0e1)) 
    img_test.setPixel(0, 1, newColor(1.0e2, 2.0e2, 3.0e2))
    img_test.setPixel(1, 1, newColor(4.0e2, 5.0e2, 6.0e2))
    img_test.setPixel(2, 1, newColor(7.0e2, 8.0e2, 9.0e2))
    var
      stream = streams.newStringStream("")
      buffer = be_ref_bytes
    writePfmImage(img_test, stream, 1.0)
    stream.setPosition(0)
    var
      buffer2: array[sizeof(buffer), byte]
      stuff = stream.readData(addr(buffer2), sizeof(buffer2)) 
    check:
      buffer2 == buffer

##########
#TEST LDR#
##########

suite "Test ldr.nim":
  setup:
    var
      c1 = newColor(1.0, 2.0, 3.0)
      c2 = newColor(9.0, 5.0, 7.0)
      img : HdrImage = newHdrImage(2, 1)
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
    normalizeImage(img, factor=1000.0, luminosity=options.some(100.0))
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
    var
      a : Vec = newVec(1.0, 2.0, 3.0)
      b : Vec = newVec(4.0, 6.0, 8.0)
      p1 : Point = newPoint(1.0, 2.0, 3.0)
      p2 : Point = newPoint(4.0, 6.0, 8.0)
      pcg : PCG = newPCG()
  test "Test Vec":
    check:
      a.areClose(a)
      not a.areClose(b)
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
      p1.areClose(p1)
      not p2.areClose(p1)
  test "Test Point Operations":
    check:
      areClose(p1*2, newPoint(2.0, 4.0, 6.0))
      areClose(p1+b, newPoint(5.0, 8.0, 11.0))
      areClose(p2-p1, newVec(3.0, 4.0, 5.0))
      areClose(p1-b, newPoint(-3.0, -4.0, -5.0))
  test "Test ONB":
    for i in 0..10000:
      var normal = newNormal(pcg.random_float(), pcg.random_float(), pcg.random_float())
      normal = normalization(normal)
      var ONB = createONBfromZ(normal)
      check:
        areClose(VecToNormal(ONB.e3), normal)
        abs(ONB.e1.squared_norm() - 1) < 1e-6
        abs(ONB.e2.squared_norm() - 1) < 1e-6
        abs(ONB.e3.squared_norm() - 1) < 1e-6
        abs(ONB.e1.dot(ONB.e2)) < 1e-6
        abs(ONB.e2.dot(ONB.e3)) < 1e-6
        abs(ONB.e3.dot(ONB.e1)) < 1e-6
        areClose(ONB.e1.cross(ONB.e2), ONB.e3)
        areClose(ONB.e2.cross(ONB.e3), ONB.e1)
        areClose(ONB.e3.cross(ONB.e1), ONB.e2)
        areClose(ONB.e3.cross(ONB.e2), -ONB.e1)

#####################
#TEST TRANSFOTMATION#
#####################

suite "Test transformation.nim":
  setup:
    var
      m1 : Transformation = newTransformation(
                              m = [1.0, 2.0, 3.0, 4.0,
                                   5.0, 6.0, 7.0, 8.0,
                                   9.0, 9.0, 8.0, 7.0,
                                   6.0, 5.0, 4.0, 1.0],
                              invm = [-3.75, 2.75, -1, 0,
                                      4.375, -3.875, 2.0, -0.5,
                                      0.5, 0.5, -1.0, 1.0,
                                      -1.375, 0.875, 0.0, -0.5])
      m1_inv : Transformation = m1.inverse()
      prod_m : Transformation = m1*m1_inv
      m2 : Transformation = newTransformation(m1.m, m1.invm)
      m3 : Transformation = newTransformation(m1.m, m1.invm)
      m4 : Transformation = newTransformation(
                              m = [3.0, 5.0, 2.0, 4.0,
                                   4.0, 1.0, 0.0, 5.0,
                                   6.0, 3.0, 2.0, 0.0,
                                   1.0, 4.0, 2.0, 1.0],
                              invm = [0.4, -0.2, 0.2, -0.6,
                                      2.9, -1.7, 0.2, -3.1,
                                      -5.55, 3.15, -0.4, 6.45,
                                      -0.9, 0.7, -0.2, 1.1])
      ex : Transformation = newTransformation(
                              m = [33.0, 32.0, 16.0, 18.0,
                                   89.0, 84.0, 40.0, 58.0,
                                   118.0, 106.0, 48.0, 88.0,
                                   63.0, 51.0, 22.0, 50.0],
                              invm = [-1.45, 1.45, -1.0, 0.6,
                                      -13.95, 11.95, -6.5, 2.6,
                                      25.525, -22.025, 12.25, -5.2,
                                      4.825, -4.325, 2.5, -1.1])
      m5 : Transformation = newTransformation(
                              m = [1.0, 2.0, 3.0, 4.0,
                                   5.0, 6.0, 7.0, 8.0,
                                   9.0, 9.0, 8.0, 7.0,
                                   0.0, 0.0, 0.0, 1.0],
                              invm = [-3.75, 2.75, -1.0, 0.0,
                                      5.75, -4.75, 2.0, 1.0,
                                      -2.25, 2.25, -1.0, -2.0,
                                      0.0, 0.0, 0.0, 1.0])
      ex_v : Vec = newVec(14.0, 38.0, 51.0)
      ex_p : Point = newPoint(18.0, 46.0, 58.0)
      ex_n : Normal = newNormal(-8.75, 7.75, -3.0)
      tr1 : Transformation = translation(newVec(1.0, 2.0, 3.0))
      tr2 : Transformation = translation(newVec(4.0, 6.0, 8.0))
      prod_t : Transformation = tr1*tr2
      ex_t : Transformation = translation(newVec(5.0, 8.0, 11.0))
      r1_x : Transformation = rotation_x(0.1)
      r1_y : Transformation = rotation_y(0.1)
      r1_z : Transformation = rotation_z(0.1)
      r2_x : Transformation = rotation_x(90.0)
      r2_y : Transformation = rotation_y(90.0)
      r2_z : Transformation = rotation_z(90.0)
      s1 : Transformation = scaling(newVec(2.0, 5.0, 10.0))
      s2 : Transformation = scaling(newVec(3.0, 2.0, 4.0))
      ex_s : Transformation = scaling(newVec(6.0, 10.0, 40.0))
    m3.m[10] += 1
  test "Test Is Close":
    check:
      m1.isConsistent()
      not m3.isConsistent()
      m1.isClose(m2)
      not m1.isClose(m3)
  test "Test Multiplication":
    check:
      m4.isConsistent()
      ex.isConsistent()
      ex.isClose(m1*m4)
  test "Test Vec Point Multiplication":
    check:
      ex_v.areClose(m5*newVec(1.0, 2.0, 3.0))
      ex_p.areClose(m5*newPoint(1.0, 2.0, 3.0))
      ex_n.areClose(m5*newNormal(3.0, 2.0, 4.0))
  test "Teste Inverse":
    check:
      m1_inv.isConsistent()
      prod_m.isConsistent()
      prod_m.isClose(newTransformation())
  test "Test Translations":
    check:
      tr1.isConsistent()
      tr2.isConsistent()
      prod_t.isConsistent()
      prod_t.isClose(ex_t)
  test "Test Scaling":
    check:
      s1.isConsistent()
      s2.isConsistent()
      ex_s.isClose(s1*s2)
  test "Test Rotations":
    check:
      r1_x.isConsistent()
      r1_y.isConsistent()
      r1_z.isConsistent()
      areClose(r2_x*VEC_Y, VEC_Z)
      areClose(r2_y*VEC_Z, VEC_X)
      areClose(r2_z*VEC_X, VEC_Y)

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
      cam = newOrthogonalCamera(aspect_ratio = 2.0)
      ray1f : Ray = cam.fireRay(0.0, 0.0)
      ray2f : Ray = cam.fireRay(1.0, 0.0)
      ray3f : Ray = cam.fireRay(0.0, 1.0)
      ray4f : Ray = cam.fireRay(1.0, 1.0)
      cam2 = newOrthogonalCamera(aspect_ratio = 2.0, transformation = translation(- VEC_Y * 2.0) * rotation_z(90.0))
      ray5f = cam2.fireRay(0.5, 0.5)
      cam_persp = newPerspectiveCamera(distance = 1.0, aspect_ratio = 2.0)
      ray1p : Ray = cam_persp.fireRay(0.0, 0.0)
      ray2p : Ray = cam_persp.fireRay(1.0, 0.0)
      ray3p : Ray = cam_persp.fireRay(0.0, 1.0)
      ray4p : Ray = cam_persp.fireRay(1.0, 1.0)
      image : HdrImage = newHdrImage(width = 4, height = 2)
      tracer : ImageTracer = newImageTracer(image, cam)
      ray1t : Ray = tracer.fire_ray(0, 0, u_pixel = 2.5, v_pixel = 1.5)
      ray2t : Ray = tracer.fire_ray(2, 1, u_pixel = 0.5, v_pixel = 0.5)
      top_left_ray : Ray = tracer.fireRay(0, 0, u_pixel=0.0, v_pixel=0.0)
      bottom_right_ray : Ray = tracer.fireRay(3, 1, u_pixel=1.0, v_pixel=1.0)
  test "Test Ray":
    check:
      areClose(ray1, ray2)
      not areClose(ray1, ray3)
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
      areClose(ray5f.at(1.0), newPoint(0.0, -2.0, 0.0))
  test "Test PerpectiveCamera":
    check:
      areClose(ray1p.origin, ray2p.origin)
      areClose(ray1p.origin, ray3p.origin)
      areClose(ray1p.origin, ray4p.origin)
      areClose(ray1p.at(1.0), newPoint(0.0, 2.0, -1.0))
      areClose(ray2p.at(1.0), newPoint(0.0, -2.0, -1.0))
      areClose(ray3p.at(1.0), newPoint(0.0, 2.0, 1.0))
      areClose(ray4p.at(1.0), newPoint(0.0, -2.0, 1.0))
  test "Test ImageTracer":
    check:
      areClose(ray1t, ray2t)
    var f = proc (r: Ray): Color = newColor(1.0, 2.0, 3.0)
    var
      w : World
      renderer : OnOffRenderer = newOnOffRenderer(w, newColor(1.0, 2.0, 3.0), newColor(1.0, 2.0, 3.0))
    tracer.fireAllRays(renderer)
    for row in 0..<(tracer.image.height):
      for col in 0..<(tracer.image.width):
        check:
          tracer.image.getPixel(col, row) == newColor(1.0, 2.0, 3.0)
  test "Test ImageTracer Orientation":
    check:
      newPoint(0.0, 2.0, 1.0).areClose(top_left_ray.at(1.0))
      newPoint(0.0, -2.0, -1.0).areClose(bottom_right_ray.at(1.0))

##############
#TEST SHAPES#
##############

suite "Test shapes.nim":
  setup:
    var
      sphere = newSphere()
      sphereTrans = newSphere(transformation = translation(newVec(10.0, 0.0, 0.0)))
      plane = newPlane()
      planeTrans = newPlane(transformation = rotation_y(angle_deg = 90.0))
      cube = newAABox(newPoint(1.0,1.0,1.0), newPoint(2.0,2.0,2.0))
      cubeTrans = newAABox(newPoint(-1.0,-1.0,-1.0), newPoint(1.0,1.0,1.0), transformation = rotation_x(angle_deg = 45.0))
      ray1 = newRay(origin = newPoint(0, 0, 2), dir = -VEC_Z)
      ray2 = newRay(origin = newPoint(3, 0, 0), dir = -VEC_X)
      ray3 = newRay(origin = newPoint(0, 0, 0), dir = VEC_X)
      ray4 = newRay(origin = newPoint(10, 0, 2), dir = -VEC_Z)
      ray5 = newRay(origin = newPoint(13, 0, 0), dir = -VEC_X)
      ray1p = newRay(origin = newPoint(0, 0, 1), dir = -VEC_Z)
      ray2p = newRay(origin = newPoint(0, 0, 1), dir = VEC_Z)
      ray3p = newRay(origin = newPoint(0, 0, 1), dir = VEC_X)
      ray4p = newRay(origin = newPoint(0, 0, 1), dir = VEC_Y)
      ray5p = newRay(origin = newPoint(1, 0, 0), dir = -VEC_X)
      ray6p = newRay(origin = newPoint(0.25, 0.75, 1), dir = -VEC_Z)
      ray7p = newRay(origin = newPoint(4.25, 7.75, 1), dir = -VEC_Z)
      ray1a = newRay(origin = newPoint(0, 1.5, 1.5), dir = VEC_X)
      ray2a = newRay(origin = newPoint(0, 3.5, 1.5), dir = VEC_X)
      ray3a = newRay(origin = newPoint(-2, 0.99, 0.99), dir = VEC_X)
      ray4a = newRay(origin = newPoint(0.5, 0.5, -2.5), dir = VEC_Z)
      ray5a = newRay(origin = newPoint(0.0, -5, 0.2), dir = VEC_Y)
      intersection1 = sphere.rayIntersection(ray1)
      intersection2 = sphere.rayIntersection(ray2)
      intersection3 = sphere.rayIntersection(ray3)
      intersection4 = sphereTrans.rayIntersection(ray4)
      intersection5 = sphereTrans.rayIntersection(ray5)
      intersection1p = plane.rayIntersection(ray1p)
      intersection2p = plane.rayIntersection(ray2p)
      intersection3p = plane.rayIntersection(ray3p)
      intersection2pTrans = planeTrans.rayIntersection(ray2p)
      intersection3pTrans = planeTrans.rayIntersection(ray3p)
      intersection4pTrans = planeTrans.rayIntersection(ray4p)
      intersection4p = planeTrans.rayIntersection(ray4p)
      intersection5p = planeTrans.rayIntersection(ray5p)
      intersection6p = plane.rayIntersection(ray6p)
      intersection7p = plane.rayIntersection(ray7p)
      intersection1a = cube.rayIntersection(ray1a)
      intersection2a = cube.rayIntersection(ray2a)
      intersection3a = cubeTrans.rayIntersection(ray3a)
      intersection4a = cubeTrans.rayIntersection(ray4a)
      intersection5a = cubeTrans.rayIntersection(ray5a)
  test "Test Sphere Hit":
    check:
      not intersection1.isNone
      not intersection2.isNone
      areClose(newHitRecord(world_point=newPoint(0.0, 0.0, 1.0),
                            normal=newNormal(0.0, 0.0, 1.0),
                            surface_point=newVec2d(0.0, 0.0),
                            t=1.0,
                            ray=ray1),
                intersection1.get())
      areClose(newHitRecord(world_point=newPoint(1.0, 0.0, 0.0),
                            normal=newNormal(1.0, 0.0, 0.0),
                            surface_point=newVec2d(0.0, 0.5),
                            t=2.0,
                            ray=ray2),
                intersection2.get())
      sphere.rayIntersection(newRay(origin = newPoint(0, 10, 2), dir = -VEC_Z)).isNone
  test "Test Sphere InnerHit":
    check:
      not intersection3.isNone
      areClose(newHitRecord(world_point=newPoint(1.0, 0.0, 0.0),
                            normal=newNormal(-1.0, 0.0, 0.0),
                            surface_point=newVec2d(0.0, 0.5),
                            t=1.0,
                            ray=ray3),
                intersection3.get())
  test "Test Sphere Transformation":
    check:
      not intersection4.isNone
      not intersection5.isNone
      areClose(newHitRecord(world_point=newPoint(10.0, 0.0, 1.0),
                            normal=newNormal(0.0, 0.0, 1.0),
                            surface_point=newVec2d(0.0, 0.0),
                            t=1.0,
                            ray=ray4),
                intersection4.get())
      areClose(newHitRecord(world_point=newPoint(11.0, 0.0, 0.0),
                            normal=newNormal(1.0, 0.0, 0.0),
                            surface_point=newVec2d(0.0, 0.5),
                            t=2.0,
                            ray=ray5),
                intersection5.get())
      sphereTrans.rayIntersection(newRay(origin = newPoint(0, 0, 2), dir = -VEC_Z)).isNone
      sphereTrans.rayIntersection(newRay(origin = newPoint(-10, 0, 0), dir = -VEC_Z)).isNone
  test "Test Plane Hit":
    check:
      not intersection1p.isNone
      intersection2p.isNone
      intersection3p.isNone
      intersection4p.isNone
      areClose(newHitRecord(world_point=newPoint(0.0, 0.0, 0.0),
                            normal=newNormal(0.0, 0.0, 1.0),
                            surface_point=newVec2d(0.0, 0.0),
                            t=1.0,
                            ray=ray1p),
                intersection1p.get())
  test "Test Plane Transformation":
    check:
      not intersection5p.isNone
      areClose(newHitRecord(world_point=newPoint(0.0, 0.0, 0.0),
                            normal=newNormal(1.0, 0.0, 0.0),
                            surface_point=newVec2d(0.0, 0.0),
                            t=1.0,
                            ray=ray5p),
                intersection5p.get())
      intersection2pTrans.isNone
      intersection3pTrans.isNone
      intersection4pTrans.isNone
  test "Test UV Coordinates":
    check:
      areClose(intersection1p.get().surface_point, (newVec2d(0.0, 0.0)))
      areClose(intersection6p.get().surface_point, (newVec2d(0.25, 0.75)))
      areClose(intersection7p.get().surface_point, (newVec2d(0.25, 0.75)))
  test "Test AABox Hit":
    check:
      not intersection1a.isNone
      intersection2a.isNone
      areClose(intersection1a.get().world_point, (newPoint(1.0, 1.5, 1.5)))
  test "Test AABox Transformation":
    #echo(intersection5a.get().normal)
    check:
      intersection3a.isNone
      not intersection4a.isNone
      not intersection5a.isNone
      

############
#TEST WORLD#
############

suite "Test World":
  setup:
    var
      world : World
      sphere1 = newSphere(transformation = translation(VEC_X * 2))
      sphere2 = newSphere(transformation = translation(VEC_X * 8))
    world.shapes.add(sphere1)
    world.shapes.add(sphere2)
    var
      intersection1 = world.rayIntersection(newRay(origin = newPoint(0.0, 0.0, 0.0), dir = VEC_X))
      intersection2 = world.rayIntersection(newRay(origin = newPoint(10.0, 0.0, 0.0), dir = -VEC_X))
  test "Test World Hit":
    check:
      not intersection1.isNone
      not intersection2.isNone
      areClose(intersection1.get().world_point, (newPoint(1.0, 0.0, 0.0)))
      areClose(intersection2.get().world_point, (newPoint(9.0, 0.0, 0.0)))
  test "Test Quick Ray Intersection":
    check:
      not world.is_point_visible(point = newPoint(10.0,0.0,0.0), observer_pos = newPoint(0.0,0.0,0.0))
      not world.is_point_visible(point = newPoint(5.0,0.0,0.0), observer_pos = newPoint(0.0,0.0,0.0))
      world.is_point_visible(point = newPoint(5.0,0.0,0.0), observer_pos = newPoint(5.0,0.0,0.0))
      world.is_point_visible(point = newPoint(0.5,0.0,0.0), observer_pos = newPoint(0.0,0.0,0.0))
      world.is_point_visible(point = newPoint(0.0,10.0,0.0), observer_pos = newPoint(0.0,0.0,0.0))
      world.is_point_visible(point = newPoint(0.0,0.0,10.0), observer_pos = newPoint(0.0,0.0,0.0))

################
#TEST MATERIALS#
################

suite "Test materials.nim":
  setup:
    var
      color1 = newColor(1.0, 2.0, 3.0)
      color2 = newColor(10.0, 20.0, 30.0)
      image1 = newHdrImage(width=2, height=2)
    image1.set_pixel(0, 0, newColor(1.0, 2.0, 3.0))
    image1.set_pixel(1, 0, newColor(2.0, 3.0, 1.0))
    image1.set_pixel(0, 1, newColor(2.0, 1.0, 3.0))
    image1.set_pixel(1, 1, newColor(3.0, 2.0, 1.0))
    var
      pigment1 = newUniformPigment(color = color1)
      pigment2 = newImagePigment(image1)
      pigment3 = newCheckeredPigment(color1 = color1, color2 = color2, num_of_steps = 2)

  test "Test Uniform Pigment":
    check:
      areClose(pigment1.getColor(newVec2d(0.0, 0.0)), color1)
      areClose(pigment1.getColor(newVec2d(1.0, 0.0)), color1)
      areClose(pigment1.getColor(newVec2d(0.0, 1.0)), color1)
      areClose(pigment1.getColor(newVec2d(1.0, 1.0)), color1)

  test "Test Image Pigment":
    check:
      areClose(pigment2.getColor(newVec2d(0.0, 0.0)), newColor(1.0, 2.0, 3.0))
      areClose(pigment2.getColor(newVec2d(1.0, 0.0)), newColor(2.0, 3.0, 1.0))
      areClose(pigment2.getColor(newVec2d(0.0, 1.0)), newColor(2.0, 1.0, 3.0))
      areClose(pigment2.getColor(newVec2d(1.0, 1.0)), newColor(3.0, 2.0, 1.0))

  test "Test Checkered Pigment":
    check:
      # With num_of_steps == 2, the pattern should be the following:
      #
      #              (0.5, 0)
      #   (0, 0) +------+------+ (1, 0)
      #          |      |      |
      #          | col1 | col2 |
      #          |      |      |
      # (0, 0.5) +------+------+ (1, 0.5)
      #          |      |      |
      #          | col2 | col1 |
      #          |      |      |
      #   (0, 1) +------+------+ (1, 1)
      #              (0.5, 1)
      areClose(pigment3.getColor(newVec2d(0.25, 0.25)), color1)
      areClose(pigment3.getColor(newVec2d(0.75, 0.25)), color2)
      areClose(pigment3.getColor(newVec2d(0.25, 0.75)), color2)
      areClose(pigment3.getColor(newVec2d(0.75, 0.75)), color1)

##########
#TEST PCG#
##########

suite "Test pcg.nim":
  setup:
    var
      pcg = newPCG()
      expected = [2707161783.uint32, 2068313097.uint32,
                  3122475824.uint32, 2211639955.uint32, 
                  3215226955.uint32, 3421331566.uint32]
  test "Test PCG generator":
    check:
      pcg.state == uint64(1753877967969059832)
      pcg.inc == uint64(109)
  test "Test PCG usage":
    for k in expected:
      check:
        k == pcg.random()

###############
#TEST RENDERER#
###############

suite "Test renderer.nim":
  setup:
    var
      sphere_color = newColor(1.0, 2.0, 3.0)
      sphere = newSphere(transformation = translation(newVec(2, 0, 0))*scaling(newVec(0.2, 0.2, 0.2)),
                         material = newMaterial(brdf = newDiffuseBRDF(pigment = newUniformPigment(WHITE))))
      sphere1 = newSphere(transformation = translation(newVec(2, 0, 0))*scaling(newVec(0.2, 0.2, 0.2)),
                          material = newMaterial(brdf = newDiffuseBRDF(pigment = newUniformPigment(sphere_color))))
      image = newHdrImage(width = 3, height = 3)
      camera = newOrthogonalCamera()
      tracer = newImageTracer(image = image, camera = camera)
      world : World
      world1 : World
    world.shapes.add(sphere)
    world1.shapes.add(sphere1)
    var
      renderer = newOnOffRenderer(world = world)
      renderer1 = newFlatRenderer(world = world1)
  test "Test OnOffRenderer":
#[     proc fun(r : Ray) : Color =
      return renderer.render(r) ]#
    tracer.fireAllRays(renderer)
    check:
      areClose(tracer.image.getPixel(0, 0), BLACK)
      areClose(tracer.image.getPixel(1, 0), BLACK)
      areClose(tracer.image.getPixel(2, 0), BLACK)
      areClose(tracer.image.getPixel(0, 1), BLACK)
      areClose(tracer.image.getPixel(1, 1), WHITE)
      areClose(tracer.image.getPixel(2, 1), BLACK)
      areClose(tracer.image.getPixel(0, 2), BLACK)
      areClose(tracer.image.getPixel(1, 2), BLACK)
      areClose(tracer.image.getPixel(2, 2), BLACK)
  test "Test FlatRenderer":
    tracer.fireAllRays(renderer1)
    check:
      areClose(tracer.image.getPixel(0, 0), BLACK)
      areClose(tracer.image.getPixel(1, 0), BLACK)
      areClose(tracer.image.getPixel(2, 0), BLACK)
      areClose(tracer.image.getPixel(0, 1), BLACK)
      areClose(tracer.image.getPixel(1, 1), sphere_color)
      areClose(tracer.image.getPixel(2, 1), BLACK)
      areClose(tracer.image.getPixel(0, 2), BLACK)
      areClose(tracer.image.getPixel(1, 2), BLACK)
      areClose(tracer.image.getPixel(2, 2), BLACK)
suite "Test PathTracer":
  test "Furnace Test":
    var pcg : PCG = newPCG()
    for i in 0..5:
      var 
        world : World = newWorld()
        ray : Ray = newRay(origin = newPoint(0.0,0.0,0.0), dir = newVec(1.0,0.0,0.0))
        emitted_radiance : float = pcg.random_float()
        reflectance : float = pcg.random_float() * 0.9
        enclosure_material : Material = newMaterial(newDiffuseBRDF(newUniformPigment(newColor(1.0,1.0,1.0) * reflectance)),
                                                    newUniformPigment(newColor(1.0,1.0,1.0) * emitted_radiance))
      world.shapes.add(newSphere(material = enclosure_material))
      let 
        path_tracer : PathTracer = newPathTracer(world, pcg = pcg, num_of_rays = 1, max_depth = 100, russian_roulette_limit = 101) 
        color : Color = path_tracer.render(ray)
        expected : float = emitted_radiance / (1.0 - reflectance)
      check:
        abs(color.r - expected) < 1e-3
        abs(color.b - expected) < 1e-3
        abs(color.g - expected) < 1e-3

##################
#TEST SCENE FILES#
##################

#Some useful function

proc assert_is_keyword(token : Token, keyword : KeywordEnum): bool =
  return token.kind == KeywordToken and token.keyword == keyword 

proc assert_is_identifier(token : Token, identifier : string): bool =
  return token.kind == IdentifierToken and token.identifier == identifier

proc assert_is_symbol(token : Token, symbol : string): bool =
  return token.kind == SymbolToken and token.symbol == symbol

proc assert_is_number(token : Token, number : float): bool =
  return token.kind == LiteralNumberToken and token.value == number

proc assert_is_string(token : Token, s : string): bool =
  return token.kind == StringToken and token.s == s

suite "Test scene file":
  setup:
    var 
      buffer = newStringStream("abc   \nd\nef")
      buffer1 = newStringStream("""
        # This is a comment
        # This is another comment
        new material sky_material(
            diffuse(image("my_file.pfm")),
            <5.0, 500.0, 300.0>
        ) # Comment at the end of the line
        """)
      buffer_parser = newStringStream(
        """
        float clock(150)
    
        material sky_material(
            diffuse(uniform(<0, 0, 0>)),
            uniform(<0.7, 0.5, 1>)
        )
    
        # Here is a comment
    
        material ground_material(
            diffuse(checkered(<0.3, 0.5, 0.1>,
                              <0.1, 0.2, 0.5>, 4)),
            uniform(<0, 0, 0>)
        )
    
        material sphere_material(
            specular(uniform(<0.5, 0.5, 0.5>)),
            uniform(<0, 0, 0>)
        )
    
        plane (sky_material, translation([0, 0, 100]) * rotation_y(clock))

        plane (ground_material, identity)
    
        sphere(sphere_material, translation([0, 0, 1]))
    
        camera(perspective, rotation_z(30) * translation([-4, 0, 1]), 1.0, 2.0) 
        """)
    buffer.setPosition(0)
    buffer1.setPosition(0)
    buffer_parser.setPosition(0)
    var 
      stream = newInputStream(stream = buffer)
      input_file = newInputStream(buffer1)
      stream_parser = newInputStream(buffer_parser)
      scene : Scene = parseScene(stream_parser)
  test "Test input file":
    check:
      stream.location.line_num == 1
      stream.location.col_num == 1
      stream.readChar() == 'a'
      stream.location.line_num == 1
      stream.location.col_num == 2
    stream.unreadChar('A')
    check:
      stream.location.line_num == 1
      stream.location.col_num == 1
      stream.readChar() == 'A'
      stream.location.line_num == 1
      stream.location.col_num == 2
      stream.readChar() == 'b'
      stream.location.line_num == 1
      stream.location.col_num == 3
      stream.readChar() == 'c'
      stream.location.line_num == 1
      stream.location.col_num == 4
    stream.skipWhitespacesAndComments()
    check:
      stream.readChar() == 'd'
      stream.location.line_num == 2
      stream.location.col_num == 2
      stream.readChar() == '\n'
      stream.location.line_num == 3
      stream.location.col_num == 1
      stream.readChar() == 'e'
      stream.location.line_num == 3
      stream.location.col_num == 2
      stream.readChar() == 'f'
      stream.location.line_num == 3
      stream.location.col_num == 3
      stream.readChar() == '\0'
  test "Test Lexer":
    check:
      assert_is_keyword(input_file.readToken(), KeywordEnum.NEW)
      assert_is_keyword(input_file.readToken(), KeywordEnum.MATERIAL)
      assert_is_identifier(input_file.readToken(), "sky_material")
      assert_is_symbol(input_file.readToken(), "(")
      assert_is_keyword(input_file.readToken(), KeywordEnum.DIFFUSE)
      assert_is_symbol(input_file.readToken(), "(")
      assert_is_keyword(input_file.readToken(), KeywordEnum.IMAGE)
      assert_is_symbol(input_file.readToken(), "(")
      assert_is_string(input_file.readToken(), "my_file.pfm")
      assert_is_symbol(input_file.readToken(), ")")
  test "Test Parser":
    check:
      # Check that the float variables are ok
      len(scene.float_variables) == 1
      scene.float_variables.hasKey("clock")
      scene.float_variables["clock"] == 150.0
      # Check that the materials are ok
      len(scene.materials) == 3
      scene.materials.hasKey("sphere_material")
      scene.materials.hasKey("sky_material")
      scene.materials.hasKey("ground_material")
    let
      sphere_material = scene.materials["sphere_material"]
      sky_material = scene.materials["sky_material"]
      ground_material = scene.materials["ground_material"]
    check:
      sky_material.brdf_function of DiffuseBRDF
      sky_material.brdf_function.pigment of UniformPigment
      areClose(sky_material.brdf_function.pigment.getColor(newVec2d(0.5,0.5)), newColor(0, 0, 0)) # Specify newVec2d(0.5,0.5) IN THIS CASE is useless because the pigmant is uniform.
      ground_material.brdf_function of DiffuseBRDF
      ground_material.brdf_function.pigment of CheckeredPigment
      # Errori di compilazione perchè deve valutare in runtime il tipo di pigmanto, in fase di compile time non ha idea che sia a scacchi e quindi non sa cosa sia color1 e color2...
      #ground_material.brdf_function.pigment.color2.areClose(newColor(0.3, 0.5, 0.1))
      #ground_material.brdf_function.pigment.color2.areClose(newColor(0.1, 0.2, 0.5))
      #ground_material.brdf_function.pigment.num_of_steps == 4

# Implementazione di Tomasi
#[ 
 def test_parser(self):





        

        assert isinstance(sphere_material.brdf, SpecularBRDF)
        assert isinstance(sphere_material.brdf.pigment, UniformPigment)
        assert sphere_material.brdf.pigment.color.is_close(Color(0.5, 0.5, 0.5))

        assert isinstance(sky_material.emitted_radiance, UniformPigment)
        assert sky_material.emitted_radiance.color.is_close(Color(0.7, 0.5, 1.0))
        assert isinstance(ground_material.emitted_radiance, UniformPigment)
        assert ground_material.emitted_radiance.color.is_close(Color(0, 0, 0))
        assert isinstance(sphere_material.emitted_radiance, UniformPigment)
        assert sphere_material.emitted_radiance.color.is_close(Color(0, 0, 0))

        # Check that the shapes are ok

        assert len(scene.world.shapes) == 3
        assert isinstance(scene.world.shapes[0], Plane)
        assert scene.world.shapes[0].transformation.is_close(translation(Vec(0, 0, 100)) * rotation_y(150.0))
        assert isinstance(scene.world.shapes[1], Plane)
        assert scene.world.shapes[1].transformation.is_close(Transformation())
        assert isinstance(scene.world.shapes[2], Sphere)
        assert scene.world.shapes[2].transformation.is_close(translation(Vec(0, 0, 1)))

        # Check that the camera is ok

        assert isinstance(scene.camera, PerspectiveCamera)
        assert scene.camera.transformation.is_close(rotation_z(30) * translation(Vec(-4, 0, 1)))
        assert pytest.approx(1.0) == scene.camera.aspect_ratio
        assert pytest.approx(2.0) == scene.camera.screen_distance

 ]#