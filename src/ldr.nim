#[  T-RayX: a Nim ray tracing library
    Copyright (C) 2022 Matteo Baratto, Eleonora Gatti

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>. ]#
    
import std/[math, options, strformat]
import simplepng, basictypes

#*********************************** OPERATIONS ON HDRIMAGE ***********************************

proc luminosity*(c : Color) : float32 =
    ## Return the luminosity of a pixel
    return (max(max(c.r, c.g), c.b) + min(min(c.r, c.g), c.b)) / 2

proc averageLuminosity*(img : HdrImage, delta : float32 = 1e-10) : float32 =
    ## Return the average luminosity of a HdrImage
    var cumsum : float32 = 0.0
    for pixel in img.pixels:
        cumsum += log10(delta + luminosity(pixel))
    return pow(10.0, cumsum / float(len(img.pixels)))

proc normalizeImage*(img : var HdrImage, factor : float, luminosity : Option[float] = none(float)) =
    ## Normalize a HdrImage
    if luminosity.isNone:
        var luminosity : float32 = averageLuminosity(img)
        for i in 0..<len(img.pixels):
            img.pixels[i] = img.pixels[i] * (factor / luminosity)
    else:
        for i in 0..<len(img.pixels):
            img.pixels[i] = img.pixels[i] * (factor / luminosity.get())

proc clamp*(x : float32) : float32 =
    ## Clamp the luminosity of a pixel
    return x / (1 + x)

proc clampImage*(img : var HdrImage) =
    ## Clamp the entire image
    for i in 0..<len(img.pixels):
        img.pixels[i].r = clamp(img.pixels[i].r)
        img.pixels[i].g = clamp(img.pixels[i].g)
        img.pixels[i].b = clamp(img.pixels[i].b)

#*********************************** WRITING ***********************************

proc writeLdrImage*(img : HdrImage, name : string, gamma : float = 1.0) =
    ## Write a HdrImage in a png image
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
    simplePNG(fmt"output/{name}", p)