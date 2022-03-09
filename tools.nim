type
    Color* = object
        r*, g*, b* : float32

    HdrImage* = object
        width*, height*: int
        pixels* : seq[Color]
        

func newColor*(r : float32 = 0.0; g : float32 = 0.0; b : float32 = 0.0) : Color =
    var C : Color
    C.r = r
    C.g = g
    C.b = b
    return C


func `*` *(c1, c2: Color) : Color =
    return newColor(c1.r * c2.r, c1.g * c2.g, c1.b * c2.b)

func `*` *(a: float32, c: Color) : Color =
    return newColor(c.r * a, c.g * a, c.b * a)

func are_close *(c1, c2: Color; epsilon : float32 = 1e-5) : bool =
    var dif : Color = c1 - c2
    return dif.r < epsilon and dif.g < epsilon and dif.b < epsilon