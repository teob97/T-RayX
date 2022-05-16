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

import shapes, basictypes, cameras, materials, options

type
  Renderer* = ref object of RootObj
    world* : World
    background_color* : Color
  OnOffRenderer* = ref object of Renderer
    color* : Color
  FlatRenderer* = ref object of Renderer

proc newOnOffRenderer*(world : World, color : Color = WHITE, background_color : Color = BLACK) : OnOffRenderer =
  result = OnOffRenderer.new()
  result.world = world
  result.color = color
  result.background_color = background_color

proc newFlatRenderer*(world : World, backgroung_color : Color = BLACK) : FlatRenderer =
  result = FlatRenderer.new()
  result.world = world 
  result.background_color = backgroung_color

method render*(renderer: Renderer, ray : Ray): Color {.base.} =
  quit "to overrride1"

method render*(renderer: OnOffRenderer, ray : Ray): Color =
  if renderer.world.rayIntersection(ray).isNone: 
    result = renderer.background_color  
  else:
    result = renderer.color

method render*(renderer: FlatRenderer, ray : Ray): Color =
  var hit = renderer.world.rayIntersection(ray)
  if hit.isNone:
    return renderer.background_color
  var mat = get(hit).material
  return (mat.brdf_function.pigment.getColor(get(hit).surface_point) + mat.emitted_radiance.getColor(get(hit).surface_point))
