import std/[options, tables, streams, strutils]

type
  GrammarError* = object of CatchableError
    #location* : SourceLocation
    #message* : string
  SourceLocation* = object 
    file_name* : string
    line_num* : int
    col_num* : int
  InputStream* = object
    stream* : Stream
    location* : SourceLocation
    saved_char* : Option[char]
    saved_location* : SourceLocation
    tabulation* : int



type
  KeywordEnum* = enum
    NEW = 1,
    MATERIAL = 2,
    PLANE = 3,
    SPHERE = 4,
    DIFFUSE = 5,
    SPECULAR = 6,
    UNIFORM = 7,
    CHECKERED = 8,
    IMAGE = 9,
    IDENTITY = 10,
    TRANSLATION = 11,
    ROTATION_X = 12,
    ROTATION_Y = 13,
    ROTATION_Z = 14,
    SCALING = 15,
    CAMERA = 16,
    ORTHOGONAL = 17,
    PERSPECTIVE = 18,
    FLOAT = 19

const KEYWORDS = {"new": KeywordEnum.NEW,
              "material": KeywordEnum.MATERIAL,
              "plane": KeywordEnum.PLANE,
              "sphere": KeywordEnum.SPHERE,
              "diffuse": KeywordEnum.DIFFUSE,
              "specular": KeywordEnum.SPECULAR,
              "uniform": KeywordEnum.UNIFORM,
              "checkered": KeywordEnum.CHECKERED,
              "image": KeywordEnum.IMAGE,
              "identity": KeywordEnum.IDENTITY,
              "translation": KeywordEnum.TRANSLATION,
              "rotation_x": KeywordEnum.ROTATION_X,
              "rotation_y": KeywordEnum.ROTATION_Y,
              "rotation_z": KeywordEnum.ROTATION_Z,
              "scaling": KeywordEnum.SCALING,
              "camera": KeywordEnum.CAMERA,
              "orthogonal": KeywordEnum.ORTHOGONAL,
              "perspective": KeywordEnum.PERSPECTIVE,
              "float": KeywordEnum.FLOAT
              }.toTable
type
  TokenKind* = enum
    KeywordToken,
    IdentifierToken,
    StringToken,
    LiteralNumberToken,
    SymbolToken,
    StopToken
  Token* = ref TokenValue
  TokenValue* = object
    location*: SourceLocation
    case kind*: TokenKind
    of KeywordToken:
      keyword*: KeywordEnum
    of IdentifierToken:
      identifier* : string
    of StringToken:
      s* : string
    of LiteralNumberToken:
      value* : float
    of SymbolToken:
      symbol* : string
    of StopToken:
      useless_thing* : bool

#*************************************** SOURCE LOCATION *******************************************

proc newSourceLocation*(file_name : string = "", line_num = 0, col_num = 0): SourceLocation =
  result.file_name = file_name
  result.line_num = line_num
  result.col_num = col_num

#*************************************** GRAMMAR ERROR *******************************************

#[ proc newGrammarError*(location : SourceLocation): GrammarError =
  result = GrammarError.new()
  result.location = location
  #result.message = message ]#

#***************************************** INPUT STREAM *********************************************

proc newInputStream*(stream : Stream, file_name : string = "", tabulation = 4): InputStream =
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

proc parseStringToken*(strm : var InputStream, token_location : SourceLocation) : Token =
  var token = ""
  var ch : Option[char]
  while true:
    ch = strm.readChar()
    if ch.get() == '"':
      break
    if ch.isNone:
      let error_string = "Unterminated string. Missing `\"` at position: row "&intToStr(strm.location.line_num)&", column "&intToStr(strm.location.col_num)
      raise newException(GrammarError, error_string)
    token = token & $ch.get()
  result = Token(location : token_location, kind : StringToken, s : token)