import std/endians
import std/streams
import std/strutils

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
        raise InvalidPfmFileFormat("missing endianness specification")

    if val > 0: return 1.0
    elif val < 0: return -1.0
    else: raise InvalidPfmFileFormat("invalid endianness specification")
