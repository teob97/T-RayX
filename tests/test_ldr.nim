import std/options
import ../src/basictypes
import ../src/ldr

proc test_luminosity() =
    let c1 = newColor(1.0, 2.0, 3.0)
    let c2 = newColor(9.0, 5.0, 7.0)
    assert luminosity(c1) == 2.0
    assert luminosity(c2) == 7.0

proc test_average_luminosity() =
    var img : HdrImage = newHdrImage(2, 1)
    set_pixel(img, 0, 0, newColor(5.0, 10.0, 15.0))
    set_pixel(img, 1, 0, newColor(500.0, 1000.0, 1500.0))
    assert average_luminosity(img, delta=0.0) == 100.0

proc test_normalize_image() =
    var img : HdrImage = newHdrImage(2, 1)
    set_pixel(img, 0, 0, newColor(5.0, 10.0, 15.0))
    set_pixel(img, 1, 0, newColor(500.0, 1000.0, 1500.0))
    normalize_image(img, factor=1000.0, luminosity=some(100.0))
    assert are_close(get_pixel(img, 0, 0), newColor(0.5e2, 1.0e2, 1.5e2))
    assert are_close(get_pixel(img, 1, 0), newColor(0.5e4, 1.0e4, 1.5e4))
    
proc test_clamp_image() =
    var img : HdrImage = newHdrImage(2, 1)
    set_pixel(img, 0, 0, newColor(0.5e1, 1.0e1, 1.5e1))
    set_pixel(img, 1, 0, newColor(0.5e3, 1.0e3, 1.5e3))
    clamp_image(img)
    for pixel in img.pixels:
        assert (pixel.r >= 0) and (pixel.r <= 1)
        assert (pixel.g >= 0) and (pixel.g <= 1)
        assert (pixel.b >= 0) and (pixel.b <= 1)

test_luminosity()
test_average_luminosity()
test_normalize_image()
test_clamp_image()


