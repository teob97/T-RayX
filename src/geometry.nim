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

import std/math

type 
  Vec* = object
    ## Vec object: (x, y, z) floats
    ## Represents a Vec in the 3D space
    x*, y*, z* : float
  Vec2d* = object
    ## Vec2d object: (u,v) floats
    ## ## Represents a Vec in the 2D space
    u*, v* : float
  Point* = object
    ## Point object: (x, y, z) floats
    ## Represents a Point in the 3D space
    x*, y*, z* : float
  Normal* = object
    ## Normal object: (x, y, z) floats
    ## Represents a Normal in the 3D space
    x*, y*, z* : float
  ONB* = object
    ## Ortho Normal Basis: (x, y, z) floats
    ## Represents an Orto Normal Basis in the 3D space
    e1*, e2*, e3* : Vec   

#*********************************** VEC ***********************************

proc newVec*(x, y, z : float) : Vec =
  ## Constructor of Vec
  result.x = x
  result.y = y
  result.z = z

proc areClose*(v1, v2 : Vec2d, epsilon : float = 1e-5) : bool =
  ## Check whether two Vec2d points are roughly the same or not
  return (abs(v1.u - v2.u) < epsilon) and (abs(v1.v - v2.v) < epsilon)

#*********************************** VEC2D ***********************************

proc newVec2d*(u, v : float) : Vec2d =
  ## Constructor for Vec2d
  result.u = u
  result.v = v

# Useful constats
const VEC_X* : Vec = newVec(1.0, 0.0, 0.0)
const VEC_Y* : Vec = newVec(0.0, 1.0, 0.0)
const VEC_Z* : Vec = newVec(0.0, 0.0, 1.0)


#*********************************** POINT ***********************************

proc newPoint*(x, y, z : float) : Point =
  ## Constructor of Point
  result.x = x
  result.y = y
  result.z = z

#*********************************** NORMAL ***********************************

proc newNormal*(x, y, z : float) : Normal =
  ## Constructor of Normal
  result.x = x
  result.y = y
  result.z = z

#********************************* OPERATIONS *********************************

template define_print_string(t: typedesc) = 
  ## Print the object in the format Obj.type(Obj.x, Obj.y, Obj.z)
  proc print_string*(arg : t) =
    echo $t & $arg

define_print_string(Vec)
define_print_string(Point)
define_print_string(Normal)

template define_string_conversion(t: typedesc) = 
  ## Return a string in the format Obj.type(Obj.x, Obj.y, Obj.z)
  proc `$`*(arg : t): string =
    var buffer : string = $t & "(" & $arg.x & ", " & $arg.y & ", " & $arg.z & ")"
    return buffer

define_string_conversion(Vec)
define_string_conversion(Point)
define_string_conversion(Normal)

template define_areClose(t: typedesc) =
  ## Compare two objects of the same type (Vec, Point, Normal) with a precision of e=1e-5
  proc areClose*(arg1, arg2 : t; e = 1e-5): bool =
    return abs(arg1.x-arg2.x)<e and abs(arg1.y-arg2.y)<e and abs(arg1.z-arg2.z)<e

define_areClose(Vec)
define_areClose(Point)
define_areClose(Normal) 

template define_product*(t: typedesc) =
  ## Product between a scalar and an object (Vec, Point, Normal)
  proc `*`*(arg1 : float, arg2 : t) : t =
    result.x = arg1 * arg2.x
    result.y = arg1 * arg2.y
    result.z = arg1 * arg2.z

  proc `*`*(arg2 : t, arg1 : float) : t =
    result.x = arg1 * arg2.x
    result.y = arg1 * arg2.y
    result.z = arg1 * arg2.z
    
define_product(Vec)
define_product(Point)
define_product(Normal)

template define_neg(t: typedesc) =
  ## Negation: return the reversed Vec or the reversed Normal
  proc `-`*(arg : t): t =
    result = -1.0 * arg 

define_neg(Vec)
define_neg(Normal)

