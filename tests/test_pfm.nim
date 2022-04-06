import std/streams
import ../src/basictypes
import ../src/pfm
import std/unittest

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
      img.get_pixel(0, 0).are_close(newColor(1.0e1, 2.0e1, 3.0e1))
      img.get_pixel(1, 0).are_close(newColor(4.0e1, 5.0e1, 6.0e1))
      img.get_pixel(2, 0).are_close(newColor(7.0e1, 8.0e1, 9.0e1))
      img.get_pixel(0, 1).are_close(newColor(1.0e2, 2.0e2, 3.0e2))
      img.get_pixel(1, 1).are_close(newColor(4.0e2, 5.0e2, 6.0e2))
      img.get_pixel(2, 1).are_close(newColor(7.0e2, 8.0e2, 9.0e2))
  test "Test readPfmImage_be":
    var buffer = toString(be_ref_bytes)
    var stream = newStringStream(buffer)
    var img = readPfmImage(stream)
    check:
      img.width == 3
      img.height == 2
      img.get_pixel(0, 0).are_close(newColor(1.0e1, 2.0e1, 3.0e1))
      img.get_pixel(1, 0).are_close(newColor(4.0e1, 5.0e1, 6.0e1))
      img.get_pixel(2, 0).are_close(newColor(7.0e1, 8.0e1, 9.0e1))
      img.get_pixel(0, 1).are_close(newColor(1.0e2, 2.0e2, 3.0e2))
      img.get_pixel(1, 1).are_close(newColor(4.0e2, 5.0e2, 6.0e2))
      img.get_pixel(2, 1).are_close(newColor(7.0e2, 8.0e2, 9.0e2))

  test "Test readPfmImage_execption":
    expect InvalidPfmFileFormat :
      let buf = newStringStream("PokoF\n3 2\n-1.0\nstop")
      var img_2 = readPfmImage(buf)

  test "Test writePfmImage":
    img_test.set_pixel(0, 0, newColor(1.0e1, 2.0e1, 3.0e1)) 
    img_test.set_pixel(1, 0, newColor(4.0e1, 5.0e1, 6.0e1)) 
    img_test.set_pixel(2, 0, newColor(7.0e1, 8.0e1, 9.0e1)) 
    img_test.set_pixel(0, 1, newColor(1.0e2, 2.0e2, 3.0e2))
    img_test.set_pixel(1, 1, newColor(4.0e2, 5.0e2, 6.0e2))
    img_test.set_pixel(2, 1, newColor(7.0e2, 8.0e2, 9.0e2))
    var stream = newStringStream("")
    var buffer = be_ref_bytes
    writePfmImage(img_test, stream, 1.0)
    stream.setPosition(0)
    var buffer2: array[sizeof(buffer), byte]
    var stuff = stream.readData(addr(buffer2), sizeof(buffer2)) 
    check:
      buffer2 == buffer


#UNIT TEST

proc test_parseImgSize() =
  assert parseImgSize("2 3") == (2,3)
  expect(InvalidPfmFileFormat):
    var test = parseImgSize("-2 3")
  expect(InvalidPfmFileFormat):
    var test = parseImgSize("2 2 8")

proc test_parseEndiannes() =
  assert parseEndianness("-20.4") == -1.0
  assert parseEndianness("49.8") == 1.0
  expect(InvalidPfmFileFormat):
    var test = parseEndianness("")
  expect(InvalidPfmFileFormat):
    var test = parseEndianness("0")

#INTEGRATION TEST

