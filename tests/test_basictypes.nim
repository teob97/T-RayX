import ../src/basictypes
import std/unittest

proc test_get_pixel() = 
    var img = newHdrImage(7,4)
    expect(IOError):
        var test = img.get_pixel(1,-3)

proc test_image_creation() =
    var img = newHdrImage(7, 4)
    assert img.width == 7
    assert img.height == 4

proc test_coordinates() =
    var img = newHdrImage(7, 4)
    assert test_valid_coordinates(img, 0, 0)
    assert test_valid_coordinates(img, 6, 3)
    assert not test_valid_coordinates(img, -1, 0)
    assert not test_valid_coordinates(img, 0, -1)
    assert not test_valid_coordinates(img, 7, 0)
    assert not test_valid_coordinates(img, 0, 4)

proc test_pixel_offset() =
    var img = newHdrImage(7, 4)

    assert pixel_offset(img, 0, 0) == 0
    assert pixel_offset(img, 3, 2) == 17
    assert pixel_offset(img, 6, 3) == 7 * 4 - 1

proc test_get_set_pixel() =
    var 
        img = newHdrImage(7, 4)
        reference_color = newColor(1.0, 2.0, 3.0)
    set_pixel(img, 3, 2, reference_color)
    assert are_close(reference_color, img.get_pixel(3, 2))

when isMainModule:
    assert newColor(1.0, 2.0, 3.0) + newColor(3.0, 4.0, 5.0) == newColor(4.0, 6.0, 8.0)
    assert newColor(6.0, 4.0, 5.0) - newColor(1.0, 2.0, 3.0) == newColor(5.0, 2.0, 2.0)
    assert newColor(1.0, 2.0, 3.0) * newColor(2.0, 3.0, 4.0) == newColor(2.0, 6.0, 12.0)
    assert 3.0 * newColor(1.0, 2.0, 3.0) == newColor(3.0, 6.0, 9.0)
    assert newColor(1.0, 2.0, 3.0) * 3.0 == newColor(3.0, 6.0, 9.0)
    assert are_close(newColor(1.11113, 2.0, 3.0), newColor(1.11113, 2.0, 3.0)) == true
    
    test_get_pixel()
    test_image_creation()
    test_coordinates()
    test_get_set_pixel()
    test_pixel_offset()