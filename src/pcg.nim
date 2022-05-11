type
  PCG* = object
    state* : uint64
    inc* : uint64

proc random*(pcg : var PCG): uint32 =
  var oldstate : uint64 = pcg.state
  pcg.state = uint64(oldstate * 6364136223846793005.uint64 + pcg.inc)
  var 
    xorshifted : uint32 = uint32((((oldstate shr 18) xor oldstate) shr 27))
    rot : uint32 = uint32(oldstate shr 59)
  result = uint32((xorshifted shr rot) or (xorshifted shl ((not(rot)+1) and 31)))

proc newPCG*(init_state : uint64 = 42, init_seq: uint64 = 54): PCG =
  result.state = 0
  result.inc = (init_seq shl 1) or 1
  var trash = result.random()
  result.state += init_state
  trash = result.random()

proc random_float*(pcg : var PCG): float =
  result = pcg.random().float / 0xffffffff.float