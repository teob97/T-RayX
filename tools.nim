type
    Color* = object
        r*, g*, b* : float32
        
        proc newColor*(r=0.0, g=0.0, b=0.0: float32) : Color =
            var C : Color
            C.r = r
            C.g = g
            C.b = b
            return C

    HdrImage* = object
        width*, height*: int
        pixels* = seq[Color]