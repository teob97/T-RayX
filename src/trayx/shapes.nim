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
    
import basictypes, geometry, cameras, transformation, materials
import std/[math, options]

type
  HitRecord* = ref object
    ## An object holding information about a ray-shape intersection
    ## The parameters defined in this dataclass are the following:
    ## - `world_point`: a `Point` object holding the world coordinates of the hit point
    ## - `normal`: a `Normal` object holding the orientation of the normal to the surface where the hit happened
    ## - `surface_point`: a `Vec2d` object holding the position of the hit point on the surface of the object
    ## - `t`: a floating-point value specifying the distance from the origin of the ray where the hit happened
    ## - `ray`: the ray that hit the surface
    world_point* : Point
    normal* : Normal
    surface_point* : Vec2d
    t* : float
    ray* : Ray
    material* : Material
  AABoundingBox* = ref object
    ## An axis alligned bounding box defined by two vertices in the 3D space.
    pmin* : Point
    pmax* : Point
  Shape* = ref object of RootObj
    ## A generic 3D shape
    ## This is an abstract class, and you should only use it to derive
    ## concrete classes. Be sure to redefine the method `.Shape.rayIntersection`.
    transformation* : Transformation
    material* : Material
    bound_box* : AABoundingBox
  Sphere* = ref object of Shape
    ## A 3D unit sphere centered on the origin of the axes.
  AABox * = ref object of Shape
    ## An axis alligned box defined by two vertices in the 3D space.
    pmin* : Point
    pmax* : Point
  Plane* = ref object of Shape
    ## A 3D infinite plane parallel to the x and y axis and passing through the origin.
  Cylinder* = ref object of Shape
    ## A 3D cylinder lateral surface alligned with z axis.
    r* : float
    z_min* : float
    z_max* : float
    phi_max* : float
  PointLight* = object
    ## A point light (used by the point-light render). 
    ## It represents a Dirac's delta in the rendering equation.
    ## If `linear_radius` is non-zero, it is used to compute the solid angle subtended by 
    ## the light at a given distance `d` through the formula `(linear_radius/d)^2`
    position* : Point
    color* : Color
    linear_radius* : float
  World* = object
    ## A class holding a list of shapes, which make a «world»
    ## You can add shapes to a world using :meth:`.World.add`. Typically, you call
    ## :meth:`.World.rayIntersection` to check whether a light ray intersects any
    ## of the shapes in the world.
    shapes* : seq[Shape]
    point_lights* : seq[PointLight]

proc eq_2deg_solver*(a,b,c : float): array[2, float] =
  ## More stable way to compute the solution of a 2nd degree equation: a*x^2 + b*x + c = 0
  var 
    delta : float = b*b - 4 * a * c
    q : float  
  if b < 0:
    q = - 0.5 * (b - sqrt(delta))
  else:
    q = - 0.5 * (b + sqrt(delta))
  result[0] = min(q/a, c/q)
  result[1] = max(q/a, c/q)


#*********************************** HITRECORD ***********************************

proc newHitRecord*(world_point : Point, normal : Normal, surface_point : Vec2d, t : float, ray : Ray, material : Material = newMaterial()) : HitRecord =
  ## Constructor of HitRecord
  result = HitRecord.new()
  result.world_point = world_point
  result.normal = normal
  result.surface_point = surface_point
  result.t = t
  result.ray = ray
  result.material = material

proc areClose*(h1, h2: HitRecord, epsilon : float = 1e-5) : bool =
  ## Check whether two `HitRecord` represent the same hit event or not
  return areClose(h1.world_point, h2.world_point) and
         areClose(h1.normal, h2.normal) and 
         areClose(h1.surface_point, h2.surface_point) and 
         abs(h1.t - h2.t) < epsilon and 
         areClose(h1.ray, h2.ray)

#*********************************** WORLD ***********************************

proc newWorld*(shapes : seq[Shape] = newSeq[Shape](0), point_lights : seq[PointLight] = newSeq[PointLight](0)) : World =
  result.shapes = shapes
  result.point_lights = point_lights

