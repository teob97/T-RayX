import std/endians
import std/streams
import std/strutils
import basictypes

type
    InvalidPfmFileFormat* = object of CatchableError

proc readFloat*(stream: Stream, endianness: float) : float32 =
    ## Read a binary value and convert it to float32 value using the correct endianness
    var num: float32
    var x = stream.readUint32()
    if endianness > 0:
        bigEndian32(addr num, addr x)
    if endianness < 0:
        littleEndian32(addr num, addr x)
    return num

proc parseImgSize*(line: string): (int,int) =
    ## Take the string containing width x height and return a tuple of int
    var 
        elements = split(line)
        width : int
        height : int

    if len(elements) != 2:
        raise newException(InvalidPfmFileFormat, "Invalid image size specification")

    try:
        width = elements[0].parseInt()
        height = elements[1].parseInt()
        if width < 0 or height < 0:
            raise newException(ValueError, "")
    except ValueError:
        raise newException(InvalidPfmFileFormat, "Ivalid width/height")

    return (width, height)

proc parseEndianness*(line: string) : float32 =
    ## Take the srting containing the endianness and return the corresponding float32
    var val : float32
    try:
        val = line.parseFloat()
    except ValueError:
        raise newException(InvalidPfmFileFormat, "missing endianness specification")

    if val > 0: return 1.0
    elif val < 0: return -1.0
    else: raise newException(InvalidPfmFileFormat, "invalid endianness specification")

proc readPfmImage*(stream: Stream) : HdrImage =

    #Check if the file is a pfm image reading the first line
    let magic = stream.readLine()
    if magic != "PF":
        raise newException(InvalidPfmFileFormat, "invalid magic in PFM file")
    
    #Read the second and third lines of the pfm image and save all the information
    let 
        (width, height) = parseImgSize(stream.readLine())
        endianness : float32 = parseEndianness(stream.readLine())

    #Create the hdr image and the other usefull variables
    var 
        img : HdrImage = newHdrImage(width=width, height=height)
        c : Color
        y : int = height - 1
    
    while y >= 0:
        for x in 0 ..< width:
            c.r = readFloat(stream, endianness)
            c.g = readFloat(stream, endianness)
            c.b = readFloat(stream, endianness)
            set_pixel(img, x, y, c)
        y = y - 1
    
    stream.close()
    return img
