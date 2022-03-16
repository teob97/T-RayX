import std/endians
import std/streams

proc readFloat*(stream: Stream, endianness: float) : float32 =

    var num: float32
    var x = stream.readUint32()

    if endianness > 0:
        bigEndian32(addr num, addr x)
    if endianness < 0:
        littleEndian32(addr num, addr x)
    return num
