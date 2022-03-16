import ../src/basictypes

#TESTS

when isMainModule:
    assert newColor(1.0, 2.0, 3.0) + newColor(3.0, 4.0, 5.0) == newColor(4.0, 6.0, 8.0)
    assert newColor(6.0, 4.0, 5.0) - newColor(1.0, 2.0, 3.0) == newColor(5.0, 2.0, 2.0)
    assert newColor(1.0, 2.0, 3.0) * newColor(2.0, 3.0, 4.0) == newColor(2.0, 6.0, 12.0)
    assert 3.0 * newColor(1.0, 2.0, 3.0) == newColor(3.0, 6.0, 9.0)
    assert newColor(1.0, 2.0, 3.0) * 3.0 == newColor(3.0, 6.0, 9.0)
    assert are_close(newColor(1.11113, 2.0, 3.0), newColor(1.11113, 2.0, 3.0)) == true
    
    test_image_creation()
    test_coordinates()
    test_get_set_pixel()
    test_pixel_offset()