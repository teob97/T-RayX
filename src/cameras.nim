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
    
import geometry, transformation

type
  Ray* = object
    ## Ray object propagating form `origin` through the space in direction `dir`
    origin* : Point 
    dir* : Vec
    tmin* : float
    tmax* : float
    depth* : int
  Camera* = ref object of RootObj
    ## Abstract Camera object
  OrthogonalCamera* = ref object of Camera
    ## Orthogonal projection of the scene
    aspect_ratio* : float
    transformation* : Transformation
  PerspectiveCamera* = ref object of Camera
    ## Perespective projection of the scene
    distance* : float
    aspect_ratio* : float
    transformation* : Transformation

#*********************************** RAY ***********************************

proc newRay*(origin : Point, dir : Vec, tmin = 1e-5, tmax = Inf, depth = 0): Ray =
  ## Constructor of Ray
  result.origin = origin
  result.dir = dir
  result.tmin = tmin
  result.tmax = tmax
  result.depth = depth

proc areClose*(ray1, ray2 : Ray): bool = 
  ## Check if two rays are close
  return areClose(ray1.origin, ray2.origin) and areClose(ray1.dir, ray2.dir)

proc at*(ray : Ray, t : float): Point = 
  ## Return the position of a ray at a given "time" t
  return ray.origin + ray.dir * t

proc transform*(ray : Ray, t : Transformation) : Ray =
  ## Transform a ray
  result = newRay(origin = t*ray.origin, dir = t*ray.dir, tmin = ray.tmin, tmax = ray.tmax, depth = ray.depth)

proc `*`*(ray : Ray, transformation : Transformation): Ray =
  ## Overload the operator * to transform a Ray object using a Transformation
  result.origin = transformation * ray.origin
  result.dir = transformation * ray.dir
  result.tmin = ray.tmin
  result.tmax = ray.tmax
  result.depth = ray.depth

#*********************************** CAMERA ***********************************

proc newOrthogonalCamera*(aspect_ratio : float = 2.0, transformation = newTransformation()): OrthogonalCamera =
  ## Constructor of OrthogonalCamera
  var cam = OrthogonalCamera.new()
  cam.aspect_ratio = aspect_ratio
  cam.transformation = transformation
  return cam

proc newPerspectiveCamera*(distance, aspect_ratio : float; transformation = newTransformation()): PerspectiveCamera =
  ## Constructor of PerspectiveCamera
  var cam = PerspectiveCamera.new()
  cam.distance = distance
  cam.aspect_ratio = aspect_ratio
  cam.transformation = transformation
  return cam

method fireRay*(cam : Camera; u,v : float): Ray {.base.} =
  quit "to override"

method fireRay*(cam : OrthogonalCamera; u,v : float): Ray = 
  ## Send a new Ray in pixel (u,v)
  let origin = newPoint(-1.0, (1.0 - 2 * u) * cam.aspect_ratio, 2 * v - 1)
  let dir = VEC_X
  return newRay(origin = origin, dir = dir, tmin = 1.0) * cam.transformation

method fireRay*(cam : PerspectiveCamera; u,v : float): Ray =
  ## Send a new Ray in pixel (u,v)
  let origin = newPoint(-cam.distance, 0.0, 0.0)
  let dir = newVec(cam.distance, (1.0 - 2 * u) * cam.aspect_ratio, 2 * v - 1)
  return newRay(origin = origin, dir = dir, tmin=1.0) * cam.transformation

