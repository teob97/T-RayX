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

import shapes, basictypes, cameras, materials, pcg, geometry
import options, math

type
  Renderer* = ref object of RootObj
    ## An object implementing a solver of the rendering equation.
    world* : World
    background_color* : Color
  OnOffRenderer* = ref object of Renderer
    ## A on/off renderer.
    ## This renderer is mostly useful for debugging purposes, as it is really fast, but it produces boring images.
    color* : Color
  FlatRenderer* = ref object of Renderer
    ## A «flat» renderer.
    ## This renderer estimates the solution of the rendering equation by neglecting any contribution of the light.
    ## It just uses the pigment of each surface to determine how to compute the final radiance.

proc newOnOffRenderer*(world : World, color : Color = WHITE, background_color : Color = BLACK) : OnOffRenderer =
  result = OnOffRenderer.new()
  result.world = world
  result.color = color
  result.background_color = background_color

proc newFlatRenderer*(world : World, backgroung_color : Color = BLACK) : FlatRenderer =
  result = FlatRenderer.new()
  result.world = world 
  result.background_color = backgroung_color

#*********************************************************************************************************************

method scatterRay(brdf_function : BRDF, pcg : var PCG, incoming_dir : Vec, interaction_point : Point, normal : Normal, depth : int): Ray {.base.} =
  ## Sampling new Ray using the importance sampling. Scattered Rays are generated over the semi-shpere with a specific distribution depending on the BRDF type.
  quit "to override"

method scatterRay(brdf_function : DiffuseBRDF, pcg : var PCG, incoming_dir : Vec, interaction_point : Point, normal : Normal, depth : int): Ray =
  var
    onb : ONB = createONBfromZ(normal) 
    e1 : Vec = onb.e1
    e2 : Vec = onb.e2
    e3 : Vec = onb.e3
    cos_theta_sq = pcg.random_float()
    cos_theta = sqrt(cos_theta_sq)
    sin_theta = sqrt(1.0 - cos_theta_sq)
    phi = 2.0 * PI * pcg.random_float()
  result = newRay(origin = interaction_point,
                  dir = e1 * cos(phi) * cos_theta + e2 * sin(phi) * cos_theta + e3 * sin_theta,
                  tmin = 1.0e-3,
                  tmax = Inf,
                  depth = depth)

method scatterRay(brdf_function : SpecularBRDF, pcg : var PCG, incoming_dir : Vec, interaction_point : Point, normal : Normal, depth : int): Ray =
  var
    ray_dir = newVec(incoming_dir.x, incoming_dir.y, incoming_dir.z).normalization()
    normal = normalToVec(normal).normalization()
    dot_prod = normal.dot(ray_dir)
  result = newRay(origin = interaction_point,
                  dir = ray_dir - normal * 2 * dot_prod,
                  tmin = 1.0e-5,
                  tmax = Inf,
                  depth = depth)
  


#*********************************************************************************************************************

method render*(renderer: Renderer, ray : Ray): Color {.base.} =
  ## Estimate the radiance along a ray.
  quit "to overrride1"

method render*(renderer: OnOffRenderer, ray : Ray): Color =
  ## Estimate the radiance along a ray.
  if renderer.world.rayIntersection(ray).isNone: 
    result = renderer.background_color  
  else:
    result = renderer.color

method render*(renderer: FlatRenderer, ray : Ray): Color =
  ## Estimate the radiance along a ray.
  var hit = renderer.world.rayIntersection(ray)
  if hit.isNone:
    return renderer.background_color
  var mat = get(hit).material
  return (mat.brdf_function.pigment.getColor(get(hit).surface_point) + mat.emitted_radiance.getColor(get(hit).surface_point))
