# CLASS

type
    Color* = object
        r*, g*, b* : float32

    HdrImage* = object
        width*, height*: int
        pixels* : seq[Color]
        
# CONSTRUCTORS

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

# FUNCTIONS

func pixelOffset*(img : HdrImage; x, y : int) : int =
    return y * img.width + x

# OPERATOR OVERLOAD

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

func areClose *(c1, c2: Color; epsilon : float32 = 1e-5) : bool =
    var dif : Color = c1 - c2
    return abs(dif.r) < epsilon and abs(dif.g) < epsilon and abs(dif.b) < epsilon

# FUNCTIONS TEST

func test_valid_coordinates*(img : HdrImage; width, height : int) : bool =
    return width >= 0 and width < img.width and height >= 0 and height < img.height 

# PIXEL ACCESS AND MODIFICATION

func getPixel*(img : HdrImage; x, y : int) : Color =
    if test_valid_coordinates(img, x ,y)==false:
        raise newException(IOError, "Invalid coordinates in getPixel function.")
    return img.pixels[y * img.width + x]

func setPixel*(img : var HdrImage; x, y : int; new_col : Color) =
    if test_valid_coordinates(img, x, y) == false:
        raise newException(IOError, "Invalid coordinates in setPixel function.")
    img.pixels[pixelOffset(img, x, y)] = new_col