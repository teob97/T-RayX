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
    
import geometry, cameras, transformation, materials
import std/[math, options]

type
  HitRecord* = object
    world_point* : Point
    normal* : Normal
    surface_point* : Vec2d
    t* : float
    ray* : Ray
    material* : Material
  AABoundingBox* = ref object
    pmin* : Point
    pmax* : Point
  Shape* = ref object of RootObj
    transformation* : Transformation
    material* : Material
    bound_box* : AABoundingBox
  Sphere* = ref object of Shape
  AABox * = ref object of Shape
    pmin* : Point
    pmax* : Point
  Plane* = ref object of Shape
  Cylinder* = ref object of Shape
    r* : float
    z_min* : float
    z_max* : float
    phi_max* : float
  World* = object
    shapes* : seq[Shape]

#*********************************** HITRECORD ***********************************

proc newHitRecord*(world_point : Point, normal : Normal, surface_point : Vec2d, t : float, ray : Ray, material : Material = newMaterial()) : HitRecord =
  result.world_point = world_point
  result.normal = normal
  result.surface_point = surface_point
  result.t = t
  result.ray = ray
  result.material = material

proc newAABoundungBox(pmin, pmax : Point): AABoundingBox =
  result = AABoundingBox.new()
  result.pmin = pmin
  result.pmax = pmax

proc areClose*(h1, h2: HitRecord, epsilon : float = 1e-5) : bool =
  return areClose(h1.world_point, h2.world_point) and
         areClose(h1.normal, h2.normal) and 
         areClose(h1.surface_point, h2.surface_point) and 
         abs(h1.t - h2.t) < epsilon and 
         areClose(h1.ray, h2.ray)

#*********************************** WORLD ***********************************

method rayIntersection*(shape : Shape, ray : Ray): Option[HitRecord] {.base.} =
  quit "to override"

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


#******************************************************************************
#*********************************** SPHERE ***********************************
#******************************************************************************

proc newSphere*(transformation : Transformation = newTransformation(), material : Material = newMaterial()) : Sphere =
  result = Sphere.new()
  result.transformation = transformation
  result.material = material

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
                      ray = ray,
                      material = sphere.material))


#*************************************************************************
#*********************** AXIS-ALIGNED-BOXES ******************************
#*************************************************************************

proc newAABox*(pmin, pmax : Point; transformation : Transformation = newTransformation(), material : Material = newMaterial()) : AABox =
  ## Constructor for an Axis Aligned Boxes with min vertex in pmin and max vertex in pmax
  result = AABox.new()
  result.pmin = pmin
  result.pmax = pmax
  result.transformation = transformation
  result.material = material

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

proc boxIntersection(pmin, pmax : Point; ray : Ray) : bool =
  ## Check if there is an intersection with the boundary box
  var
    tx_min : float = (pmin.x - ray.origin.x) / ray.dir.x
    ty_min : float = (pmin.y - ray.origin.y) / ray.dir.y
    tz_min : float = (pmin.z - ray.origin.z) / ray.dir.z
    tx_max : float = (pmax.x - ray.origin.x) / ray.dir.x
    ty_max : float = (pmax.y - ray.origin.y) / ray.dir.y
    tz_max : float = (pmax.z - ray.origin.z) / ray.dir.z
  if tx_min > tx_max: swap(tx_min, tx_max)
  if ty_min > ty_max: swap(ty_min, ty_max)
  if tz_min > tz_max: swap(tz_min, tz_max)
  if checkIntersection(tx_min, tx_max, ty_min, ty_max, tz_min, tz_max).isNone:
    return false
  else:
    return true


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
                      ray = ray,
                      material = box.material))


#*****************************************************************************
#*********************************** PLANE ***********************************
#*****************************************************************************

proc newPlane*(transformation : Transformation = newTransformation(), material : Material = newMaterial()) : Plane =
  result = Plane.new()
  result.transformation = transformation
  result.material = material

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
                               ray = ray,
                               material = plane.material))

#*************************************************************************
#**************************** CYLINDER ***********************************
#*************************************************************************

proc newCylinder*(transformation : Transformation = newTransformation(), material : Material = newMaterial(); r, z_min, z_max : float; phi_max : float = 2 * PI): Cylinder =
  ## Constructor for a cylinder's later surface.
  result = Cylinder.new()
  result.transformation = transformation
  result.material = material
  result.r = r
  result.z_min = z_min
  result.z_max = z_max
  result.phi_max = phi_max
  result.bound_box = newAABoundungBox(newPoint(-r, -r, z_min), newPoint(r, r, z_max))

method rayIntersection(cylinder : Cylinder, ray : Ray): Option[HitRecord] =
  ## Checks if a ray intersects the cylinder's lateral surface
  ## Return a `HitRecord`, or `None` if no intersection was found.
  var
    inv_ray : Ray = ray.transform(cylinder.transformation.inverse())
    hit_point : Point
    t_hit : float
    phi : float
    t0, t1 : float
  #Check if ray intersects the Bounding Box
  if boxIntersection(cylinder.bound_box.pmin, cylinder.bound_box.pmax, inv_ray) == false :
    return none(HitRecord)
  #Calculate the intersection equation's coefficients
  let
    a : float = inv_ray.dir.x * inv_ray.dir.x + inv_ray.dir.y * inv_ray.dir.y
    b : float = 2 * (inv_ray.dir.x * inv_ray.origin.x + inv_ray.dir.y * inv_ray.origin.y)
    c : float = inv_ray.origin.x * inv_ray.origin.x + inv_ray.origin.y * inv_ray.origin.y - cylinder.r * cylinder.r
    delta : float = b * b - 4 * a * c
  #Check if there are solutions
  if delta < 0:
    return none(HitRecord)
  #Calculate the solutions
  t0 = (- b - sqrt(delta))/(2 * a)
  t1 = (- b + sqrt(delta))/(2 * a)
  if t0 > t1 : swap(t0, t1) #NON SONO SICURO
  #Check if t0 and t1 are in the correct [t_min, t_max] range
  if (t0 > inv_ray.tmax or t1 < inv_ray.tmin):
    return none(HitRecord)
  #Check which solution is the correct one
  t_hit = t0
  if t_hit < inv_ray.tmin :
    t_hit = t1
    if t_hit > inv_ray.tmax:
      return none(HitRecord)
  #Calculate the hit point and phi
  hit_point = inv_ray.at(t_hit)
  phi = arctan2(hit_point.y, hit_point.x)
  if phi < 0:
    phi = phi + 2 * PI
  #Check the boundaries conditions for z, and if they aren't safisfied try the other solution
  if (hit_point.z < cylinder.z_min or hit_point.z > cylinder.z_max or phi > cylinder.phi_max):
    if (t_hit == t1):
      return none(HitRecord)
    t_hit = t1
    if t_hit > inv_ray.tmax:
      return none(HitRecord)
    hit_point = inv_ray.at(t_hit)
    phi = arctan2(hit_point.y, hit_point.x)
    if phi < 0:
      phi = phi + 2 * PI
    if (hit_point.z < cylinder.z_min or hit_point.z > cylinder.z_max or phi > cylinder.phi_max):
      return none(HitRecord)
  #Return the HitRecord
  result = some(newHitRecord(world_point = cylinder.transformation * hit_point,
                            normal = VecToNormal(newVec(0.0, 0.0, 0.0)), #Temporaneo non ho ancora pensato a cosa usare
                            surface_point = newVec2d(phi / cylinder.phi_max, (hit_point.z - cylinder.z_min) / (cylinder.z_max - cylinder.z_min)),
                            t = t_hit,
                            ray = ray,
                            material = cylinder.material))