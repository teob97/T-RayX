import ../src/tools

#FUNCTIONS

func test_image_creation() =
    img = HdrImage(7, 4)
    assert img.width == 7
    assert img.height == 4

func test_coordinates():
    img = HdrImage(7, 4)
    assert img.valid_coordinates(0, 0)
    assert img.valid_coordinates(6, 3)
    assert not img.valid_coordinates(-1, 0)
    assert not img.valid_coordinates(0, -1)
    assert not img.valid_coordinates(7, 0)
    assert not img.valid_coordinates(0, 4)

func test_pixel_offset():
    img = HdrImage(7, 4)

    assert img.pixel_offset(0, 0) == 0
    assert img.pixel_offset(3, 2) == 17
    assert img.pixel_offset(6, 3) == 7 * 4 - 1

func test_get_set_pixel():
    img = HdrImage(7, 4)

    reference_color = Color(1.0, 2.0, 3.0)
    img.set_pixel(3, 2, reference_color)
    assert are_colors_close(reference_color, img.get_pixel(3, 2))

#TESTS

when isMainModule:
    assert newColor(1.0, 2.0, 3.0) + newColor(3.0, 4.0, 5.0) == newColor(4.0, 6.0, 8.0)
    assert newColor(6.0, 4.0, 5.0) - newColor(1.0, 2.0, 3.0) == newColor(5.0, 2.0, 2.0)
    assert newColor(1.0, 2.0, 3.0) * newColor(2.0, 3.0, 4.0) == newColor(2.0, 6.0, 12.0)
    assert 3.0 * newColor(1.0, 2.0, 3.0) == newColor(3.0, 6.0, 9.0)
    assert newColor(1.0, 2.0, 3.0) * 3.0 == newColor(3.0, 6.0, 9.0)
    assert are_close(newColor(1.11113, 2.0, 3.0), newColor(1.11113, 2.0, 3.0)) == true
