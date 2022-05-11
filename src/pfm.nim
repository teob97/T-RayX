import std/[endians, streams, strutils, strformat]
import basictypes

type
    InvalidPfmFileFormat* = object of CatchableError

#*********************************** READING ***********************************

proc readFloat*(stream: Stream, endianness: float) : float32 =
    ## Reading 4 byte sequence in a 32 bit floating-point taking endianness into account
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
        val = line.parseFloat() #native
    except ValueError:
        raise newException(InvalidPfmFileFormat, "missing endianness specification")
    if val > 0: return 1.0
    elif val < 0: return -1.0
    else: raise newException(InvalidPfmFileFormat, "invalid endianness specification")

proc readPfmImage*(stream: Stream) : HdrImage =
    ## Read a pfm image as a stream and return HdrImage type
    # Check if the file is a pfm image reading the first line
    let magic = stream.readLine()
    if magic != "PF":
        raise newException(InvalidPfmFileFormat, "invalid magic in PFM file")
    # Read the second and third lines of the pfm image and save all the information
    let 
        (width, height) = parseImgSize(stream.readLine())
        endianness : float32 = parseEndianness(stream.readLine())
    # Create the hdr image and the other usefull variables
    var 
        img : HdrImage = newHdrImage(width=width, height=height)
        c : Color
        y : int = height - 1
    while y >= 0:
        for x in 0 ..< width:
            c.r = readFloat(stream, endianness)
            c.g = readFloat(stream, endianness)
            c.b = readFloat(stream, endianness)
            setPixel(img, x, y, c)
        y = y - 1
    stream.close()
    return img

#*********************************** WRITING ***********************************

proc writeFloat*(stream : Stream, color : float32, endianness: float32) =
    ## Write a float32 into a stream with the right endianness
    if endianness == -1.0:
        stream.write(color)
    else:
        var val2 : uint32
        var col : float32 = color
        swapEndian32(addr val2, addr col)
        stream.write(val2)

proc writePfmImage*(img: HdrImage, stream: Stream, endianness: float32 = -1.0) =
    ## Print a PFM image into a stream
    var endianness_string : string
    if endianness == -1.0: endianness_string = "-1.0"
    else: endianness_string = "1.0"
    stream.writeLine("PF")
    stream.writeLine(fmt"{img.width} {img.height}")
    stream.writeLine(fmt"{endianness_string}")
    var c : Color
    for y in countdown(img.height - 1, 0):
        for x in 0 ..< img.width:
            c = getPixel(img, x, y)
            writeFloat(stream, c.r, endianness)
            writeFloat(stream, c.g, endianness)
            writeFloat(stream, c.b, endianness)