method rayIntersection*(shape : Shape, ray : Ray): Option[HitRecord] {.base.} =
  quit "to override"

proc rayIntersection*(world : World, ray : Ray): Option[HitRecord] =
  ## Iterate over the entire list of shapes and check if there are any intersection with ray.
  var closest : Option[HitRecord] = none(HitRecord)
  for shape in world.shapes:
    var intersection = shape.rayIntersection(ray)
    if intersection.isNone:
      continue
    if closest.isNone or intersection.get().t < closest.get().t:
      closest = intersection
  return closest

method quickRayIntersection*(shape : Shape, ray : Ray): bool {.base.} =
  ## Abstract method. Determine wheter a ray hits the shape or not.
  ## Used in point-light tracer
  quit "to override"
  
proc is_point_visible*(world : World, point : Point, observer_pos : Point): bool =
  let
    direction : Vec = point - observer_pos
    dir_norm : float = direction.norm()
    ray : Ray = newRay(origin = observer_pos, dir = direction, tmin = 1e-2 / dir_norm, tmax = 1.0, depth = 0)
  for shapes in world.shapes:
    if shapes.quickRayIntersection(ray):
      return false
  return true

#*************************************** Point Light *******************************************

proc newPointLight*(position : Point, color : Color, linear_radius : float = 0.0): PointLight =
  result.position = position
  result.color = color
  result.linear_radius = linear_radius

#***********************************************************************************************
#******************************** AXIS-ALIGNED-(BOUNDING)-BOXES ********************************
#***********************************************************************************************

proc newAABox*(pmin : Point = newPoint(0, 0, 0), pmax : Point = newPoint(1, 1, 1), transformation : Transformation = newTransformation(), material : Material = newMaterial()) : AABox =
  ## Constructor of an Axis Aligned Box with min vertex in pmin and max vertex in pmax
  result = AABox.new()
  result.pmin = pmin
  result.pmax = pmax
  result.transformation = transformation
  result.material = material

proc newAABoundungBox(pmin, pmax : Point): AABoundingBox =
  ## Constructor of an Axis Aligned Bounding Box with min vertex in pmin and max vertex in pmax.
  result = AABoundingBox.new()
  result.pmin = pmin
  result.pmax = pmax

proc AABoxPointToUV*(point: Point) : Vec2d =
  ## Convert a 3D point on the surface of the cube with p_min(0,0,0) and p_max(1,1,1)
  ## into a (u, v) 2D point.
  # face (0, y, z) [0]
  if point.x == 0:
    result = newVec2d((1 + point.y) / 4, (1 + point.z) / 3)
  # face (x, 1, z) [1]
  elif point.y == 1:
    result = newVec2d((1 - point.x) / 4, (1 + point.z) / 3)
  # face (x, 0, z) [4]
  elif point.y == 0:
    result = newVec2d((2 + point.x) / 4, (1 + point.z) / 3)
  # face (1, y, z) [5]
  elif point.x == 1:
    result = newVec2d((3 + point.x) / 4, (1 + point.z) / 3)
  # face (x, y, 0) [3] 
  elif point.z == 0:
    result = newVec2d((1 + point.y) / 4, (1 - point.x) / 3)
  # face (x, y, 1) [2] 
  elif point.z == 1:
    result = newVec2d((1 + point.y) / 4, (2 + point.x) / 3)

proc checkIntersection(tx_min, tx_max, ty_min, ty_max, tz_min, tz_max: float): Option[float] =
  ## Check if the intersection is "real".
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
  ## Check if there is an intersection with the boundary box.
  ## Return true o false.
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
  ## Check in which face of the cube there is the intersection and calculate the normal knowing pmin and pmax.
  ## Default : pmin = (0,0,0) ; pmax = (1,1,1)
  if hit_point.x == box.pmin.x: # if hit_point.x == 0
    result = newNormal(-1, 0, 0)
  elif hit_point.y == box.pmin.y:
    # xz face
    result = newNormal(0, -1, 0)
  elif hit_point.z == box.pmin.z:
    # xy face
    result = newNormal(0,0,-1)
  elif hit_point.x == box.pmax.x:
    result = newNormal(1,0,0)
  elif hit_point.y == box.pmax.y:
    result = newNormal(0,1,0)
  elif hit_point.z == box.pmax.z:
    result = newNormal(0,0,1)
  if PointToVec(hit_point).dot(ray.dir) <= 0:
    result = - result


