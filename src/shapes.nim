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
  AABox * = ref object of Shape
    pmin* : Point
    pmax* : Point
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

#*********************** AXIS-ALIGNED-BOXES *****************************

proc newAABox*(pmin, pmax : Point; transformation : Transformation = newTransformation()) : AABox =
  ## Constructor for an Axis Aligned Boxes with min vertex in pmin and max vertex in pmax
  var box = AABox.new()
  box.pmin = pmin
  box.pmax = pmax
  box.transformation = transformation
  return box

proc checkIntersection(tx_min, tx_max, ty_min, ty_max, tz_min, tz_max: float): Option[float] =
  var 
    t_hit_min : float = tx_min
    t_hit_max : float = tx_max
  if tx_min > ty_max or ty_min > tx_max:
    return none(float)
  if ty_min > tx_min:
    t_hit_min = ty_min
  if ty_max < tx_max:
    t_hit_max = ty_max
  if t_hit_min > tz_max or tz_min > t_hit_max:
    return none(float)
  if tz_min > t_hit_min:
    t_hit_min = tz_min
  if tz_max < t_hit_max:
    t_hit_max = tz_max
  return some(t_hit_min)

proc boxNormal(box : AABox, hit_point : Point, ray : Ray) : Normal =
  ## Check in which face of the cube there is the intersection and calculate the normal using the cross product.
  var
    a = box.pmin
    h = box.pmax
    b = newPoint(h.x, a.y, a.z)
    c = newPoint(h.x, a.y, h.z)
    d = newPoint(a.x, a.y, h.z)
    e = newPoint(a.x, h.y, h.z)
    f = newPoint(a.x, h.y, a.z)
    g = newPoint(h.x, h.y, a.z)
  if hit_point.x == box.pmin.x:
    # yz face (pmin.x, hit_point.y, hit_point.z)
    result = VecToNormal(cross(d-a, f-a))
  elif hit_point.y == box.pmin.y:
    # xz face
    result = VecToNormal(cross(b-a, d-a))
  elif hit_point.z == box.pmin.z:
    # xy face
    result = VecToNormal(cross(f-a, b-a))
  elif hit_point.x == box.pmax.x:
    result = VecToNormal(cross(g-b, c-b))
  elif hit_point.y == box.pmax.y:
    result = VecToNormal(cross(e-f, g-f))
  elif hit_point.z == box.pmax.z:
    result = VecToNormal(cross(c-d, e-d))

method rayIntersection*(box : AABox, ray : Ray) : Option[HitRecord] =
  ## Checks if a ray intersects the AAB
  ## Return a `HitRecord`, or `None` if no intersection was found.  
  var
    inv_ray : Ray = ray.transform(box.transformation.inverse())
    origin_vec = PointToVec(inv_ray.origin)
    tx_min : float = (box.pmin.x - origin_vec.x) / inv_ray.dir.x
    ty_min : float = (box.pmin.y - origin_vec.y) / inv_ray.dir.y
    tz_min : float = (box.pmin.z - origin_vec.z) / inv_ray.dir.z
    tx_max : float = (box.pmax.x - origin_vec.x) / inv_ray.dir.x
    ty_max : float = (box.pmax.y - origin_vec.y) / inv_ray.dir.y
    tz_max : float = (box.pmax.z - origin_vec.z) / inv_ray.dir.z
    t_hit : float
    normal : Normal
  if tx_min > tx_max: swap(tx_min, tx_max)
  if ty_min > ty_max: swap(ty_min, ty_max)
  if tz_min > tz_max: swap(tz_min, tz_max)
  if checkIntersection(tx_min, tx_max, ty_min, ty_max, tz_min, tz_max).isNone:
    return none(HitRecord)
  else:
    t_hit = get(checkIntersection(tx_min, tx_max, ty_min, ty_max, tz_min, tz_max))
  if (t_hit <= inv_ray.tmin) or (t_hit >= inv_ray.tmax):
    return none(HitRecord)
  var hit_point : Point = inv_ray.at(t_hit)
  if PointToVec(hit_point).dot(inv_ray.dir) < 0:
    normal = boxNormal(box, hit_point, inv_ray)
  else:
    normal = -boxNormal(box, hit_point, inv_ray)
  result = some(newHitRecord(world_point = box.transformation * hit_point,
                      normal = normal,
                      surface_point = newVec2d(0,0), #Incorrect. We don't know the correct parametrisation.
                      t = t_hit,
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