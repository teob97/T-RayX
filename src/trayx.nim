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

import trayx/[basictypes, cameras, pfm, ldr,  imagetracer, shapes, transformation, geometry, materials, renderer, scenefiles]
import std/[strutils, strformat, streams, times, options]
import docopt
when compileOption("profiler"):
  import nimprof

let doc = """
T-RayX: a Nim Raytracing Library

Usage:
  ./trayx render <SCENE_FILE.txt> <width> <height> [options]
  ./trayx pfm2png <INPUT_FILE.pfm> <alpha> <gamma> <OUTPUT.png>
  ./trayx demo

Options:
  --renderer=<type>             Renderer's type: onoff, flat, pathtracing, pointlight. Default: pathtracing.
  --clock=<angle-deg>           Angle in degree. Use it to rotate camera.
  --output=<output-file>        Output file.png
  --numberOfRays=<nRay>         Number of rays departing from each surface point (only applicable with --algorithm=pathtracing).
  --maxDepth=<depth>            Maximum allowed ray depth (only applicable with --algorithm=pathtracing).
  --initState=<seed>            Initial seed for the random number generator (positive number).
  --initSeq=<seq-seed>          Identifier of the sequence produced by the random number generator (positive number)."
  --samplePerPixel=<n_sample>   Number of samples per pixel (must be a perfect square, e.g., 16).
  -h --help                     Show this screen
  --version                     Show version
"""

let args = docopt(doc, version = "1.0.0") #find a way to automatize versioning

#*********************************** PFM2PNG ***********************************

#[ type
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

proc pfm2png*() =
  ## Main procedure to convert a .pfm file into a .png file
  var param : Parameters
  try:
    parseCommandLine(param):
  except IOError:
    echo ("Error: wrong parameters. See --help.")
    return
  var 
    impf = openFileStream(param.input_pfm_file_name)
    img : HdrImage = readPfmImage(impf)
  impf.close()
  echo (fmt"File {param.input_pfm_file_name} has been read from disk.")
  img.normalize_image(factor=param.factor)
  img.clamp_image()
  var outf = newFileStream(param.output_png_file_name, fmWrite)
  img.write_ldr_image(name=param.output_png_file_name, gamma=param.gamma)
  outf.close()
  echo (fmt"File {param.output_png_file_name} has been written to disk.") ]#

proc pfm2png*() =
  ## Main procedure to convert a .pfm file into a .png file
  var 
    impf = openFileStream($args["<INPUT_FILE.pfm>"])
    img : HdrImage = readPfmImage(impf)
  impf.close()
  echo ("File "&($args["<INPUT_FILE.pfm>"])&" has been read from disk.")
  img.normalize_image(factor = parseFloat($args["<alpha>"]))
  img.clamp_image()
  var outf = newFileStream($args["<OUTPUT.png>"], fmWrite)
  img.write_ldr_image(name = $args["<OUTPUT.png>"], gamma = parseFloat($args["<gamma>"]))
  outf.close()
  echo (fmt"File "&($args["<OUTPUT.png>"])&" has been written to disk.")

#*********************************** DEMO ***********************************

proc demo*()=
  let
    width  : int = 960
    height : int = 540
    ratio : float = width/height
  var 
    translation : Transformation = translation(newVec(-1.0, 0.0, 1.0))
    world : World
    strm : FileStream = newFileStream("output/demo.pfm", fmWrite)
    tracer : ImageTracer = newImageTracer(newHdrImage(width, height), newPerspectiveCamera(1, ratio, translation))      
  let
    sky_material: Material = newMaterial(brdf = newDiffuseBRDF(newUniformPigment(newColor(0, 0, 0))), emitted_radiance = newUniformPigment(newColor(1.0, 0.9, 0.5)))
    ground_material: Material = newMaterial(brdf = newDiffuseBRDF(pigment = newCheckeredPigment(color1 = newColor(0.3, 0.5, 0.1), color2 = newColor(0.1, 0.2, 0.5))))
    sphere_material: Material = newMaterial(brdf = newDiffuseBRDF(pigment = newUniformPigment(newColor(0.3, 0.4, 0.8))))
    mirror_material: Material = newMaterial(brdf = newSpecularBRDF(pigment = newUniformPigment(color = newColor(0.6, 0.2, 0.3))))
  # Add all the shapes in world
  world.shapes.add(newSphere(material=sky_material, transformation=scaling(newVec(200, 200, 200)) * translation(newVec(0, 0, 0.4))))
  world.shapes.add(newPlane(material=ground_material))
  world.shapes.add(newSphere(material=sphere_material, transformation=translation(newVec(0, 0, 1))))
  world.shapes.add(newSphere(material=mirror_material, transformation=translation(newVec(1, 2.5, 0))))
  #Initiallize the render and fire the rays
  let renderer : Renderer = newPathTracer(world)
  tracer.fireAllRays(renderer)
  tracer.image.writePfmImage(strm)
  tracer.image.writeLdrImage("demo.png")

