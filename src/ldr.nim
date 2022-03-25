import std/math
import std/options
import std/streams
import simplepng
import basictypes
import pfm

# Luminosity
proc luminosity*(c : Color) : float32 =
    return (max(max(c.r, c.g), c.b) + min(min(c.r, c.g), c.b)) / 2

proc average_luminosity*(img : HdrImage, delta : float32 = 1e-10) : float32 =
    var cumsum : float32 = 0.0
    for pixel in img.pixels:
        cumsum += log10(delta + luminosity(pixel))
    return pow(10.0, cumsum / float(len(img.pixels)))

# Normalization
proc normalize_image*(img : var HdrImage, a : float, luminosity : Option[float] = none(float)) =
    if luminosity.isNone:
        var luminosity : float32 = average_luminosity(img)
    for i in 0..<len(img.pixels):
        img.pixels[i] = img.pixels[i] * (a / luminosity.get())

# Light points
proc clamp*(x : float32) : float32 =
    return x / (1 + x)

proc clamp_image*(img : var HdrImage) =
    for i in 0..<len(img.pixels):
        img.pixels[i].r = clamp(img.pixels[i].r)
        img.pixels[i].g = clamp(img.pixels[i].g)
        img.pixels[i].b = clamp(img.pixels[i].b)

# Write LDR Image
proc write_ldr_image*(img : HdrImage, stream : Stream, name : string, gamma : float = 1.0) =
    var p = initPixels(img.width, img.height)
    var c : Color
    var i : int = 0
    for y in 0..<img.height:
        for x in 0..<img.width:
            c = img.get_pixel(x, y)
            setColor(p.getPixel(x,y),
            int(255 * pow(c.r, 1 / gamma)),
            int(255 * pow(c.g, 1 / gamma)),
            int(255 * pow(c.b, 1 / gamma)), 255)
            i += 1
    simplePNG(name, p)