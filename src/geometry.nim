###############
#VECTOR OBJECT#
###############

type 
  Vec* = object
    x*, y*, z* : float

proc newVec*(x, y, z : float) : Vec =
  result.x = x
  result.y = y
  result.z = z

##############
#POINT OBJECT#
##############

type 
  Point* = object
    x*, y*, z* : float

proc newPoint*(x, y, z : float) : Point =
  result.x = x
  result.y = y
  result.z = z

###############
#NORMAL OBJECT#
###############

type 
  Normal* = object
    x*, y*, z* : float

proc newNormal*(x, y, z : float) : Normal =
  result.x = x
  result.y = y
  result.z = z

###########
#TEMPLATES#
###########

#Print the object in the format Obj.type(Obj.x, Obj.y, Obj.z)
template define_print_string(t: typedesc) = 
  proc print_string*(arg : t) =
    echo $t & $arg

define_print_string(Vec)
define_print_string(Point)
define_print_string(Normal)

#Return a string in the format Obj.type(Obj.x, Obj.y, Obj.z)
template define_string_conversion(t: typedesc) = 
  proc `$`*(arg : t): string =
    var buffer : string = $t & "(" & $arg.x & ", " & $arg.y & ", " & $arg.z & ")"
    return buffer

define_string_conversion(Vec)
define_string_conversion(Point)
define_string_conversion(Normal)

#Compare the object with a precision of e=1e-5
template define_are_close(t: typedesc) =
  proc are_close*(arg1, arg2 : t; e = 1e-5): bool =
    return abs(arg1.x-arg2.x)<e and abs(arg1.y-arg2.y)<e and abs(arg1.z-arg2.z)<e

define_are_close(Vec)
define_are_close(Point)
define_are_close(Normal) 

#Product between a scalar and an object
template define_product(t: typedesc) =
  proc `*`*(arg1 : float, arg2 : t) : t =
    result.x = arg1 * arg2.x
    result.y = arg1 * arg2.y
    result.z = arg1 * arg2.z

define_product(Vec)
define_product(Point)
define_product(Normal)

#Negation: return the reversed vector
template define_neg(t: typedesc) =
  proc neg*(arg : t): t =
    result = -1.0 * arg 

define_neg(Vec)
define_neg(Normal)

#Define a vector product between two objects
template define_cross(t1, t2: typedesc) =
  proc cross*(arg1 : t1, arg2 : t2) : Vec =
    result.x = arg1.y*arg2.z - arg1.z*arg2.y
    result.y = arg1.z*arg2.x - arg1.x*arg2.z
    result.z = arg1.x*arg2.y - arg1.y*arg2.x

define_cross(Vec, Normal)
define_cross(Normal, Vec)
define_cross(Vec, Vec)
define_cross(Normal, Normal)