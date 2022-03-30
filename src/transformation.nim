import std/math
import geometry

const IDENTITY_MATRIX4x4 = [1.0, 0.0, 0.0, 0.0,
                            0.0, 1.0, 0.0, 0.0,
                            0.0, 0.0, 1.0, 0.0,
                            0.0, 0.0, 0.0, 1.0]
#######################
#TRANSFORMATION OBJECT#
#######################

type 
  Transformation* = object
    m : array[16, float]
    invm : array[16, float]

#Constructor
proc newTransformation*(m=IDENTITY_MATRIX4x4, invm=IDENTITY_MATRIX4x4) : Transformation =
    result.m = m
    result.invm = invm

proc inverse*(matrix: Transformation) : Transformation =
    result.m = matrix.invm
    result.invm = matrix.m