method rayIntersection*(box : AABox, ray : Ray) : Option[HitRecord] =
  ## Checks if a ray intersects the AAB
  ## Return a `HitRecord`, or `None` if no intersection was found.  
  var
    inv_ray : Ray = ray.transform(box.transformation.inverse())
    origin_vec : Vec = PointToVec(inv_ray.origin)
    tx_min : float = (box.pmin.x - origin_vec.x) / inv_ray.dir.x
    ty_min : float = (box.pmin.y - origin_vec.y) / inv_ray.dir.y
    tz_min : float = (box.pmin.z - origin_vec.z) / inv_ray.dir.z
    tx_max : float = (box.pmax.x - origin_vec.x) / inv_ray.dir.x
    ty_max : float = (box.pmax.y - origin_vec.y) / inv_ray.dir.y
    tz_max : float = (box.pmax.z - origin_vec.z) / inv_ray.dir.z
    t_hit : float
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
  result = some(newHitRecord(world_point = box.transformation * hit_point,
                      normal = box.transformation * box.boxNormal(hit_point, inv_ray),
                      surface_point = AABoxPointToUV(hit_point),
                      t = t_hit,
                      ray = ray,
                      material = box.material))



#******************************************************************************
#*********************************** SPHERE ***********************************
#******************************************************************************

proc newSphere*(transformation : Transformation = newTransformation(), material : Material = newMaterial()) : Sphere =
  ## Create a shape, potentially associating a transformation to it.
  result = Sphere.new()
  result.transformation = transformation
  result.material = material
  result.bound_box = newAABoundungBox(newPoint(-1, -1, -1), newPoint(1, 1, 1))

proc spherePointToUV*(point: Point) : Vec2d =
  ## Convert a 3D point on the surface of the unit sphere into a (u, v) 2D point.
  var u : float = arctan2(point.y, point.x) / (2.0 * PI)
  if u >= 0:
    result.u = u
  else:
    result.u = u + 1.0
  result.v = arccos(point.z) / PI

proc sphereNormal*(point: Point, ray_dir: Vec) : Normal =
  ## Compute the normal of a unit sphere.
  ## The normal is computed for `point` (a point on the surface of the sphere),
  ## and it is chosen so that it is always in the opposite direction with respect to `ray_dir`.
  if (PointtoVec(point).dot(ray_dir) < 0.0):
    result = newNormal(point.x, point.y, point.z)
  else:
    result = -newNormal(point.x, point.y, point.z)

method rayIntersection*(sphere : Sphere, ray : Ray): Option[HitRecord] =
  ## Checks if a ray intersects the sphere.
  ## Return a `HitRecord`, or `None` if no intersection was found.
  #Check if ray intersects the Bounding Box
  let 
    inv_ray : Ray = ray.transform(sphere.transformation.inverse())
    origin_vec = PointToVec(inv_ray.origin)
  if boxIntersection(sphere.bound_box.pmin, sphere.bound_box.pmax, inv_ray) == false :
    return none(HitRecord)
  let
    a : float = inv_ray.dir.squared_norm()
    b : float = 2.0 * origin_vec.dot(inv_ray.dir)
    c : float = origin_vec.squared_norm() - 1.0
    delta : float = b * b - 4.0 * a * c
  if delta <= 0:
    return none(HitRecord)
  var
    first_hit_t : float
  let 
    t = eq_2deg_solver(a, b, c)
    tmin : float = t[0]
    tmax : float = t[1]
  if (tmin > inv_ray.tmin) and (tmin < inv_ray.tmax):
    first_hit_t = tmin
  elif (tmax > inv_ray.tmin) and (tmax < inv_ray.tmax):
    first_hit_t = tmax
  else:
    return none(HitRecord)
  let hit_point : Point = inv_ray.at(first_hit_t)
  result = some(newHitRecord(world_point = sphere.transformation * hit_point,
                      normal = sphere.transformation * sphereNormal(hit_point, inv_ray.dir),
                      surface_point = spherePointToUV(hit_point),
                      t = first_hit_t,
                      ray = ray,
                      material = sphere.material))


