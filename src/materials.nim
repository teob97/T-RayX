import geometry, basictypes
import std/math

type
  Pigment* = ref object of RootObj
  UniformPigment* = ref object of Pigment
    color* : Color
  ImagePigment* = ref object of Pigment
    image* : HdrImage
  CheckeredPigment* = ref object of Pigment
    color1* : Color
    color2* : Color
    num_of_steps* : int
  BRDF* = ref object of RootObj
    pigment* : Pigment
  DiffuseBRDF* = ref object of BRDF
    reflectance* : float
  Material* = object
    brdf_function* : BRDF
    emitted_radiance* : Pigment


#*********************************** PIGMENT ***********************************

proc newUniformPigment*(color : Color = WHITE) : UniformPigment =
  var pig = UniformPigment.new()
  pig.color = color
  return pig

proc newImagePigment*(image : HdrImage) : ImagePigment =
  var pig = ImagePigment.new()
  pig.image = image
  return pig

proc newCheckeredPigment*(color1, color2 : Color; num_of_steps : int) : CheckeredPigment =
  var pig = CheckeredPigment.new()
  pig.color1 = color1
  pig.color2 = color2
  pig.num_of_steps = num_of_steps
  return pig

method getColor*(pig : Pigment; uv : Vec2d): Color {.base.} =
  quit "to override"

method getColor*(pig : UniformPigment; uv : Vec2d): Color =
  result = pig.color

method getColor*(pig : ImagePigment; uv : Vec2d): Color =
  var
    col = int(uv.u * pig.image.width.float)
    row = int(uv.v * pig.image.height.float)
  if col >= pig.image.width:
    col = pig.image.width - 1
  if row >= pig.image.height:
    row = pig.image.height - 1
  result = pig.image.getPixel(col, row)

method getColor*(pig : CheckeredPigment; uv : Vec2d): Color =
  var
    int_u = int(floor(pig.num_of_steps.float * uv.u))
    int_v = int(floor(pig.num_of_steps.float * uv.v))
  if (int_u mod 2) == (int_v mod 2):
    result = pig.color1
  else:
    result = pig.color2

#*********************************** BRDF ***********************************

proc newDiffuseBRDF*(pigment : Pigment = newUniformPigment()): DiffuseBRDF =
  result = DiffuseBRDF.new()
  result.pigment = pigment

method eval*(brdf : BRDF, normal : Normal; in_dir, out_dir : Vec; uv : Vec2d): Color {.base.} =
  quit "to override"

method eval*(brdf : DiffuseBRDF, normal : Normal; in_dir, out_dir : Vec; uv : Vec2d): Color =
  return brdf.pigment.getColor(uv) * (brdf.reflectance / PI)

#********************************** MATERIAL *******************************

proc newMaterial*(brdf : BRDF = newDiffuseBRDF(newUniformPigment()), emitted_radiance : Pigment = newUniformPigment(BLACK)): Material =
  result.brdf_function = brdf
  result.emitted_radiance = emitted_radiance