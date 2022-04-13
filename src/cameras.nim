import ../src/basictypes
import ../src/geometry
import ../src/transformation

#RAY

type
  Ray* = object
    origin* : Point 
    dir* : Vec
    tmin : float
    tmax : float
    depth : int

proc newRay*(origin : Point, dir : Vec, tmin = 1e-5, tmax = Inf, depth = 0): Ray =
  result.origin = origin
  result.dir = dir
  result.tmin = tmin
  result.tmax = tmax
  result.depth = depth

proc areClose*(ray1, ray2 : Ray): bool = 
  return areClose(ray1.origin, ray2.origin) and areClose(ray1.dir, ray2.dir)

proc at*(ray : Ray, t : float): Point = 
  ## Return the position of a ray at a given "time" t
  return ray.origin + ray.dir * t

proc `*`*(ray : Ray, transformation : Transformation): Ray =
  result.origin = transformation * ray.origin
  result.dir = transformation * ray.dir
  result.tmin = ray.tmin
  result.tmax = ray.tmax
  result.depth = ray.depth

#CAMERA

type
  Camera* = object of RootObj
  OrthogonalCamera* = object of Camera
    aspect_ratio* : float
    transformation* : Transformation
  PerspectiveCamera* = object of Camera

proc newOrthogonalCamera*(aspect_ratio : float, transformation = newTransformation()): OrthogonalCamera = 
  result.aspect_ratio = aspect_ratio
  result.transformation = transformation

method fireRay*(cam : Camera; u,v : float): Ray {.base.} =
  quit "to override"

method fireRay*(cam : OrthogonalCamera; u,v : float): Ray = 
  let origin = newPoint(-1.0, (1.0 - 2 * u) * cam.aspect_ratio, 2 * v - 1)
  let dir = VEC_X
  return newRay(origin = origin, dir = dir, tmin = 1.0) * cam.transformation

#IMAGE TRACER

type
  ImageTracer* = object
    image* : HdrImage
    camera* : Camera

proc newImageTracer*(image : HdrImage, camera : OrthogonalCamera): ImageTracer =
  result.image = image
  result.camera = camera

proc fireRay*(imageT : ImageTracer, col : int, row : int, u_pixel = 0.5, v_pixel = 0.5): Ray =
  var u : float = (col.float + u_pixel) / (imageT.image.width - 1).float
  var v : float = (row.float + v_pixel) / (imageT.image.height - 1).float
  return imageT.camera.fireRay(u, v)

proc fireAllRay*(imageT : var ImageTracer, function : proc) =
  var ray : Ray
  var color : Color
  for row in 0..<(imageT.image.height):
    for col in 0..<(imageT.image.width):
      ray = imageT.fire_ray(col, row)
      color = function(ray)
      imageT.image.setPixel(col, row, color)