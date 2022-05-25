include streams, options

type
    GrammarError* = object of CatchableError

type
  SourceLocation* = object 
    file_name : string
    line_num : int
    col_num : int
  InputStream* = object
    stream : FileStream
    location : SourceLocation
    saved_char : Option[char]
    saved_location : SourceLocation
    tabulation : int


proc newSourceLocation*(file_name : string = "", line_num = 0, col_num = 0): SourceLocation =
  result.file_name = file_name
  result.line_num = line_num
  result.col_num = col_num

proc newInputStream*(stream : FileStream, file_name : string = "", tabulation = 4): InputStream =
  result.stream = stream
  result.location = newSourceLocation(file_name = file_name, line_num = 1, col_num = 1)
  result.saved_char = none(char)
  result.saved_location = result.location
  result.tabulation = tabulation

proc updatePos*(strm : var InputStream, ch : Option[char]) =
  if ch.isNone:
    return
  elif ch.get() == '\n':
    strm.location.line_num = strm.location.line_num + 1
    strm.location.col_num = strm.location.col_num + 1
  elif ch.get() == '\t':
    strm.location.col_num = strm.location.col_num + 1
  else:
    strm.location.col_num = strm.location.col_num + 1

proc read_char*(strm : var InputStream) : Option[char] =
  if not strm.saved_char.isNone:
    result = strm.saved_char
    strm.saved_char = none(char)
  else:
    result = some(strm.stream.readChar())
  strm.saved_location = strm.location
  strm.updatePos(result)

proc unread_char*(strm : var InputStream, ch : Option[char]) =
  assert strm.saved_char.isNone
  strm.saved_char = ch
  strm.location = strm.saved_location