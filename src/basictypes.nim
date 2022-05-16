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

type
  Color* = object
    ## Color object
    r*, g*, b* : float32
  HdrImage* = object
    ## HDR Image object: width, height are int
    ## and pixels is a seq of color
    width*, height*: int
    pixels* : seq[Color]
        
#*********************************** COLOR ***********************************

func newColor*(r : float32 = 0.0; g : float32 = 0.0; b : float32 = 0.0) : Color =
    ## Constructor of Color, default (0, 0, 0) [Black] 
    var C : Color
    C.r = r
    C.g = g
    C.b = b
    return C

const
  BLACK* = newColor(0.0, 0.0, 0.0)
  WHITE* = newColor(1.0, 1.0, 1.0)

#*********************************** HDR IMAGE ***********************************

func newHdrImage*(width, height : int) : HdrImage =
    ## Costructor of HdrImage
    var img : HdrImage
    var C : Color = newColor(0.0, 0.0, 0.0)
    img.width = width
    img.height = height
    img.pixels = newSeq[Color](width*height)
    for i in 0..<width*height:
        img.pixels[i] = C
    return img

func pixelOffset*(img : HdrImage; x, y : int) : int =
    ## Given (x,y) the coordinates of the pixel, return the corresponding index inside the vector in which the pixel is stored.
    return y * img.width + x

##*********************************** OPERATIONS ***********************************

func `+` *(c1 : Color, c2 : Color): Color =
  ## Return the sum of two pixels
  return newColor(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)

func `-` *(c1 : Color, c2 : Color): Color =
  ## Return the difference of two pixels
  return newColor(c1.r - c2.r, c1.g - c2.g, c1.b - c2.b)

func `*` *(c1, c2: Color) : Color =
  ## Return the product between two pixels
  return newColor(c1.r * c2.r, c1.g * c2.g, c1.b * c2.b)

func `*` *(a: float32, c: Color) : Color =
  ## Return the product between a scalar and a pixel
  return newColor(c.r * a, c.g * a, c.b * a)

func `*` *(c: Color, a: float32) : Color =
  ## Return the product between a pixel and a scalar
  return newColor(c.r * a, c.g * a, c.b * a)

func areClose *(c1, c2: Color; epsilon : float32 = 1e-5) : bool =
  ## Check if two colors are close
  var dif : Color = c1 - c2
  return abs(dif.r) < epsilon and abs(dif.g) < epsilon and abs(dif.b) < epsilon

func test_valid_coordinates*(img : HdrImage; width, height : int) : bool =
  ## Check if the coordinates are positives and if the are in the (width, height) range. 
  return width >= 0 and width < img.width and height >= 0 and height < img.height 

func getPixel*(img : HdrImage; x, y : int) : Color =
  ## Get pixel color in position (x,y)
  if test_valid_coordinates(img, x ,y) == false:
    raise newException(IOError, "Invalid coordinates in getPixel function.")
  return img.pixels[y * img.width + x]

func setPixel*(img : var HdrImage; x, y : int; new_col : Color) =
  ## Set pixel color in position (x,y)
  if test_valid_coordinates(img, x, y) == false:
    raise newException(IOError, "Invalid coordinates in setPixel function.")
  img.pixels[pixelOffset(img, x, y)] = new_col