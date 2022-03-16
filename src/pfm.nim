import std/endians
import std/streams

proc readFloat*(stream: Stream, endianness: float) : float32 =
    var num: float32
    var x = stream.readUint32
    if endianness > 0:
        bigEndian32(addr num, addr x)
    if endianness < 0:
        littleEndian32(addr num, addr x)
    return num

var prova = newFileStream("reference_le.pfm")
setPosition(prova, 0)
while prova.atEnd != true:
    echo prova.readFloat(prova, -1)

#[ var l = ""
while prova.readLine(l):
    echo l

setPosition(prova, 3)
echo readFloat(prova, -1.0)
echo readFloat(prova, -1.0)
echo readFloat(prova, -1.0) ]#