#*****************************************************************************
#*********************************** PLANE ***********************************
#*****************************************************************************

proc newPlane*(transformation : Transformation = newTransformation(), material : Material = newMaterial()) : Plane =
  ## Create a xy plane, potentially associating a transformation to it.
  result = Plane.new()
  result.transformation = transformation
  result.material = material

method rayIntersection*(plane : Plane, ray : Ray): Option[HitRecord] =
  ## Checks if a ray intersects the plane.
  ## Return a `HitRecord`, or `None` if no intersection was found.
  let
    inv_ray : Ray = ray.transform(plane.transformation.inverse())
  if abs(inv_ray.dir.z) < 1e-5:
    return none(HitRecord)
  let t = - inv_ray.origin.z / inv_ray.dir.z
  if (t <= inv_ray.tmin) or (t >= inv_ray.tmax):
    return none(HitRecord)
  else:
    var normal : Normal
    if inv_ray.dir.z < 0.0:
      normal = newNormal(0.0, 0.0, 1.0)
    else:
      normal = newNormal(0.0, 0.0, -1.0)
    result = some(newHitRecord(world_point = plane.transformation * inv_ray.at(t),
                               normal = plane.transformation * normal,
                               surface_point = newVec2d(inv_ray.at(t).x - floor(inv_ray.at(t).x), inv_ray.at(t).y - floor(inv_ray.at(t).y)),
                               t = t,
                               ray = ray,
                               material = plane.material))

#*************************************************************************
#**************************** CYLINDER ***********************************
#*************************************************************************

proc newCylinder*(transformation : Transformation = newTransformation(), material : Material = newMaterial(); 
                  r : float = 1, z_min : float = 0, z_max : float = 1; phi_max : float = 2 * PI): Cylinder =
  ## Constructor for a cylinder's later surface.
  result = Cylinder.new()
  result.transformation = transformation
  result.material = material
  result.r = r
  result.z_min = z_min
  result.z_max = z_max
  result.phi_max = phi_max
  result.bound_box = newAABoundungBox(newPoint(-r, -r, z_min), newPoint(r, r, z_max))

method rayIntersection*(cylinder : Cylinder, ray : Ray): Option[HitRecord] =
  ## Checks if a ray intersects the cylinder's lateral surface.
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
  let t = eq_2deg_solver(a, b, c)
  t0 = t[0] 
  t1 = t[1]
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
                            normal =  cylinder.transformation * VecToNormal(newVec(hit_point.x, hit_point.y, 0.0)),
                            surface_point = newVec2d(phi / cylinder.phi_max, (hit_point.z - cylinder.z_min) / (cylinder.z_max - cylinder.z_min)),
                            t = t_hit,
                            ray = ray,
                            material = cylinder.material))

#***********************************************************************************
#**************************** Quick rayIntersection ********************************
#***********************************************************************************
  
method quickRayIntersection*(sphere : Sphere, ray : Ray): bool =
  let 
    inv_ray : Ray = ray.transform(sphere.transformation.inverse())
    origin_vec = PointToVec(inv_ray.origin)
    a : float = inv_ray.dir.squared_norm()
    b : float = 2.0 * origin_vec.dot(inv_ray.dir)
    c : float = origin_vec.squared_norm() - 1.0
    delta : float = b * b - 4.0 * a * c
  if delta <= 0:
    return false
  let
    sqrt_delta : float = sqrt(delta)
    tmin : float = (-b - sqrt_delta) / (2.0 * a)
    tmax : float = (-b + sqrt_delta) / (2.0 * a)
  if (tmin > inv_ray.tmin) and (tmin < inv_ray.tmax):
    return true
  elif (tmax > inv_ray.tmin) and (tmax < inv_ray.tmax):
    return true
  else:
    return false