template define_cross(t1, t2: typedesc) =
  ## Define a vector product between two objects
  proc cross*(arg1 : t1, arg2 : t2) : Vec =
    result.x = arg1.y*arg2.z - arg1.z*arg2.y
    result.y = arg1.z*arg2.x - arg1.x*arg2.z
    result.z = arg1.x*arg2.y - arg1.y*arg2.x

define_cross(Vec, Normal)
define_cross(Normal, Vec)
define_cross(Vec, Vec)
define_cross(Normal, Normal)

template define_3dop*(fname: untyped, type1: typedesc, type2: typedesc, rettype: typedesc) =
  ## Operation fname (+ or -) between object of different type
  proc fname*(a: type1, b: type2): rettype =
    result.x = fname(a.x, b.x)
    result.y = fname(a.y, b.y)
    result.z = fname(a.z, b.z)

define_3dop(`+`, Vec, Vec, Vec)
define_3dop(`-`, Vec, Vec, Vec)
define_3dop(`+`, Vec, Point, Point)
define_3dop(`+`, Point, Vec, Point)
define_3dop(`-`, Point, Vec, Point)
define_3dop(`+`, Normal, Normal, Normal)
define_3dop(`-`, Normal, Normal, Normal)
define_3dop(`-`, Point, Point, Vec)

template define_dot*(type1: typedesc, type2: typedesc) =
  ## Scalar product between Vector and/or Normal
  proc dot*(a: type1, b: type2): float =
    return a.x * b.x +  a.y * b.y +  a.z * b.z

define_dot(Vec, Vec)
define_dot(Vec, Normal)
define_dot(Normal, Vec)
define_dot(Normal, Normal)

template define_squared_norm*(t: typedesc) =
  ## Squared norm of a Vector or a Normal
  proc squared_norm*(a: t): float =
    return a.x * a.x +  a.y * a.y +  a.z * a.z

define_squared_norm(Vec)
define_squared_norm(Normal)

template define_norm*(t: typedesc) =
  ## Norm of a Vector or a Normal
  proc norm*(a: t): float =
    return sqrt(squared_norm(a))

define_norm(Vec)
define_norm(Normal)

template define_normalization*(t: typedesc) =
  ## Modify the vector's norm so that it becomes equal to 1
  proc normalization*(a: t) : t =
    result = (1/norm(a)) * a

define_normalization(Vec)
define_normalization(Normal)

proc VecToNormal*(v: Vec) : Normal =
  ## Conversion from Vec to Normal
  var v : Vec = normalization(v)
  result.x = v.x
  result.y = v.y
  result.z = v.z

proc PointToVec*(p: Point) : Vec =
  ## Conversion from Point to Vec
  result.x = p.x
  result.y = p.y
  result.z = p.z

proc normalToVec*(n : Normal) : Vec =
  result.x = n.x
  result.y = n.y
  result.z = n.z

template define_normalized_dot*(t1, t2 : typedesc) =
  ## Apply a dot product to the two arguments after having normalized them.
  ## The result is the cosine of the angle between the two vectors/normals.
  proc normalized_dot*(a : t1, b : t2): float =
    let
      v1 = a.normalization()
      v2 = b.normalization()
    result = v1.dot(v2)
  
define_normalized_dot(Vec, Vec)
define_normalized_dot(Normal, Normal)
define_normalized_dot(Vec, Normal)
define_normalized_dot(Normal, Vec)

#***************************** ORTHO-NORMAL BASUS *****************************

proc createONBfromZ*(normal : Normal) : ONB =
  ## Create a ONB from a z-axis rapresented by `normal`
  var buffer : Normal = normal
  if (squared_norm(buffer) != 1):     # check normalization using squared_normal because is faster
    buffer = normalization(normal)
  let
    sign = copySign(1.0, buffer.z)
    a = -1 / (sign + buffer.z)
    b = buffer.x * buffer.y * a
  result.e1.x = 1.0 + sign * buffer.x * buffer.x * a
  result.e1.y = sign * b
  result.e1.z = -sign * buffer.x
  result.e2.x = b
  result.e2.y = sign + buffer.y * buffer.y * a
  result.e2.z = -buffer.y
  result.e3.x = buffer.x
  result.e3.y = buffer.y 
  result.e3.z = buffer.z