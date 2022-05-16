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
import geometry

const IDENTITY_MATRIX4x4 = [1.0, 0.0, 0.0, 0.0,
                            0.0, 1.0, 0.0, 0.0,
                            0.0, 0.0, 1.0, 0.0,
                            0.0, 0.0, 0.0, 1.0]
type
  ## Affine transformation.
  Transformation* = object
    m* : array[16, float]
    invm* : array[16, float]

#*********************************** MATRIX OPERAIONS ***********************************

proc `[]`*(m: array[16, float]; x, y: int) : float =
  ## Overload [] operator: return the element at position (x,y).
  return m[4*x+y]

proc `*`*(m1, m2: array[16, float]) : array[16, float] =
  ## Product between two matrices
  for i in 0..<4:
    for j in 0..<4:
      for k in 0..<4:
        result[4*i+k] += m1[i,j]*m2[j,k]

proc areMatrClose*(m1, m2: array[16, float], epsilon : float = 1e-5) : bool =
  ## Check if two matrices are equal with a tolerance of "epsilon"
  for i in 0..<16:
    if (abs(m1[i]-m2[i]) > epsilon):
      return false
  return true
  
proc diffOfProduct*(m1, m2, m3, m4: float) : float =
  return m1*m2-m3*m4

#*********************************** TRANSFORMATION ***********************************

proc newTransformation*(m=IDENTITY_MATRIX4x4, invm=IDENTITY_MATRIX4x4) : Transformation =
  ## Constructor for Transormation object.
  result.m = m
  result.invm = invm

proc inverse*(T: Transformation) : Transformation =
  ## Return the inverse of a Transformation.
  result.m = T.invm
  result.invm = T.m

proc isConsistent*(T: Transformation) : bool =
  ## Check the internal consistency of the transformation.
  return areMatrClose(T.m*T.invm, IDENTITY_MATRIX4x4)

proc isClose*(T1: Transformation, T2: Transformation) : bool =
  ## Check if T2 represents the same transform.
  return areMatrClose(T1.m, T2.m) and areMatrClose(T1.invm, T2.invm)

#*********************************** OPERAIONS ***********************************

proc `*`*(T: Transformation, v: Vec) : Vec =
  ## Multiplication between a Transformation object and a Vec object.
  ## Return a Vec object
  return newVec(x = T.m[0]*v.x + T.m[1]*v.y + T.m[2]*v.z,
                y = T.m[4]*v.x + T.m[5]*v.y + T.m[6]*v.z,
                z = T.m[8]*v.x + T.m[9]*v.y + T.m[10]*v.z)

proc `*`*(T: Transformation, p: Point) : Point =
  ## Multiplication between a Transformation object and a Point object.
  ## Return a Point object
  var newp : Point = newPoint(x = T.m[0]*p.x + T.m[1]*p.y + T.m[2]*p.z + T.m[3],
                           y = T.m[4]*p.x + T.m[5]*p.y + T.m[6]*p.z + T.m[7],
                           z = T.m[8]*p.x + T.m[9]*p.y + T.m[10]*p.z + T.m[11])
  var w : float = T.m[12]*p.x + T.m[13]*p.y + T.m[14]*p.z + T.m[15]
  if w == 1.0:
    return newp
  else:
    return newPoint(newp.x/w, newp.y/w, newp.z/w)

proc `*`*(T: Transformation, n: Normal) : Normal =
  ## Multiplication between a Transformation object and a Normal object.
  ## Return a Normal object
  return newNormal(x = T.invm[0]*n.x + T.invm[4]*n.y + T.invm[8]*n.z,
                y = T.invm[1]*n.x + T.invm[5]*n.y + T.invm[9]*n.z,
                z = T.invm[2]*n.x + T.invm[6]*n.y + T.invm[10]*n.z)

proc `*`*(T1: Transformation, T2: Transformation) : Transformation =
  ## Multiplication between a Transformation object and a Transformation object.
  ## Return a Transformation object
  result.m = T1.m*T2.m
  result.invm = T2.invm*T1.invm

