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

import trayx/[basictypes, cameras, pfm, ldr,  imagetracer, shapes, transformation, geometry, materials, renderer, scenefiles, pcg]
import std/[strutils, strformat, streams, times, monotimes, options, os]
import docopt
when compileOption("profiler"):
  import nimprof

let doc = """
T-RayX: a Nim Raytracing Library. 
https://github.com/teob97/T-RayX

Usage:
  ./trayx render <SCENE_FILE.txt> <width> <height> [options]
  ./trayx pfm2png <INPUT_FILE.pfm> <alpha> <gamma> <OUTPUT.png>
  ./trayx demo

Options:
  --renderer=<type>             Renderer's type: onoff, flat, pathtracing, pointlight. [default: pathtracing]
  --output=<output-file>        Output file.png
  --numberOfRays=<nRay>         Number of rays departing from each surface point (pathtracing). [default: 10]
  --maxDepth=<depth>            Maximum allowed number of ray reflection (pathtracing). [default: 2]
  --russian=<RussianLimit>      Depth beyond which the Russian Roulette is triggered. [default: 3]
  --alpha=<alpha>               Normalization parameter used during tone mapping. [default: 1.0]
  --gamma=<gamma>               Correction due to the monitor non-linear response. [default: 1.0]
  --initState=<seed>            Initial seed (positive int) for the random number generator. [default: 42]
  --initSeq=<seq-seed>          Identifier (positive int) of the sequence produced by the random number generator. [default: 97]
  --samplePerPixel=<n_sample>   Number of samples per pixel (must be a perfect square, e.g. 2,4,16...). [default: 0]
  --luminosity=<lum>            Average luminosity of the image (positive float).
  --defineFloat=<var:value>     Used to declare a new float variable. Use '/' to define multiple variables.
Other:
  -h --help                     Show this screen.
  --version                     Show version.
"""

const versionStr = (staticExec "git describe --tags HEAD").split('-')[0]
let args = docopt(doc, version = versionStr)

#*********************************** PFM2PNG ***********************************

proc pfm2png*() =
  ## Procedure to convert a .pfm file into a .png file.
  ## Use: ./trayx pfm2png <INPUT_FILE.pfm> <alpha> <gamma> <OUTPUT.png>
  var 
    impf = openFileStream($args["<INPUT_FILE.pfm>"])
    img : HdrImage = readPfmImage(impf)
  impf.close()
  echo ("File "&($args["<INPUT_FILE.pfm>"])&" has been read from disk.")
  img.normalize_image(factor = parseFloat($args["<alpha>"]))
  img.clamp_image()
  var outf = newFileStream($args["<OUTPUT.png>"], fmWrite)
  img.writeLdrImage(name = $args["<OUTPUT.png>"], gamma = parseFloat($args["<gamma>"]))
  outf.close()
  echo (fmt"File "&($args["<OUTPUT.png>"])&" has been written to disk.")

#*********************************** DEMO ***********************************

proc demo*()=
  ## A demo procedure that generate an image output/demo.png using the pathtracing algoritm.
  ## Use: ./trayx demo
  ## Elements in the image: 
  ## diffusive sphere, 
  ## reflective sphere,
  ## checkered plane as ground
  ## and a luminous sphere as sky.
  let
    width  : int = 960
    height : int = 540
    ratio : float = width/height
  var 
    transf : Transformation = translation(newVec(-1.0, 0.0, 1.0))
    world : World
    strm : FileStream = newFileStream("output/demo.pfm", fmWrite)
    tracer : ImageTracer = newImageTracer(newHdrImage(width, height), newPerspectiveCamera(1, ratio, transf))      
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
  let path : string = "output/demo.png"
  tracer.image.normalizeImage(factor = 1.0)
  tracer.image.clampImage()
  tracer.image.writeLdrImage(path)
  echo("Image saved in "&path)

#*************************************RENDER*************************************************

