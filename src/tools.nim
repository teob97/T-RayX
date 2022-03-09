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

func pixel_offset(img : HdrImage; x, y : int) : int =
    return y * img.width + x

# get_pixel
func get_pixel(img : HdrImage; x, y : int) : Color =
    assert valid_coordinates(img, x, y)
    return img.pixels[y * img.width + x]

# set_pixel
func set_pixel(img : HdrImage; x, y : int; new_col : Color) =
    assert valid_coordinates(img, x, y)
    img.pixels[y * img.width + x] = new_col

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
    return dif.r < epsilon and dif.g < epsilon and dif.b < epsilon