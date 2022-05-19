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
    
import basictypes, cameras, renderer, pcg
import std/math

type
  ImageTracer* = object
    ## Trace an image by shooting light rays through each of its pixels.
    image* : HdrImage
    camera* : Camera
    samples_per_side* : int
    pcg* : PCG

proc newImageTracer*(image : HdrImage, camera : Camera, samples_per_side : int = 0, pcg : PCG = newPCG()): ImageTracer =
  ## Initialize an ImageTracer object
  ## The parameter `image` must be a `HdrImage` object that has already been initialized.
  ## The parameter `camera` must be a descendeant of the `Camera` object.
  ## If `samples_per_side` is larger than zero, stratified sampling will be applied to each pixel in the
  ## image, using the random number generator `pcg`.
  result.image = image
  result.camera = camera
  result.samples_per_side = samples_per_side
  result.pcg = pcg

proc fireRay*(imageT : ImageTracer, col : int, row : int, u_pixel = 0.5, v_pixel = 0.5): Ray =
  ## Shoot one light ray through image pixel (col, row)
  ## The parameters (col, row) are measured in the same way as they are in `HdrImage`: the bottom left
  ## corner is placed at (0, 0).
  ## The values of `u_pixel` and `v_pixel` are floating-point numbers in the range [0, 1]. They specify where
  ## the ray should cross the pixel; passing 0.5 to both means that the ray will pass through the pixel's center.
  var u : float = (col.float + u_pixel) / (imageT.image.width).float
  var v : float = 1.0 - (row.float + v_pixel) / (imageT.image.height).float
  return imageT.camera.fireRay(u, v)

proc fireAllRays*(imageT : var ImageTracer, renderer : Renderer) =
  ## Shoot several light rays crossing each of the pixels in the image.
  ## For each pixel in the `HdrImage` object fire one ray, and pass it to the `renderer`, which
  ## must accept a `Ray` object as its only parameter and must return a `Color` object telling the
  ## color to assign to that pixel in the image.
  var ray : Ray
  var color : Color
  for row in 0..<(imageT.image.height):
    for col in 0..<(imageT.image.width):
      var cum_color = newColor(0.0, 0.0, 0.0)
      # If we want antialiasing -> samples_per_side should be > 0
      if imageT.samples_per_side > 0:
        # Run stratified sampling over the pixel's surface
        for inter_pixel_row in 0..imageT.samples_per_side:
          for inter_pixel_col in 0..imageT.samples_per_side:
            let
              u_pixel = (inter_pixel_col.float + imageT.pcg.random_float()) / imageT.samples_per_side.float
              v_pixel = (inter_pixel_row.float + imageT.pcg.random_float()) / imageT.samples_per_side.float
            ray = imageT.fireRay(col=col, row=row, u_pixel=u_pixel, v_pixel=v_pixel)
            cum_color = cum_color + renderer.render(ray)
        imageT.image.setPixel(col, row, cum_color * (1 / pow(imageT.samples_per_side.float, 2)))
      else:
        ray = imageT.fire_ray(col, row)
        color = renderer.render(ray)
        imageT.image.setPixel(col, row, color)
    