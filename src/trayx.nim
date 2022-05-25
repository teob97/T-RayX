#[  
  T-RayX: a Nim ray tracing library
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
  along with this program.  If not, see <https://www.gnu.org/licenses/>. 
]#
    
import basictypes, pfm, ldr, cameras, imagetracer, shapes, transformation, geometry, materials, renderer
import docopt
import std/[strutils, strformat, streams, os, times]
when compileOption("profiler"):
  import nimprof

let doc = """
T-RayX: a Nim Raytracing Library

Usage:
  ./trayx pfm2png <INPUT_FILE.pfm> <alpha> <gamma> <OUTPUT.png>
  ./trayx demo [--angle=<angle-deg>] [--output=<output-file>] [--orthogonal]
  ./trayx debug

Options:
  -h --help                 Show this screen
  --version                 Show version
  --angle=<angle-deg>       Angle in degree
  --orthogonal              Camera type. Default = perspective
  --output=<output-file>    Output file.png
"""

let args = docopt(doc, version = "0.1.0" )

#*********************************** PFM2PNG ***********************************

type
  Parameters* = object
      input_pfm_file_name : string
      factor : float
      gamma : float
      output_png_file_name : string

# Read parameters form command line
proc parseCommandLine*(param : var Parameters) =
  var args = commandLineParams()
  if len(args) != 5:
    raise newException(IOError, "Usage: main.nim INPUT_PFM_FILE FACTOR GAMMA OUTPUT_PNG_FILE")
  param.input_pfm_file_name = args[1]
  try:
    param.factor = args[2].parseFloat
  except ValueError:
    raise newException(IOError, fmt"Invalid factor ('{args[2]}'), it must be a floating-point number.")
  try:
    param.gamma = args[3].parseFloat
  except ValueError:
    raise newException(IOError, fmt"Invalid factor ('{args[3]}'), it must be a floating-point number.")
  param.output_png_file_name = args[4]

proc pfm2png() =
  ## Main procedure to convert a .pfm file into a .png file
  var param : Parameters
  try:
    parseCommandLine(param):
  except IOError:
    echo ("Error: wrong parameters. See --help.")
    return
  var impf = openFileStream(param.input_pfm_file_name)
  var img : HdrImage = readPfmImage(impf)
  impf.close()
  echo (fmt"File {param.input_pfm_file_name} has been read from disk.")
  img.normalize_image(factor=param.factor)
  img.clamp_image()
  var outf = newFileStream(param.output_png_file_name, fmWrite)
  img.write_ldr_image(name=param.output_png_file_name, gamma=param.gamma)
  outf.close()
  echo (fmt"File {param.output_png_file_name} has been written to disk.")

#*********************************** DEMO ***********************************

proc demo() =
  # Demo procedure that generates 10 spheres,  a cube and a checkered plane
  var 
    tracer : ImageTracer
    translation : Transformation = translation(newVec(-1.0, 0.0, 1.0))
    world : World
    strm = newFileStream("output/demo.pfm", fmWrite)
  const
    width  : int = 960
    height : int = 540
    ratio = width/height
  if args["--orthogonal"]:
    if args["--angle"]:
      tracer = newImageTracer(newHdrImage(width, height), newOrthogonalCamera(ratio, rotation_z(-parseFloat($args["--angle"]))*translation))
    else:
      tracer = newImageTracer(newHdrImage(width, height), newOrthogonalCamera(ratio, translation))
  else:   
    if args["--angle"]:
      tracer = newImageTracer(newHdrImage(width, height), newPerspectiveCamera(1, ratio, rotation_z(-parseFloat($args["--angle"]))*translation))
    else:
      tracer = newImageTracer(newHdrImage(width, height), newPerspectiveCamera(1, ratio, translation)) 
  let
    sky_material = newMaterial(brdf = newDiffuseBRDF(newUniformPigment(newColor(0, 0, 0))), emitted_radiance = newUniformPigment(newColor(1.0, 0.9, 0.5)))
    ground_material = newMaterial(brdf = newDiffuseBRDF(pigment = newCheckeredPigment(color1 = newColor(0.3, 0.5, 0.1), color2 = newColor(0.1, 0.2, 0.5))))
    sphere_material = newMaterial(brdf = newDiffuseBRDF(pigment = newUniformPigment(newColor(0.3, 0.4, 0.8))))
    mirror_material = newMaterial(brdf = newSpecularBRDF(pigment = newUniformPigment(color = newColor(0.6, 0.2, 0.3))))
  # Add all the shapes in world
  world.shapes.add(newSphere(material=sky_material, transformation=scaling(newVec(200, 200, 200)) * translation(newVec(0, 0, 0.4))))
  world.shapes.add(newPlane(material=ground_material))
  world.shapes.add(newSphere(material=sphere_material, transformation=translation(newVec(0, 0, 1))))
  world.shapes.add(newSphere(material=mirror_material, transformation=translation(newVec(1, 2.5, 0))))
  #Initiallize the render (future feature : choose from terminal the renderer's types)
  let renderer = newPathTracer(world)
  tracer.fireAllRays(renderer)
  tracer.image.writePfmImage(strm)
  if args["--output"]:
    tracer.image.writeLdrImage($args["--output"])
  else:
    tracer.image.writeLdrImage("demo.png")