const le_ref_bytes = 
  [byte 0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x2d, 0x31, 0x2e, 0x30, 0x0a,
  0x00, 0x00, 0xc8, 0x42, 0x00, 0x00, 0x48, 0x43, 0x00, 0x00, 0x96, 0x43,
  0x00, 0x00, 0xc8, 0x43, 0x00, 0x00, 0xfa, 0x43, 0x00, 0x00, 0x16, 0x44,
  0x00, 0x00, 0x2f, 0x44, 0x00, 0x00, 0x48, 0x44, 0x00, 0x00, 0x61, 0x44,
  0x00, 0x00, 0x20, 0x41, 0x00, 0x00, 0xa0, 0x41, 0x00, 0x00, 0xf0, 0x41,
  0x00, 0x00, 0x20, 0x42, 0x00, 0x00, 0x48, 0x42, 0x00, 0x00, 0x70, 0x42,
  0x00, 0x00, 0x8c, 0x42, 0x00, 0x00, 0xa0, 0x42, 0x00, 0x00, 0xb4, 0x42]

const be_ref_bytes = 
  [byte 0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x31, 0x2e, 0x30, 0x0a, 0x42,
  0xc8, 0x00, 0x00, 0x43, 0x48, 0x00, 0x00, 0x43, 0x96, 0x00, 0x00, 0x43,
  0xc8, 0x00, 0x00, 0x43, 0xfa, 0x00, 0x00, 0x44, 0x16, 0x00, 0x00, 0x44,
  0x2f, 0x00, 0x00, 0x44, 0x48, 0x00, 0x00, 0x44, 0x61, 0x00, 0x00, 0x41,
  0x20, 0x00, 0x00, 0x41, 0xa0, 0x00, 0x00, 0x41, 0xf0, 0x00, 0x00, 0x42,
  0x20, 0x00, 0x00, 0x42, 0x48, 0x00, 0x00, 0x42, 0x70, 0x00, 0x00, 0x42,
  0x8c, 0x00, 0x00, 0x42, 0xa0, 0x00, 0x00, 0x42, 0xb4, 0x00, 0x00]


proc test_readPfmImage(test : openarray[byte])=
  var buffer = toString(test)
  var stream = newStringStream(buffer)
  var img = readPfmImage(stream)
  assert img.width == 3
  assert img.height == 2

  assert img.get_pixel(0, 0).are_close(newColor(1.0e1, 2.0e1, 3.0e1))
  assert img.get_pixel(1, 0).are_close(newColor(4.0e1, 5.0e1, 6.0e1))
  assert img.get_pixel(2, 0).are_close(newColor(7.0e1, 8.0e1, 9.0e1))
  assert img.get_pixel(0, 1).are_close(newColor(1.0e2, 2.0e2, 3.0e2))
  assert img.get_pixel(1, 1).are_close(newColor(4.0e2, 5.0e2, 6.0e2))
  assert img.get_pixel(2, 1).are_close(newColor(7.0e2, 8.0e2, 9.0e2))

  stream.close()

proc test_readPfmImage_execption() = 
  expect(InvalidPfmFileFormat):
    let buf = newStringStream("PokoF\n3 2\n-1.0\nstop")
    var img_2 = readPfmImage(buf)

proc test_writePfmImage() =
  var img = newHdrImage(3,2)
  img.set_pixel(0, 0, newColor(1.0e1, 2.0e1, 3.0e1)) 
  img.set_pixel(1, 0, newColor(4.0e1, 5.0e1, 6.0e1)) 
  img.set_pixel(2, 0, newColor(7.0e1, 8.0e1, 9.0e1)) 
  img.set_pixel(0, 1, newColor(1.0e2, 2.0e2, 3.0e2))
  img.set_pixel(1, 1, newColor(4.0e2, 5.0e2, 6.0e2))
  img.set_pixel(2, 1, newColor(7.0e2, 8.0e2, 9.0e2))

  var stream = newStringStream("")
  var buffer = be_ref_bytes
  writePfmImage(img, stream, 1.0)
  stream.setPosition(0)
  var buffer2: array[sizeof(buffer), byte]
  var stuff = stream.readData(addr(buffer2), sizeof(buffer2)) 
  assert buffer2 == buffer


when isMainModule:
  test_parseImgSize()
  test_parseEndiannes()
  test_readPfmImage(le_ref_bytes)
  test_readPfmImage(be_ref_bytes)
  test_readPfmImage_execption()
  test_writePfmImage()
