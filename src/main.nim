import src/basictypes
import os

type
    Parameters* = object
        input_pfm_file_name : string = ""
        factor : float = 0.2
        gamma : float = 1.0
        output_png_file_name : string = ""

proc parse_command_line*(param : Parameters):
    var args = commandLineParams()
    if len(args) != 4:
        raise: newException(IOError, "Usage: main.py INPUT_PFM_FILE FACTOR GAMMA OUTPUT_PNG_FILE")
    param.input_pfm_file_name = args[0]
    param.factor = args[1]
    param.gamma = args[2]
    param.output_png_file_name = args[3]