#*********************************** AFFINE TRANSFORMATIONS ***********************************

proc translation*(v: Vec) : Transformation =
  ## Return a `Transformation` object encoding a rigid translation.
  ## The parameter `vec` specifies the amount of shift to be applied along the three axes.
  result.m = [1.0, 0.0, 0.0, v.x,
              0.0, 1.0, 0.0, v.y,
              0.0, 0.0, 1.0, v.z,
              0.0, 0.0, 0.0, 1.0]
  result.invm = [1.0, 0.0, 0.0, -v.x,
                 0.0, 1.0, 0.0, -v.y,
                 0.0, 0.0, 1.0, -v.z,
                 0.0, 0.0, 0.0, 1.0]

proc scaling*(v: Vec) : Transformation =
  ## Return a `Transformation` object encoding a scaling.
  ## The parameter `vec` specifies the amount of scaling along the three directions X, Y, Z.
  result.m = [v.x, 0.0, 0.0, 0.0,
              0.0, v.y, 0.0, 0.0,
              0.0, 0.0, v.z, 0.0,
              0.0, 0.0, 0.0, 1.0]
  result.invm = [1.0/v.x, 0.0, 0.0, 0.0,
                 0.0, 1.0/v.y, 0.0, 0.0,
                 0.0, 0.0, 1.0/v.z, 0.0,
                 0.0, 0.0, 0.0, 1.0]

proc rotation_x*(angle_deg: float) : Transformation =
  ## Return a `Transformation` object encoding a rotation around the X axis.
  ## The parameter `angle_deg` specifies the rotation angle (in degrees).
  ## The positive sign is given by the right-hand rule.
  var sinang: float = sin(degToRad(angle_deg))
  var cosang: float = cos(degToRad(angle_deg))
  result.m = [1.0, 0.0, 0.0, 0.0,
              0.0, cosang, -sinang, 0.0,
              0.0, sinang, cosang, 0.0,
              0.0, 0.0, 0.0, 1.0]
  result.invm = [1.0, 0.0, 0.0, 0.0,
                 0.0, cosang, sinang, 0.0,
                 0.0, -sinang, cosang, 0.0,
                 0.0, 0.0, 0.0, 1.0]

proc rotation_y*(angle_deg: float) : Transformation =
  ## Return a `Transformation` object encoding a rotation around the Y axis.
  ## The parameter `angle_deg` specifies the rotation angle (in degrees).
  ## The positive sign is given by the right-hand rule.
  var sinang: float = sin(degToRad(angle_deg))
  var cosang: float = cos(degToRad(angle_deg))
  result.m = [cosang, 0.0, sinang, 0.0,
              0.0, 1.0, 0.0, 0.0,
              -sinang, 0.0, cosang, 0.0,
              0.0, 0.0, 0.0, 1.0]
  result.invm = [cosang, 0.0, -sinang, 0.0,
                 0.0, 1.0, 0.0, 0.0,
                 sinang, 0.0, cosang, 0.0,
                 0.0, 0.0, 0.0, 1.0]

proc rotation_z*(angle_deg: float) : Transformation =
  ## Return a `Transformation` object encoding a rotation around the Z axis.
  ## The parameter `angle_deg` specifies the rotation angle (in degrees).
  ## The positive sign is given by the right-hand rule.
  var sinang: float = sin(degToRad(angle_deg))
  var cosang: float = cos(degToRad(angle_deg))
  result.m = [cosang, -sinang, 0.0, 0.0,
              sinang, cosang, 0.0, 0.0,
              0.0, 0.0, 1.0, 0.0,
              0.0, 0.0, 0.0, 1.0]
  result.invm = [cosang, sinang, 0.0, 0.0,
                 -sinang, cosang, 0.0, 0.0,
                 0.0, 0.0, 1.0, 0.0,
                 0.0, 0.0, 0.0, 1.0]
