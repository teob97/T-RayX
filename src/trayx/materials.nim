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

import geometry, basictypes
import std/math

type
  Pigment* = ref object of RootObj
    ## Pigment object
    ## This abstract class represents a pigment, i.e., a function that associates a color with
    ## each point on a parametric surface (u,v). Call the method :meth:`.Pigment.getColor` to
    ## retrieve the color of the surface given a `Vec2d` object.
  UniformPigment* = ref object of Pigment
    ## Uniform Pigment: only one color
    color* : Color
  ImagePigment* = ref object of Pigment
    ## Image Pigment: the texture is given through a PFM image.
    image* : HdrImage
  CheckeredPigment* = ref object of Pigment
    ## Checkered Pigment: chessboard pattern.
    ## The number of rows/columns in the checkered pattern is tunable, but you cannot have a different number of
    ## repetitions along the u/v directions.
    color1* : Color
    color2* : Color
    num_of_steps* : int
  BRDF* = ref object of RootObj
    ## An abstract class representing a Bidirectional Reflectance Distribution Function
    pigment* : Pigment
  DiffuseBRDF* = ref object of BRDF
    ## A class representing an ideal diffuse BRDF (also called «Lambertian»)
    reflectance* : float
  SpecularBRDF* = ref object of BRDF
    ## A class representing an ideal specular BRDF (mirror)
    threshold_angle_rad : float
  Material* = object
    ## Material object
    brdf_function* : BRDF
    emitted_radiance* : Pigment


#*********************************** PIGMENT ***********************************

proc newUniformPigment*(color : Color = WHITE) : UniformPigment =
  result = UniformPigment.new()
  result.color = color

proc newImagePigment*(image : HdrImage) : ImagePigment =
  result = ImagePigment.new()
  result.image = image

proc newCheckeredPigment*(color1 : Color = newColor(0.03, 0.27, 0.8), color2 : Color = newColor(0.98, 0.68, 0.08), num_of_steps : int = 10) : CheckeredPigment =
  result = CheckeredPigment.new()
  result.color1 = color1
  result.color2 = color2
  result.num_of_steps = num_of_steps

method getColor*(pig : Pigment; uv : Vec2d): Color {.base.} =
  quit "to override"

method getColor*(pig : UniformPigment; uv : Vec2d): Color =
  result = pig.color

method getColor*(pig : ImagePigment; uv : Vec2d): Color =
  var
    col = int(uv.u * pig.image.width.float)
    row = int(uv.v * pig.image.height.float)
  if col >= pig.image.width:
    col = pig.image.width - 1
  if row >= pig.image.height:
    row = pig.image.height - 1
  result = pig.image.getPixel(col, row)

method getColor*(pig : CheckeredPigment; uv : Vec2d): Color =
  var
    int_u = int(floor(pig.num_of_steps.float * uv.u))
    int_v = int(floor(pig.num_of_steps.float * uv.v))
  if (int_u mod 2) == (int_v mod 2):
    result = pig.color1
  else:
    result = pig.color2

#*********************************** BRDF ***********************************

proc newDiffuseBRDF*(pigment : Pigment = newUniformPigment()): DiffuseBRDF =
  result = DiffuseBRDF.new()
  result.pigment = pigment
  result.reflectance = 1.0

proc newSpecularBRDF*(pigment : Pigment = newUniformPigment(), angle : float = PI / 1800.0): SpecularBRDF =
  result = SpecularBRDF.new()
  result.pigment = pigment
  result.threshold_angle_rad = angle

method eval*(brdf : BRDF, normal : Normal; in_dir, out_dir : Vec; uv : Vec2d): Color {.base.} =
  quit "to override"

method eval*(brdf : DiffuseBRDF, normal : Normal; in_dir, out_dir : Vec; uv : Vec2d): Color =
  return brdf.pigment.getColor(uv) * (brdf.reflectance / PI)

method eval*(brdf : SpecularBRDF, normal : Normal, in_dir, out_dir : Vec; uv : Vec2d): Color =
  let
    theta_in = arccos(normalToVec(normal).dot(in_dir))
    theta_out = arccos(normalToVec(normal).dot(out_dir))
  if abs(theta_in - theta_out) < brdf.threshold_angle_rad:
    return brdf.pigment.get_color(uv)
  else:
    return newColor(0.0, 0.0, 0.0)

#********************************** MATERIAL *******************************

proc newMaterial*(brdf : BRDF = newDiffuseBRDF(newUniformPigment()), emitted_radiance : Pigment = newUniformPigment(BLACK)): Material =
  result.brdf_function = brdf
  result.emitted_radiance = emitted_radiance