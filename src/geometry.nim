import std/math

###############
#VECTOR OBJECT#
###############

type 
  Vec* = object
    x*, y*, z* : float

##############
#POINT OBJECT#
##############

type 
  Point* = object
    x*, y*, z* : float

###############
#NORMAL OBJECT#
###############

type 
  Normal* = object
    x*, y*, z* : float

###########
#TEMPLATES#
###########

#Print the object in the format Obj.type(Obj.x, Obj.y, Obj.z)
template define_print_string(t: typedesc) = 
  proc print_string(arg : t) =
    echo $t & $arg

#Return a string in the format Obj.type(Obj.x, Obj.y, Obj.z)
template define_string_conversion(t: typedesc) = 
  proc `$`(arg : t): string =
    var buffer : string = $t & "(" & $arg.x & ", " & $arg.y & ", " & $arg.z & ")"
    return buffer

#Operation fname (+ or -) between object of different type
template define_3dop*(fname: untyped, type1: typedesc, type2: typedesc, rettype: typedesc) =
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

#Scalar product between Vector and/or Normal
template define_dot*(type1: typedesc, type2: typedesc) =
  proc `*`*(a: type1, b: type2): float =
    return a.x * b.x +  a.y * b.y +  a.z * b.z

define_dot(Vec, Vec)
define_dot(Vec, Normal)
define_dot(Normal, Vec)

#Squared norm of a Vector or a Normal
template define_squared_norm*(t: typedesc) =
  proc squared_norm*(a: t): float =
    return a.x * a.x +  a.y * a.y +  a.z * a.z

define_squared_norm(Vec)
define_squared_norm(Normal)

#Norm of a Vector or a Normal
template define_norm*(t: typedesc) =
  proc norm*(a: t): float =
    return sqrt(squared_norm(a))

define_norm(Vec)
define_norm(Normal)

#Modify the vector's norm so that it becomes equal to 1
template define_normalization*(t: typedesc) =
  proc normalization*(a: t) =
    a = a * (1/norm(a))

define_normalization(Vec)
define_normalization(Normal)

#Conversion from Vec to Normal
proc VecToNormal*(v: Vec) : Normal =
  normalization(v)
  result.x = v.x
  result.y = v.y
  result.z = v.z

#Conversion from Point to Vec
proc PointToVec*(p: Point) : Vec =
  result.x = p.x
  result.y = p.y
  result.z = p.z