#*************************************DEBUG*************************************************

proc debug() =
  var
    tracer : ImageTracer = newImageTracer(newHdrImage(640, 480), newPerspectiveCamera(1, 640/480, translation(newVec(-1,0,1))))
    strm = newFileStream("output/test.pfm", fmWrite)
    material = newMaterial(newSpecularBRDF())
    check_material = newMaterial(brdf = newDiffuseBRDF(pigment = newCheckeredPigment(color1 = newColor(0.2, 0.2, 0.8), color2 = newColor(0.8, 0.6, 0.2))))
    sky_material = newMaterial(brdf = newDiffuseBRDF(newUniformPigment(newColor(0, 0, 0))), emitted_radiance = newUniformPigment(newColor(1.0, 0.9, 0.5)))
    mirror_material = newMaterial(brdf = newSpecularBRDF(pigment = newUniformPigment(color = newColor(0.6, 0.2, 0.3))))
    ground_material = newMaterial(brdf = newDiffuseBRDF(pigment = newCheckeredPigment(color1 = newColor(0.3, 0.5, 0.1), color2 = newColor(0.1, 0.2, 0.5))))
    sphere_material = newMaterial(brdf = newDiffuseBRDF(pigment = newUniformPigment(newColor(0.3, 0.4, 0.8))))

    s1 = newSphere(translation(newVec(0, 0.5, 0)), material)
    plane = newPlane(translation(newVec(0.0, 0.0, -1.5)), sky_material)
    world : World
#[ 
  # diffusive sky
  world.shapes.add(newSphere(material=sky_material, transformation=scaling(newVec(200, 200, 200)) * translation(newVec(0, 0, 0.4))))
  # checkered ground
  world.shapes.add(newPlane(material=ground_material))
  # checkered cube
#[   world.shapes.add(newAABox(transformation = translation(newVec(-0.5, 1, 0))*scaling(newVec(0.3,0.3,0.3)),
                  material=check_material)) ]#
  # mirror cube
  world.shapes.add(newSphere(material=sphere_material, transformation=scaling(newVec(0.5,0.5,0.5))*translation(newVec(0, 0, 1))))
  world.shapes.add(newAABox(material=mirror_material, transformation=scaling(newVec(0.6,0.6,0.6))*translation(newVec(3, 5, 0))))
 ]#
  world.shapes.add(newSphere(material=sky_material, transformation=scaling(newVec(200, 200, 200)) * translation(newVec(0, 0, 0.4))))
  world.shapes.add(newPlane(material=ground_material))
  world.shapes.add(newSphere(material=sphere_material, transformation=scaling(newVec(0.3,0.3,0.3))*translation(newVec(0, 0, 1))))
  world.shapes.add(newAABox(material=mirror_material, transformation=translation(newVec(1, 2.5, 0))))
 
  var renderer = newPathTracer(world)
  tracer.fireAllRays(renderer)
  tracer.image.writePfmImage(strm)    
  tracer.image.writeLdrImage("test.png")


#*********************************** MAIN ***********************************

when isMainModule:
  if args["pfm2png"]:
    pfm2png()
  if args["demo"]:
    let t1 = epochTime()
    demo()
    let t2 = epochTime()
    echo("Execution time: ", t2 - t1)
  if args["debug"]:
    debug()
