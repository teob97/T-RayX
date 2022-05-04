import geometry, cameras, transformation
import std/[math, options]

type
  HitRecord* = object
    world_point* : Point
    normal* : Normal
    surface_point* : Vec2d
    t* : float
    ray* : Ray
  Shape* = ref object of RootObj
  Sphere* = ref object of Shape
    transformation* : Transformation
  Plane* = ref object of Shape
    transformation* : Transformation
  World* = object
    shapes* : seq[Shape]

#*********************************** HITRECORD ***********************************

proc newHitRecord*(world_point : Point, normal : Normal, surface_point : Vec2d, t : float, ray : Ray) : HitRecord =
  result.world_point = world_point
  result.normal = normal
  result.surface_point = surface_point
  result.t = t
  result.ray = ray

proc areClose*(h1, h2: HitRecord, epsilon : float = 1e-5) : bool =
  return areClose(h1.world_point, h2.world_point) and
         areClose(h1.normal, h2.normal) and 
         areClose(h1.surface_point, h2.surface_point) and 
         abs(h1.t - h2.t) < epsilon and 
         areClose(h1.ray, h2.ray)

proc spherePointToUV*(point: Point) : Vec2d =
  ## Convert a 3D point on the surface of the unit sphere into a (u, v) 2D point
  var u : float = arctan2(point.y, point.x) / (2.0 * PI)
  if u >= 0:
    result.u = u
  else:
    result.u = u + 1.0
  result.v = arccos(point.z) / PI

proc sphereNormal*(point: Point, ray_dir: Vec) : Normal =
  ## Compute the normal of a unit sphere
  ## The normal is computed for `point` (a point on the surface of the sphere),
  ## and it is chosen so that it is always in the opposite direction with respect to `ray_dir`.
  if (PointtoVec(point).dot(ray_dir) < 0.0):
    result = newNormal(point.x, point.y, point.z)
  else:
    result = -newNormal(point.x, point.y, point.z)


#*********************************** SHAPE ***********************************

proc newSphere*(transformation : Transformation = newTransformation()) : Sphere =
  var sphere = Sphere.new()
  sphere.transformation = transformation
  return sphere

method rayIntersection*(shape : Shape, ray : Ray): Option[HitRecord] {.base.} =
  quit "to override"

method rayIntersection*(sphere : Sphere, ray : Ray): Option[HitRecord] =
  ## Checks if a ray intersects the sphere
  ## Return a `HitRecord`, or `None` if no intersection was found.
  var 
    inv_ray : Ray = ray.transform(sphere.transformation.inverse())
    origin_vec = PointToVec(inv_ray.origin)
    a : float = inv_ray.dir.squared_norm()
    b : float = 2.0 * origin_vec.dot(inv_ray.dir)
    c : float = origin_vec.squared_norm() - 1.0
    delta : float = b * b - 4.0 * a * c
    first_hit_t : float
  if delta <= 0:
    return none(HitRecord)
  var 
    sqrt_delta : float = sqrt(delta)
    tmin : float = (-b - sqrt_delta) / (2.0 * a)
    tmax : float = (-b + sqrt_delta) / (2.0 * a)
  if (tmin > inv_ray.tmin) and (tmin < inv_ray.tmax):
    first_hit_t = tmin
  elif (tmax > inv_ray.tmin) and (tmax < inv_ray.tmax):
    first_hit_t = tmax
  else:
    return none(HitRecord)
  var hit_point : Point = inv_ray.at(first_hit_t)
  result = some(newHitRecord(world_point = sphere.transformation * hit_point,
                      normal = sphere.transformation * sphereNormal(hit_point, inv_ray.dir),
                      surface_point = spherePointToUV(hit_point),
                      t = first_hit_t,
                      ray = ray))

#*********************************** PLANE ***********************************

proc newPlane*(transformation : Transformation = newTransformation()) : Plane =
  var plane = Plane.new()
  plane.transformation = transformation
  return plane

method rayIntersection*(plane : Plane, ray : Ray): Option[HitRecord] =
  ## Checks if a ray intersects the plane
  ## Return a `HitRecord`, or `None` if no intersection was found.
  var
    inv_ray : Ray = ray.transform(plane.transformation.inverse())
    normal : Normal
  if abs(inv_ray.dir.z) < 1e-5:
    return none(HitRecord)
  var t = -inv_ray.origin.z / inv_ray.dir.z
  if (t <= inv_ray.tmin) or (t >= inv_ray.tmax):
    return none(HitRecord)
  else:
    var hit_point = inv_ray.at(t)
    if inv_ray.dir.z < 0.0:
      normal = newNormal(0.0, 0.0, 1.0)
    else:
      normal = newNormal(0.0, 0.0, -1.0)
    result = some(newHitRecord(world_point = plane.transformation * hit_point,
                               normal = plane.transformation * normal,
                               surface_point = newVec2d(hit_point.x - floor(hit_point.x), hit_point.y - floor(hit_point.y)),
                               t = t,
                               ray = ray))

#*********************************** WORLD ***********************************

proc rayIntersection*(world : World, ray : Ray): Option[HitRecord] =
  ## Iterate over the entire list of shapes and check if there are any intersection with ray
  var closest : Option[HitRecord] = none(HitRecord)
  for shape in world.shapes:
    var intersection = shape.rayIntersection(ray)
    if intersection.isNone:
      continue
    if closest.isNone or intersection.get().t < closest.get().t:
      closest = intersection
  return closest