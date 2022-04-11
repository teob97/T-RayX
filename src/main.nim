import basictypes
import pfm
import ldr
import std/strutils
import std/strformat
import std/streams
import std/os

type
    Parameters* = object
        input_pfm_file_name : string
        factor : float
        gamma : float
        output_png_file_name : string

# Read parameters form command line
proc parseCommandLine*(param : var Parameters) =
    var args = commandLineParams()
    if len(args) != 4:
        raise newException(IOError, "Usage: main.nim INPUT_PFM_FILE FACTOR GAMMA OUTPUT_PNG_FILE")
    param.input_pfm_file_name = args[0]
    try:
        param.factor = args[1].parseFloat
    except ValueError:
        raise newException(IOError, fmt"Invalid factor ('{args[1]}'), it must be a floating-point number.")
    try:
        param.gamma = args[2].parseFloat
    except ValueError:
        raise newException(IOError, fmt"Invalid factor ('{args[2]}'), it must be a floating-point number.")
    param.output_png_file_name = args[3]

proc main() =
    var param : Parameters
    try:
        parseCommandLine(param):
    except IOError as err:
        echo ("Error: ", err)
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

main()