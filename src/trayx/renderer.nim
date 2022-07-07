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
  PointLightRenderer* = ref object of Renderer
    ## A simple point-light renderer.
    ambient_color* : Color

# Methods necessary for "render" procedure in trayx.nim
method setNumOfRays*(x : var Renderer, n : int) {.base.} =
  quit "To override"

method setMaxDepth*(x : var Renderer, n : int) {.base.} =
  quit "To override"

method setPCG*(x : var Renderer, s1 : uint64 = 42, s2 : uint64 = 54) {.base.} =
  quit "To override"

method setNumOfRays*(x : var PathTracer, n : int) =
  x.num_of_rays = n

method setMaxDepth*(x : var PathTracer, n : int) =
  x.max_depth = n

method setPCG*(x : var PathTracer, s1 : uint64 = 42, s2 : uint64 = 54) =
  x.pcg = newPCG(init_state = s1, init_seq = s2)

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
                    max_depth: int = 2, russian_roulette_limit : int = 3) : PathTracer =
  result = PathTracer.new()
  result.world = world 
  result.background_color = background_color
  result.pcg = pcg
  result.num_of_rays = num_of_rays
  result.max_depth = max_depth
  result.russian_roulette_limit = russian_roulette_limit

proc newPointLightRenderer*(world : World, background_color : Color = BLACK, ambient_color : Color = newColor(0.1, 0.1, 0.1)) : PointLightRenderer =
  result = PointLightRenderer.new()
  result.world = world
  result.background_color = background_color
  result.ambient_color = ambient_color

#**************************************************** SCATTER RAY ****************************************************

method scatterRay(brdf_function : BRDF, pcg : var PCG, incoming_dir : Vec, interaction_point : Point, normal : Normal, depth : int): Ray {.base.} =
  ## Sampling new Ray using the importance sampling. Scattered Rays are generated over the semi-shpere with a specific distribution depending on the BRDF type.
  quit "to override"

method scatterRay(brdf_function : DiffuseBRDF, pcg : var PCG, incoming_dir : Vec, interaction_point : Point, normal : Normal, depth : int): Ray =
  let
    onb : ONB = createONBfromZ(normal) 
    cos_theta_sq  : float = pcg.random_float()
    cos_theta : float = sqrt(cos_theta_sq)
    sin_theta : float = sqrt(1.0 - cos_theta_sq)
    phi = 2.0 * PI * pcg.random_float()
  result = newRay(origin = interaction_point,
                  dir = onb.e1 * cos(phi) * cos_theta + onb.e2 * sin(phi) * cos_theta + onb.e3 * sin_theta,
                  tmin = 1.0e-5,
                  tmax = Inf,
                  depth = depth)

method scatterRay(brdf_function : SpecularBRDF, pcg : var PCG, incoming_dir : Vec, interaction_point : Point, normal : Normal, depth : int): Ray =
  let
    ray_dir : Vec = newVec(incoming_dir.x, incoming_dir.y, incoming_dir.z).normalization()
    normal : Vec = normalToVec(normal).normalization()
    dot_prod : float = normal.dot(ray_dir)
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
  var hit : Option[HitRecord] = renderer.world.rayIntersection(ray)
  if hit.isNone:
    return renderer.background_color
  var mat : Material = get(hit).material
  return (mat.brdf_function.pigment.getColor(get(hit).surface_point) + mat.emitted_radiance.getColor(get(hit).surface_point))

method render*(renderer: PathTracer, ray: Ray): Color {.locks: "unknown".} =
  ## Estimate the radiance along a ray using PathTracer.
  ## The algorithm implemented here allows the caller to tune number of rays thrown at each iteration, as well as the
  ## maximum depth. It implements Russian roulette, so in principle it will take a finite time to complete the
  ## calculation even if you set max_depth to `Inf`.
  # Exit Contition
  if ray.depth > renderer.max_depth:
    return newColor(0.0, 0.0, 0.0)
  # Find the intersection
  let hit_record : Option[HitRecord] = renderer.world.rayIntersection(ray)
  if hit_record.isNone:
    return renderer.background_color
  # Extract all the HitRecord's information
  var
    hit_record_buff : HitRecord = hit_record.get()
    hit_material : Material = hit_record_buff.material
    hit_color : Color = hit_material.brdf_function.pigment.getColor(hit_record_buff.surface_point)
    emitted_radiance : Color = hit_material.emitted_radiance.getColor(hit_record_buff.surface_point)
    hit_color_lum : float = max(hit_color.r, max(hit_color.g, hit_color.b))
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
  var cum_radiance : Color = newColor(0.0, 0.0, 0.0)
  if hit_color_lum > 0.0:  # Only do costly recursions if it's worth it
    var 
      new_radiance : Color
    for ray_index in 0..<renderer.num_of_rays: 
      var new_ray : Ray = hit_material.brdf_function.scatterRay(pcg=renderer.pcg,
                                                      incoming_dir=hit_record_buff.ray.dir,
                                                      interaction_point=hit_record_buff.world_point,
                                                      normal=hit_record_buff.normal,
                                                      depth=ray.depth + 1)
      # Recursive call
      new_radiance = renderer.render(new_ray)
      cum_radiance = cum_radiance + hit_color * new_radiance
  return emitted_radiance + cum_radiance * (1.0 / renderer.num_of_rays.float)

method render*(renderer : PointLightRenderer, ray : Ray): Color {.locks: "unknown".} =
  ## Point light renderer.
  
  let hit_record_buff : Option[HitRecord] = renderer.world.rayIntersection(ray)
  if hit_record_buff.isNone():
    return renderer.background_color

  let 
    hit_record  : HitRecord = hit_record_buff.get()
    hit_material : Material = hit_record.material
  var 
    result_color : Color = renderer.ambient_color
    distance_factor : float

  for cur_light in renderer.world.point_lights:
    if renderer.world.is_point_visible(point = cur_light.position, observer_pos=hit_record.world_point):
      var
        distance_vec : Vec = hit_record.world_point - cur_light.position
        distance : float = distance_vec.norm()
        in_dir : Vec = distance_vec * (1.0 / distance)
        cos_theta  : float = max(0.0, normalized_dot(-distance_vec, hit_record.normal))
      
      if (cur_light.linear_radius > 0):
        distance_factor = (cur_light.linear_radius / distance)^2
      else:
        distance_factor = 1.0
      
      var 
        emitted_color : Color = hit_material.emitted_radiance.get_color(hit_record.surface_point)
        brdf_color : Color = hit_material.brdf_function.eval(
          normal = hit_record.normal,
          in_dir = in_dir,
          out_dir = -ray.dir,
          uv = hit_record.surface_point,
        )
      result_color = result_color + (emitted_color + brdf_color) * cur_light.color * cos_theta * distance_factor
  return result_color 
