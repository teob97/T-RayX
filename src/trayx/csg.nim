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

import shapes, transformation, cameras, geometry
import std/options
type
  CsgUnion* = ref object of Shape
    firstShape* : Shape
    secondShape* : Shape
  CsgDifference* = ref object of Shape
    firstShape* : Shape
    secondShape* : Shape

#*********************************** UNION ***********************************

proc newCsgUnion*(shape1, shape2 : Shape; transformation : Transformation = newTransformation()) : CsgUnion =
  ## Create a CsgUnion object
  result = CsgUnion.new()
  result.firstShape = shape1
  result.secondShape = shape2
  result.transformation = transformation

method rayIntersection*(csgUnion : CsgUnion, ray : Ray) : Option[HitRecord] =
  ## Checks if a ray intersects the CsgUnion.
  ## Return a `HitRecord`, or `None` if no intersection was found.
  var 
    inv_ray : Ray = ray.transform(csgUnion.transformation.inverse())
    hit1 : Option[HitRecord] = csgUnion.firstShape.rayIntersection(inv_ray)
    hit2 : Option[HitRecord] = csgUnion.secondShape.rayIntersection(inv_ray)
  # Return the first hitting point
  if hit1 == none(HitRecord) and hit2 == none(HitRecord):
    return none(HitRecord)
  elif hit1 == none(HitRecord):
    return hit2
  elif hit2 == none(HitRecord):
    return hit1
  elif hit1.get().t < hit2.get().t:
    return hit1
  else:
    return hit2

method rayIntersection*(csgUnion : CsgDifference, ray : Ray) : Option[HitRecord] =
  ## Checks if a ray intersects the CsgDifference.
  ## Return a `HitRecord`, or `None` if no intersection was found.
  var 
    inv_ray : Ray = ray.transform(csgUnion.transformation.inverse())
    hit1 : Option[HitRecord] = csgUnion.firstShape.rayIntersection(inv_ray)
    hit2 : Option[HitRecord] = csgUnion.secondShape.rayIntersection(inv_ray)
  # Return the first hitting point
  if hit1 == none(HitRecord) and hit2 == none(HitRecord):
    return none(HitRecord)
  elif hit1 == none(HitRecord):
    return hit2
  elif hit2 == none(HitRecord):
    return hit1
  elif hit1.get().t < hit2.get().t:
    return hit1
  else:
    return hit2

#*********************************** UNION ***********************************
