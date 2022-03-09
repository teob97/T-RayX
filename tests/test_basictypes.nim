import ../src/tools

#FUNCTIONS

func valid_coordinates(img : HdrImage; width, height : int) : bool =
    return width >= 0 and width < img.width and height >= 0 and height < img.height 

func test_image_creation() =
    var img = newHdrImage(7, 4)
    assert img.width == 7
    assert img.height == 4

#[ func test_coordinates() =
    var img = newHdrImage(7, 4)
    assert valid_coordinates(img, 0, 0)
    assert valid_coordinates(img, 6, 3)
    assert not valid_coordinates(img, -1, 0)
    assert not valid_coordinates(img, 0, -1)
    assert not valid_coordinates(img, 7, 0)
    assert not valid_coordinates(img, 0, 4) ]#

#[ func test_pixel_offset() =
    var img = newHdrImage(7, 4)

    assert pixel_offset(img, 0, 0) == 0
    assert pixel_offset(img, 3, 2) == 17
    assert pixel_offset(img, 6, 3) == 7 * 4 - 1 ]#


#[ func test_get_set_pixel() =
    var img = newHdrImage(7, 4)

    reference_color = Color(1.0, 2.0, 3.0)
    img.set_pixel(3, 2, reference_color)
    assert are_colors_close(reference_color, img.get_pixel(3, 2)) ]#

#TESTS

when isMainModule:
    assert newColor(1.0, 2.0, 3.0) + newColor(3.0, 4.0, 5.0) == newColor(4.0, 6.0, 8.0)
    assert newColor(6.0, 4.0, 5.0) - newColor(1.0, 2.0, 3.0) == newColor(5.0, 2.0, 2.0)
    assert newColor(1.0, 2.0, 3.0) * newColor(2.0, 3.0, 4.0) == newColor(2.0, 6.0, 12.0)
    assert 3.0 * newColor(1.0, 2.0, 3.0) == newColor(3.0, 6.0, 9.0)
    assert newColor(1.0, 2.0, 3.0) * 3.0 == newColor(3.0, 6.0, 9.0)
    assert are_close(newColor(1.11113, 2.0, 3.0), newColor(1.11113, 2.0, 3.0)) == true
    
    test_image_creation()
    #test_coordinates()
    #test_get_set_pixel()
    #test_pixel_offset()