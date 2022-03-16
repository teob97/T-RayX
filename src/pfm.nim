import std/endians
import std/streams
import std/strutils
import src/basictypes

proc readFloat*(stream: Stream, endianness: float) : float32 =
    var num: float32
    var x = stream.readUint32()
    if endianness > 0:
        bigEndian32(addr num, addr x)
    if endianness < 0:
        littleEndian32(addr num, addr x)
        return num

proc parseEndianness*(line: string) : float32 =
    var val : float32
    try:
        val = line.parseFloat
    except ValueError:
        raise newException (InvalidPfmFileFormat, "missing endianness specification")

    if val > 0: return 1.0
    elif val < 0: return -1.0
    else: raise newException (InvalidPfmFileFormat, "invalid endianness specification")

proc readPfmImage*(stream: Stream) : HdrImage =
    const magic = stream.readLine()
    if magic != "PF":
        raise newException(InvalidPfmFileFormat, "invalid magic in PFM file")
    const img_size : string = stream.readLine()
    const (width, height) : int = parseImgSize(img_size)
    const endianness_line : string = stream.readLine()
    const endianness : float32 = parseEndianness(endianness_line)
    var result : HdrImage = newHdrImage(width=width, height=height)
    var c : Color
    var y : int = height - 1
    while y >= 0:
        for x in 0 ..< width:
            c.r = readFloat(stream, endianness)
            c.g = readFloat(stream, endianness)
            c.b = readFloat(stream, endianness)
            set_pixel(result, x, y, c)
        y = y - 1
    return result