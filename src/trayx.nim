import basictypes, pfm, ldr, cameras, shapes, transformation, geometry, renderer
import docopt
import std/[strutils, strformat, streams, os, options]


let doc = """
T-RayX: a Nim Raytracing Library

Usage:
  ./trayx pfm2png <INPUT_FILE.pfm> <alpha> <gamma> <OUTPUT.png>
  ./trayx demo [--angle=<angle-deg>] [--output=<output-file>] [--orthogonal]

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
  # Demo procedure that generates 10 spheres
  var tracer : ImageTracer
  if args["--orthogonal"]:
    if args["--angle"]:
      tracer = newImageTracer(newHdrImage(640, 480), newOrthogonalCamera(640/480, rotation_z(-parseFloat($args["--angle"]))*translation(newVec(-1,0,0))))
    else:
      tracer = newImageTracer(newHdrImage(640, 480), newOrthogonalCamera(640/480, translation(newVec(-1,0,0))))
  else:
    if args["--angle"]:
      tracer = newImageTracer(newHdrImage(640, 480), newPerspectiveCamera(1, 640/480, rotation_z(-parseFloat($args["--angle"]))*translation(newVec(-1,0,0))))
    else:
      tracer = newImageTracer(newHdrImage(640, 480), newPerspectiveCamera(1, 640/480, translation(newVec(-1,0,0))))
  var
    strm = newFileStream("output/demo.pfm", fmWrite)
    scaling = scaling(newVec(1/10, 1/10, 1/10))
    s1 = newSphere(translation(newVec(0, 0.5, 0))*scaling)
    s2 = newSphere(translation(newVec(0, 0, -0.5))*scaling)
    cube = newAABox(newPoint(-0.25,-0.15,-0.15), newPoint(0.25,0.15,0.15), rotation_x(45.0))
    world : World
  world.shapes.add(s1)
  world.shapes.add(s2)
  world.shapes.add(cube)
  for i in [-0.5, 0.5]:
    for j in [-0.5, 0.5]:
      for k in [-0.5, 0.5]:
        world.shapes.add(newSphere(translation(newVec(i, j, k))*scaling))
  proc f(r : Ray) : Color = 
    if world.rayIntersection(r).isNone: 
      result = newColor(0.0, 0.0, 0.0)
    else:
      result = newColor(1, 1, 1)
  tracer.fireAllRays(f)
  tracer.image.writePfmImage(strm)
  if args["--output"]:
    tracer.image.writeLdrImage($args["--output"])
  else:
    tracer.image.writeLdrImage("demo.png")

#*********************************** MAIN ***********************************

when isMainModule:
  if args["pfm2png"]:
    pfm2png()
  if args["demo"]:
    demo()
