import ../src/basictypes
import ../src/geometry
import ../src/transformation

type
  Ray* = object
    origin* : Point 
    dir* : Vec
    tmin : float
    tmax : float
    depth : int

proc newRay*(origin : Point, dir : Vec): Ray =
  result.origin = origin
  result.dir = dir
  result.tmin = 1e-5
  result.tmax = Inf
  result.depth = 0

proc are_close*(ray1, ray2 : Ray): bool = 
  return are_close(ray1.origin, ray2.origin) and are_close(ray1.dir, ray2.dir)

proc at*(ray : Ray, t : float): Point = 
  return ray.origin + ray.dir * t


type
  ImageTracer* = object
    image* : HdrImage
    camera* : Camera

proc newImageTracer*(image : HdrImage, camera : Camera): ImageTracer =
  result.image = image
  result.camera = camera

proc fireRay*(imageT : ImageTracer, col : int, row : int, u_pixel = 0.5, v_pixel = 0.5): Ray =
  return imageT.camera.fireRay( (col + u_pixel) / (image.width - 1), (row + v_pixel) / (self.image.height - 1) )

proc fireAllRay*(imageT : var ImageTracer, function : proc) =
  var ray : Ray
  var color : Color
  for row in 0..<(imageT.image.height):
    for col in 0..<(imageT.image.width):
      ray = imageT.fire_ray(col, row)
      color = function(ray)
      imageT.image.setPixel(col, row, color)