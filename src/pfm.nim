import std/endians
import std/streams
import std/strutils
import basictypes

type
    InvalidPfmFileFormat = object of CatchableError

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
    ## Reading width and height from a string
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
    var val : float32
    try:
        val = line.parseFloat()
    except ValueError:
        raise newException(InvalidPfmFileFormat, "missing endianness specification")
    if val > 0: return 1.0
    elif val < 0: return -1.0
    else: raise newException(InvalidPfmFileFormat, "invalid endianness specification")

proc readPfmImage*(stream: Stream) : HdrImage =
    let magic = stream.readLine()
    if magic != "PF":
        raise newException(InvalidPfmFileFormat, "invalid magic in PFM file")
    let img_size : string = stream.readLine()
    let (width, height) = parseImgSize(img_size)
    let endianness_line : string = stream.readLine()
    let endianness : float32 = parseEndianness(endianness_line)
    var img : HdrImage = newHdrImage(width=width, height=height)
    var c : Color
    var y : int = height - 1
    while y >= 0:
        for x in 0 ..< width:
            c.r = readFloat(stream, endianness)
            c.g = readFloat(stream, endianness)
            c.b = readFloat(stream, endianness)
            set_pixel(img, x, y, c)
        y = y - 1
    return img


# ANCORA DA SISTEMAREEEEE
proc writePfmImage*(img HdrImage, stream: Stream, endianness: float) =
    let endianness_string : string
    if endianness == -1.0: endianness_string == "-1.0"
    else: endianness_string == "1.0"
    # vedi differenza tra fmt vs. &
    let header : string = fmt"PF\n{img.width} {self.height}\n-1.0\n"
    stream.write(header)
    var c : Color
    var y : int = height - 1
    while y >= 0:
        for x in 0 ..< width:
            c = get_pixel(img, x, y)
            #ATTENZIONE MANCA WRITEFLOAT 
            writeFloat(stream, c.r, endianness)
            writeFloat(stream, c.g, endianness)
            writeFloat(stream, c.b, endianness)




