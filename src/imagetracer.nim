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
    
import basictypes, cameras, renderer

type
  ImageTracer* = object
    ## Image Tracer object
    image* : HdrImage
    camera* : Camera

proc newImageTracer*(image : HdrImage, camera : Camera): ImageTracer =
  ## Constructor of ImageTracer
  result.image = image
  result.camera = camera

proc fireRay*(imageT : ImageTracer, col : int, row : int, u_pixel = 0.5, v_pixel = 0.5): Ray =
  ## Send a new Ray in pixel (col, row) taking in account the position of the ray inside the pixel (u_pixel, v_pixel). Default: the ray is in the centre of the pixel.
  var u : float = (col.float + u_pixel) / (imageT.image.width).float
  var v : float = 1.0 - (row.float + v_pixel) / (imageT.image.height).float
  return imageT.camera.fireRay(u, v)

proc fireAllRays*(imageT : var ImageTracer, renderer : Renderer) =
  ## Resolve the rendering equation using a given "function" and then fill all the pixels in the image.
  var ray : Ray
  var color : Color
  for row in 0..<(imageT.image.height):
    for col in 0..<(imageT.image.width):
      ray = imageT.fire_ray(col, row)
      color = renderer.render(ray)
      imageT.image.setPixel(col, row, color)