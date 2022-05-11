import shapes
import basictypes
import cameras
import options

type
  Renderer* = ref object of RootObj
    world* : World
    background_color* : Color
  OnOffRenderer* = ref object of Renderer
    color* : Color
  FlatRenderer* = ref object of Renderer

proc newRenderer*(world : World, color : Color) : Renderer =
  result = Renderer.new()
  result.world = world 

proc newOnOffRenderer*(world : World, color : Color, background_color : Color = BLACK) : OnOffRenderer =
  result = OnOffRenderer.new()
  result.world = world
  result.color = color
  result.background_color = background_color

method render*(renderer: Renderer, ray : Ray): Color {.base.} =
  quit "to overrride1"

method render*(renderer: OnOffRenderer, ray : Ray): Color =
  if renderer.world.rayIntersection(ray).isNone: 
    result = BLACK  
  else:
    result = renderer.color