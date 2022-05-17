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
    ## A ray of light propagating in space
    ## The class contains the following members:
    ## - `origin` (``Point``): the 3D point where the ray originated
    ## - `dir` (``Vec``): the 3D direction along which this ray propagates
    ## - `tmin` (float): the minimum distance travelled by the ray is this number times `dir`
    ## - `tmax` (float): the maximum distance travelled by the ray is this number times `dir`
    ## - `depth` (int): number of times this ray was reflected/refracted
    origin* : Point 
    dir* : Vec
    tmin* : float
    tmax* : float
    depth* : int
  Camera* = ref object of RootObj
    ## An abstract class representing an observer
    ## Concrete subclasses are `OrthogographicCamera` and `PerspectiveCamera`.
  OrthogonalCamera* = ref object of Camera
    ## A camera implementing an orthogonal 3D → 2D projection
    ## This class implements an observer seeing the world through an orthogonal projection.
    aspect_ratio* : float
    transformation* : Transformation
  PerspectiveCamera* = ref object of Camera
    ## A camera implementing a perespective 3D → 2D projection
    ## This class implements an observer seeing the world through an perespective projection.
    distance* : float
    aspect_ratio* : float
    transformation* : Transformation

#*********************************** RAY ***********************************

proc newRay*(origin : Point, dir : Vec, tmin = 1e-5, tmax = Inf, depth = 0): Ray =
  ## Constructor of `Ray`.
  result.origin = origin
  result.dir = dir
  result.tmin = tmin
  result.tmax = tmax
  result.depth = depth

proc areClose*(ray1, ray2 : Ray): bool = 
  ## Check if two rays are similar enough to be considered equal
  return areClose(ray1.origin, ray2.origin) and areClose(ray1.dir, ray2.dir)

proc at*(ray : Ray, t : float): Point = 
  ## Compute the point along the ray's path at some distance from the origin.
  ## Return a ``Point`` object representing the point in 3D space whose distance from the
  ## ray's origin is equal to `t`, measured in units of the length of `Vec.dir`.
  return ray.origin + ray.dir * t

proc transform*(ray : Ray, t : Transformation) : Ray =
  ## Transform a ray.
  ## This method returns a new ray whose origin and direction are the transformation of the original ray.
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
  ## Create a new orthographic camera.
  ## The parameter `aspect_ratio` defines how larger than the height is the image. For fullscreen
  ## images, you should probably set `aspect_ratio` to 16/9, as this is the most used aspect ratio
  ## used in modern monitors.
  ## The `transformation` parameter is a `Transformation` object.
  var cam = OrthogonalCamera.new()
  cam.aspect_ratio = aspect_ratio
  cam.transformation = transformation
  return cam

proc newPerspectiveCamera*(distance, aspect_ratio : float; transformation = newTransformation()): PerspectiveCamera =
  ## Create a new perespective camera.
  ## The parameter `screen_distance` tells how much far from the eye of the observer is the screen,
  ## and it influences the so-called «aperture» (the field-of-view angle along the horizontal direction).
  ## The parameter `aspect_ratio` defines how larger than the height is the image. For fullscreen
  ## images, you should probably set `aspect_ratio` to 16/9, as this is the most used aspect ratio
  ## used in modern monitors.
  ## The `transformation` parameter is a `Transformation` object.
  var cam = PerspectiveCamera.new()
  cam.distance = distance
  cam.aspect_ratio = aspect_ratio
  cam.transformation = transformation
  return cam

method fireRay*(cam : Camera; u,v : float): Ray {.base.} =
  ## Fire a ray through the camera.
  ## This is an abstract method. You should redefine it in derived objects.
  ## Fire a ray that goes through the screen at the position (u, v). The exact meaning
  ## of these coordinates depend on the projection used by the camera.
  quit "to override"

method fireRay*(cam : OrthogonalCamera; u,v : float): Ray = 
  ## Shoot a ray through the camera's screen.
  ## The coordinates (u, v) specify the point on the screen where the ray crosses it.
  ## Coordinates (0, 0) represent the bottom-left corner, (0, 1) the top-left corner,
  ## (1, 0) the bottom-right corner, and (1, 1) the top-right corner, as in the following diagram:
  ##     (0, 1)                          (1, 1)
  ##        +------------------------------+
  ##        |                              |
  ##        |                              |
  ##        |                              |
  ##        +------------------------------+
  ##     (0, 0)                          (1, 0)
  let origin = newPoint(-1.0, (1.0 - 2 * u) * cam.aspect_ratio, 2 * v - 1)
  let dir = VEC_X
  return newRay(origin = origin, dir = dir, tmin = 1.0) * cam.transformation

method fireRay*(cam : PerspectiveCamera; u,v : float): Ray =
  ## Shoot a ray through the camera's screen.
  ## The coordinates (u, v) specify the point on the screen where the ray crosses it.
  ## Coordinates (0, 0) represent the bottom-left corner, (0, 1) the top-left corner,
  ## (1, 0) the bottom-right corner, and (1, 1) the top-right corner, as in the following diagram:
  ##     (0, 1)                          (1, 1)
  ##        +------------------------------+
  ##        |                              |
  ##        |                              |
  ##        |                              |
  ##        +------------------------------+
  ##     (0, 0)                          (1, 0)
  let origin = newPoint(-cam.distance, 0.0, 0.0)
  let dir = newVec(cam.distance, (1.0 - 2 * u) * cam.aspect_ratio, 2 * v - 1)
  return newRay(origin = origin, dir = dir, tmin=1.0) * cam.transformation

