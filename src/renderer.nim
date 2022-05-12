import shapes
import basictypes
import cameras
import materials
import options

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