method quickRayIntersection*(plane : Plane, ray : Ray): bool =
  let
    inv_ray = ray.transform(plane.transformation.inverse())
  if abs(inv_ray.dir.z) < 1e-5:
    return false
  let t = - inv_ray.origin.z / inv_ray.dir.z
  return (t > inv_ray.tmin and t < inv_ray.tmax)

method quickRayIntersection*(cylinder : Cylinder, ray : Ray): bool =
  var
    inv_ray : Ray = ray.transform(cylinder.transformation.inverse())
    hit_point : Point
    t_hit : float
    phi : float
    t0, t1 : float
  #Calculate the intersection equation's coefficients
  let
    a : float = inv_ray.dir.x * inv_ray.dir.x + inv_ray.dir.y * inv_ray.dir.y
    b : float = 2 * (inv_ray.dir.x * inv_ray.origin.x + inv_ray.dir.y * inv_ray.origin.y)
    c : float = inv_ray.origin.x * inv_ray.origin.x + inv_ray.origin.y * inv_ray.origin.y - cylinder.r * cylinder.r
    delta : float = b * b - 4 * a * c
  #Check if there are solutions
  if delta < 0:
    return false
  let t = eq_2deg_solver(a, b, c)
  t0 = t[0] 
  t1 = t[1]
  #Check if t0 and t1 are in the correct [t_min, t_max] range
  if (t0 > inv_ray.tmax or t1 < inv_ray.tmin):
    return false
  #Check which solution is the correct one
  t_hit = t0
  if t_hit < inv_ray.tmin :
    t_hit = t1
    if t_hit > inv_ray.tmax:
      return false
  #Calculate the hit point and phi
  hit_point = inv_ray.at(t_hit)
  phi = arctan2(hit_point.y, hit_point.x)
  if phi < 0:
    phi = phi + 2 * PI
  #Check the boundaries conditions for z, and if they aren't safisfied try the other solution
  if (hit_point.z < cylinder.z_min or hit_point.z > cylinder.z_max or phi > cylinder.phi_max):
    if (t_hit == t1):
      return false
    t_hit = t1
    if t_hit > inv_ray.tmax:
      return false
    hit_point = inv_ray.at(t_hit)
    phi = arctan2(hit_point.y, hit_point.x)
    if phi < 0:
      phi = phi + 2 * PI
    if (hit_point.z < cylinder.z_min or hit_point.z > cylinder.z_max or phi > cylinder.phi_max):
      return false
  return true

method quickRayIntersection*(box : AABox, ray : Ray): bool =
  ## Checks if a ray intersects the AAB (only used in PointLight Tracer)
  ## Return a true, or flase if no intersection was found.  
  var
    inv_ray : Ray = ray.transform(box.transformation.inverse())
    origin_vec : Vec = PointToVec(inv_ray.origin)
    tx_min : float64 = (box.pmin.x - origin_vec.x) / inv_ray.dir.x
    ty_min : float64 = (box.pmin.y - origin_vec.y) / inv_ray.dir.y
    tz_min : float64 = (box.pmin.z - origin_vec.z) / inv_ray.dir.z
    tx_max : float64 = (box.pmax.x - origin_vec.x) / inv_ray.dir.x
    ty_max : float64 = (box.pmax.y - origin_vec.y) / inv_ray.dir.y
    tz_max : float64 = (box.pmax.z - origin_vec.z) / inv_ray.dir.z
    t_hit : float64
  if tx_min > tx_max: swap(tx_min, tx_max)
  if ty_min > ty_max: swap(ty_min, ty_max)
  if tz_min > tz_max: swap(tz_min, tz_max)
  if checkIntersection(tx_min, tx_max, ty_min, ty_max, tz_min, tz_max).isNone:
    return false
  else:
    t_hit = get(checkIntersection(tx_min, tx_max, ty_min, ty_max, tz_min, tz_max))
  if (t_hit <= inv_ray.tmin) or (t_hit >= inv_ray.tmax):
    return false
  return true
  
