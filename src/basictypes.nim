#CLASS

type
    Color* = object
        r*, g*, b* : float32

    HdrImage* = object
        width*, height*: int
        pixels* : seq[Color]
        
#CONSTRUCTORS

func newColor*(r : float32 = 0.0; g : float32 = 0.0; b : float32 = 0.0) : Color =
    var C : Color
    C.r = r
    C.g = g
    C.b = b
    return C

func newHdrImage*(width, height : int) : HdrImage =
    
    var img : HdrImage
    var C : Color = newColor(0.0, 0.0, 0.0)

    img.width = width
    img.height = height
    img.pixels = newSeq[Color](width*height)
    
    for i in 0..<width*height:
        img.pixels[i] = C
    
    return img

#FUNCTIONS

func pixel_offset*(img : HdrImage; x, y : int) : int =
    return y * img.width + x

#OPERATOR OVERLOAD

func `+` *(c1 : Color, c2 : Color): Color =
    return newColor(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)

func `-` *(c1 : Color, c2 : Color): Color =
    return newColor(c1.r - c2.r, c1.g - c2.g, c1.b - c2.b)

func `*` *(c1, c2: Color) : Color =
    return newColor(c1.r * c2.r, c1.g * c2.g, c1.b * c2.b)

func `*` *(a: float32, c: Color) : Color =
    return newColor(c.r * a, c.g * a, c.b * a)

func `*` *(c: Color, a: float32) : Color =
    return newColor(c.r * a, c.g * a, c.b * a)

func are_close *(c1, c2: Color; epsilon : float32 = 1e-5) : bool =
    var dif : Color = c1 - c2
    return abs(dif.r) < epsilon and abs(dif.g) < epsilon and abs(dif.b) < epsilon

#FUNCTIONS TEST

func valid_coordinates*(img : HdrImage; width, height : int) : bool =
    return width >= 0 and width < img.width and height >= 0 and height < img.height 

func test_image_creation*() =
    var img = newHdrImage(7, 4)
    assert img.width == 7
    assert img.height == 4

func test_coordinates*() =
    var img = newHdrImage(7, 4)
    assert valid_coordinates(img, 0, 0)
    assert valid_coordinates(img, 6, 3)
    assert not valid_coordinates(img, -1, 0)
    assert not valid_coordinates(img, 0, -1)
    assert not valid_coordinates(img, 7, 0)
    assert not valid_coordinates(img, 0, 4)

func test_pixel_offset*() =
    var img = newHdrImage(7, 4)

    assert pixel_offset(img, 0, 0) == 0
    assert pixel_offset(img, 3, 2) == 17
    assert pixel_offset(img, 6, 3) == 7 * 4 - 1


#PIXEL ACCESS AND MODIFICATION

func get_pixel*(img : HdrImage; x, y : int) : Color =
    assert valid_coordinates(img, x, y)
    return img.pixels[y * img.width + x]

func set_pixel*(img : var HdrImage; x, y : int; new_col : Color) =
    assert valid_coordinates(img, x, y)
    img.pixels[pixel_offset(img, x, y)] = new_col

func test_get_set_pixel*() =
    var 
        img = newHdrImage(7, 4)
        reference_color = newColor(1.0, 2.0, 3.0)
    set_pixel(img, 3, 2, reference_color)
    assert are_close(reference_color, img.get_pixel(3, 2))