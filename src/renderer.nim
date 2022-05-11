import shapes
import materials
import basictypes

type
  Renderer* : ref object of RootObj
    world* : World
    background_color* : Color
  OnOffRenderer* : ref object of Renderer
    color* : Color
  FlatRenderer* : ref object of Renderer

proc newRenderer*(world : World, color : Color) : Renderer =
  render = Renderer.new()
  render.world = world 
  render.color = color

proc newOnOffRenderer*(world : World, color : Color, background_color : Color = BLACK) : OnOffRenderer =
  render = OnOffRenderer.new()
  render.world = world
  render.color = color
  render.background_color = background_color
  return render

method render*(renderer: Render, ray : Ray): Color {.base.} =
  quit "to overrride1"

method render(renderer: OnOffRenderer, ray : Ray): Color =
  if renderer.world.rayIntersection(ray).isNone: 
    result = renderer.color    
  else:
    result = BLACK
  
  
