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