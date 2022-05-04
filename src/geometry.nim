import std/math


#VECTOR OBJECT

type 
  Vec* = object
    x*, y*, z* : float

proc newVec*(x, y, z : float) : Vec =
  result.x = x
  result.y = y
  result.z = z

type
  Vec2d* = object
    u*, v* : float

proc areClose*(v1, v2 : Vec2d, epsilon : float = 1e-5) : bool =
  ## Check whether two Vec2d points are roughly the same or not
  return (abs(v1.u - v2.u) < epsilon) and (abs(v1.v - v2.v) < epsilon)

proc newVec2d*(u, v : float) : Vec2d =
  result.u = u
  result.v = v

# Useful constats
const VEC_X* : Vec = newVec(1.0, 0.0, 0.0)
const VEC_Y* : Vec = newVec(0.0, 1.0, 0.0)
const VEC_Z* : Vec = newVec(0.0, 0.0, 1.0)


#POINT OBJECT

type 
  Point* = object
    x*, y*, z* : float

proc newPoint*(x, y, z : float) : Point =
  result.x = x
  result.y = y
  result.z = z


#NORMAL OBJECT

type 
  Normal* = object
    x*, y*, z* : float

proc newNormal*(x, y, z : float) : Normal =
  result.x = x
  result.y = y
  result.z = z

#TEMPLATES

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

proc `<`*(p1, p2:Point):bool=
  return p1.x<p2.x and p1.y<p2.y and p1.z<p2.z

proc `>`*(p1, p2:Point):bool=
  return p1.x>p2.x and p1.y>p2.y and p1.z>p2.z