proc build_variable_table(cliInput : string) : Table[string, float] =
  ## Build a table (dictionary) with the variables defined throught the CLI,
  ## This dictionary will be used to override the values in the parser.
  for elements in cliInput.split('/'):
    var nameAndValues = elements.split(':')
    if nameAndValues.len() != 2:
      raise newException(IOError, "Invalid number of parameters in --defineFloat. Use var1:value1/var2:value2")
    var floatValue : float = nameAndValues[1].parseFloat()
    result[nameAndValues[0]]=floatValue

proc render*() =
  ## Main procedure to renderize an image using a specific alghoritm.
  ## Use: ./trayx render <SCENE_FILE.txt> <width> <height> [options]
  ## To see the aviable options use: ./trayx --helps 
  
  var variables = initTable[string, float]()
  if args["--defineFloat"]:
    variables = build_variable_table($args["--defineFloat"])
  
  # Define input stream and parse the scene
  var 
    file_stream : FileStream = newFileStream($args["<SCENE_FILE.txt>"], fmRead)
    input_stream : InputStream = newInputStream(file_stream)
    img_scene : Scene = parseScene(input_stream, variables)
  file_stream.close()
  
  # Define renderer
  var  
    renderer : Renderer
  if args["--renderer"]:
    case $args["--renderer"]:
      of "onoff":
        renderer = newOnOffRenderer(img_scene.world)
      of "flat":
        renderer = newFlatRenderer(img_scene.world)
      of "pointlight":
        renderer = newPointLightRenderer(img_scene.world)
      of "pathtracing":
        renderer = newPathTracer(world = img_scene.world,
                                pcg = newPCG(init_state = parseUInt($args["--initState"]), init_seq = parseUInt($args["--initSeq"])),
                                num_of_rays = parseInt($args["--numberOfRays"]),
                                max_depth = parseInt($args["--maxDepth"]),
                                russian_roulette_limit = parseInt($args["--russian"])
                                )
      else:
        raise newException(IOError, "Invalid type of renderer.")

  # Define image parameters and image tracer
  let
    width  : int = parseInt($args["<width>"])
    height : int = parseInt($args["<height>"])
  
  var 
    tracer : ImageTracer = newImageTracer(image = newHdrImage(width, height), 
                                            camera = img_scene.camera.get(),
                                            samples_per_side = parseInt($args["--samplePerPixel"]),
                                            pcg = newPCG()
                                            )

  # Fire all the rays and solve the render equation for every ray
  tracer.fireAllRays(renderer)
  
  # Save the final image
  let
    path_ldr : string = "output/img_"&(now().format("yyyy-MM-dd'T'HH:mm:ss"))&".png"
    path_pfm : string = "output/img_"&(now().format("yyyy-MM-dd'T'HH:mm:ss"))&".pfm"
    out_strm : FileStream = newFileStream(path_pfm, fmWrite)

  tracer.image.writePfmImage(out_strm)

  if args["--luminosity"]:
    tracer.image.normalizeImage(factor = parseFloat($args["--alpha"]), luminosity = some(parseFloat($args["--luminosity"])))
  else:
    tracer.image.normalizeImage(factor = parseFloat($args["--alpha"]))
  
  tracer.image.clampImage()

  if args["--output"]:
    tracer.image.writeLdrImage($args["--output"], gamma = parseFloat($args["--gamma"]))
  else:
    tracer.image.writeLdrImage(path_ldr, gamma = parseFloat($args["--gamma"]))

#*********************************** MAIN ***********************************

when isMainModule:

  if not dirExists("output"):
    createDir("output")

  if args["pfm2png"]:
    let t1 = getMonoTime()
    pfm2png()
    let t2 = getMonoTime()
    echo("Execution time: ", t2 - t1)  

  if args["demo"]:
    let t1 = getMonoTime()
    demo()
    let t2 = getMonoTime()
    echo("Execution time: ", t2 - t1)

  if args["render"]:
    let t1 = getMonoTime()
    render()
    let t2 = getMonoTime()
    echo("Execution time: ", t2 - t1)