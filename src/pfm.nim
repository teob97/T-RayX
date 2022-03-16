import std/endians
import std/streams
import std/strutils

type
    InvalidPfmFileFormat = object of CatchableError

proc readFloat*(stream: Stream, endianness: float) : float32 =
    
    var num: float32
    var x = stream.readUint32()

    if endianness > 0:
        bigEndian32(addr num, addr x)
    if endianness < 0:
        littleEndian32(addr num, addr x)
    return num

proc parseImgSize*(line: string): (int,int) =
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