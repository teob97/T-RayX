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
import std/[math, options]

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
  PathTracer* = ref object of Renderer
    ## A simple path-tracing renderer.
    pcg* : PCG
    num_of_rays* : int
    max_depth* : int
    russian_roulette_limit* : int

#**************************************************** CONSTRUCTORS ****************************************************

proc newOnOffRenderer*(world : World, color : Color = WHITE, background_color : Color = BLACK) : OnOffRenderer =
  result = OnOffRenderer.new()
  result.world = world
  result.color = color
  result.background_color = background_color

proc newFlatRenderer*(world : World, background_color : Color = BLACK) : FlatRenderer =
  result = FlatRenderer.new()
  result.world = world 
  result.background_color = background_color

proc newPathTracer*(world: World, background_color: Color = BLACK, pcg: PCG = newPCG(), num_of_rays: int = 10,
                    max_depth: int = 2, russian_roulette_limit = 3) : PathTracer =
  ## The algorithm implemented here allows the caller to tune number of rays thrown at each iteration, as well as the
  ## maximum depth. It implements Russian roulette, so in principle it will take a finite time to complete the
  ## calculation even if you set max_depth to `math.inf`.
  result = PathTracer.new()
  result.world = world 
  result.background_color = background_color
  result.pcg = pcg
  result.num_of_rays = num_of_rays
  result.max_depth = max_depth
  result.russian_roulette_limit = russian_roulette_limit

#**************************************************** SCATTER RAY ****************************************************

method scatterRay(brdf_function : BRDF, pcg : var PCG, incoming_dir : Vec, interaction_point : Point, normal : Normal, depth : int): Ray {.base.} =
  ## Sampling new Ray using the importance sampling. Scattered Rays are generated over the semi-shpere with a specific distribution depending on the BRDF type.
  quit "to override"

method scatterRay(brdf_function : DiffuseBRDF, pcg : var PCG, incoming_dir : Vec, interaction_point : Point, normal : Normal, depth : int): Ray =
  let
    onb : ONB = createONBfromZ(normal) 
    cos_theta_sq = pcg.random_float()
    cos_theta = sqrt(cos_theta_sq)
    sin_theta = sqrt(1.0 - cos_theta_sq)
    phi = 2.0 * PI * pcg.random_float()
  result = newRay(origin = interaction_point,
                  dir = onb.e1 * cos(phi) * cos_theta + onb.e2 * sin(phi) * cos_theta + onb.e3 * sin_theta,
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

#**************************************************** RENDERER ****************************************************

method render*(renderer: Renderer, ray: Ray): Color {.base, locks: "unknown".} =
  ## Estimate the radiance along a ray.
  quit "to overrride1"

method render*(renderer: OnOffRenderer, ray: Ray): Color {.locks: "unknown".} =
  ## Estimate the radiance along a ray using OnOffRenderer.
  if renderer.world.rayIntersection(ray).isNone: 
    result = renderer.background_color  
  else:
    result = renderer.color

method render*(renderer: FlatRenderer, ray: Ray): Color {.locks: "unknown".} =
  ## Estimate the radiance along a ray using FlatRenderer.
  var hit = renderer.world.rayIntersection(ray)
  if hit.isNone:
    return renderer.background_color
  var mat = get(hit).material
  return (mat.brdf_function.pigment.getColor(get(hit).surface_point) + mat.emitted_radiance.getColor(get(hit).surface_point))

method render*(renderer: PathTracer, ray: Ray): Color {.locks: "unknown".} =
  ## Estimate the radiance along a ray using PathTracer.
  if ray.depth > renderer.max_depth:
    return newColor(0.0, 0.0, 0.0)
  var hit_record = renderer.world.rayIntersection(ray)
  if hit_record.isNone:
    return renderer.background_color
  var
    hit_record_buff = hit_record.get()
    hit_material = hit_record_buff.material
    hit_color = hit_material.brdf_function.pigment.getColor(hit_record_buff.surface_point)
    emitted_radiance = hit_material.emitted_radiance.get_color(hit_record_buff.surface_point)
    hit_color_lum = max(hit_color.r, max(hit_color.g, hit_color.b))

  # Russian roulette
  if ray.depth >= renderer.russian_roulette_limit:
    var q : float = max(0.05, 1 - hit_color_lum)
    if renderer.pcg.random_float() > q:
      # Keep the recursion going, but compensate for other potentially discarded rays
      hit_color =  ( 1.0 / (1.0 - q) ) * hit_color
    else:
      # Terminate prematurely
      return emitted_radiance
  # Monte Carlo integration
  var cum_radiance = newColor(0.0, 0.0, 0.0)
  if hit_color_lum > 0.0:  # Only do costly recursions if it's worth it
    var 
      new_radiance : Color
      new_ray : Ray
    for ray_index in 0..renderer.num_of_rays: 
      new_ray = hit_material.brdf_function.scatterRay(pcg=renderer.pcg,
                                                        incoming_dir=hit_record_buff.ray.dir,
                                                        interaction_point=hit_record_buff.world_point,
                                                        normal=hit_record_buff.normal,
                                                        depth=ray.depth + 1)
      # Recursive call
      new_radiance = renderer.render(new_ray)
      cum_radiance = cum_radiance + hit_color * new_radiance
  return emitted_radiance + cum_radiance * (1.0 / renderer.num_of_rays.float)