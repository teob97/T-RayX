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