#*************************************RENDER*************************************************

proc render*() =
  # Check is the variable `clock` has been defined through the CLI.

  # FARE IN MODO COME FA TOMASI DI GENERARE UNA TABELLA GENERICA NEL CASO SI VOLESSERO DEFINIRE PIÙ PARAMETRI.

  var variables = initTable[string, float]()
  if args["--clock"]:
    variables["clock"] = parseFloat($args["--clock"]) 
  # Define all the basic components
  var 
    file_stream : FileStream = newFileStream($args["<SCENE_FILE.txt>"], fmRead)
    input_stream : InputStream = newInputStream(file_stream)
    img_scene : Scene = parseScene(input_stream, variables) #Qui la possibilità di passare una tabella di variabili se si desidera passarle da linea di comando.
    renderer : Renderer
  file_stream.close()
  # Check is the renderer's type has been defined through the CLI
  if args["--renderer"]:
    case $args["--renderer"]:
      of "onoff":
        renderer = newOnOffRenderer(img_scene.world)
      of "flat":
        renderer = newFlatRenderer(img_scene.world)
      of "pointlight":
        renderer = newPointLightRenderer(img_scene.world)
      of "pathtracing":
        renderer = newPathTracer(img_scene.world)
      else:
        raise newException(IOError, "Invalid type of renderer.")
  else: # Default type
    renderer = newPathTracer(img_scene.world)
  # Check if parameters are defined through the CLI
  if args["--numberOfRays"] and (renderer of PathTracer):
    renderer.setNumOfRays(parseInt($args["--numberOfRays"]))
  if args["--maxDepth"] and (renderer of PathTracer):
    renderer.setMaxDepth(parseInt($args["--maxDepth"]))
  if args["--initState"] and (renderer of PathTracer):
    renderer.setPCG(s1 = (parseUInt($args["--initState"])))
  if args["--initSeq"] and (renderer of PathTracer):
    renderer.setPCG(s2 = (parseUInt($args["--initSeq"])))
  if args["--initState"] and args["--initSeq"] and (renderer of PathTracer):
    renderer.setPCG(s1 = (parseUInt($args["--initState"])), s2 = (parseUInt($args["--initSeq"])))

  var
    width  : int = parseInt($args["<width>"])
    height : int = parseInt($args["<height>"])

  if "clock" in img_scene.float_variables:
    img_scene.camera.get().transformation = img_scene.camera.get().transformation * rotation_z(img_scene.float_variables["clock"])

  var tracer : ImageTracer = newImageTracer(newHdrImage(width, height), img_scene.camera.get())
  if args["--samplePerPixel"]:
    tracer.samples_per_side = parseInt($args["--samplePerPixel"])

  tracer.fireAllRays(renderer)
  if args["--output"]:
    tracer.image.writeLdrImage($args["--output"])
  else:
    tracer.image.writeLdrImage("result.png")

#*********************************** MAIN ***********************************

when isMainModule:
  if args["pfm2png"]:
    pfm2png()
  if args["demo"]:
    let t1 = epochTime()
    demo()
    let t2 = epochTime()
    echo("Execution time: ", t2 - t1)
  if args["render"]:
    let t1 = epochTime()
    render()
    let t2 = epochTime()
    echo("Execution time: ", t2 - t1)