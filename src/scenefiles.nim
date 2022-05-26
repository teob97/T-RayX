import std/[tables, streams, strutils]

const WHITESPACE* = ['\0', '\t', '\n', '\r']
const SYMBOLS* = ['(', ')', '[', ']', '<', '>', '*']

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
    saved_char* : char
    saved_location* : SourceLocation
    tabulation* : int

#*************************************** TOKEN *******************************************

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

#***************************************** INPUT STREAM *********************************************

proc newInputStream*(stream : Stream, file_name : string = "", tabulation = 4): InputStream =
  result.stream = stream
  result.location = newSourceLocation(file_name = file_name, line_num = 1, col_num = 1)
  result.saved_char = '\0'
  result.saved_location = result.location
  result.tabulation = tabulation

proc updatePos*(strm : var InputStream, ch : char) =
  if ch == '\0':
    return
  elif ch == '\n':
    strm.location.line_num = strm.location.line_num + 1
    strm.location.col_num = strm.location.col_num + 1
  elif ch == '\t':
    strm.location.col_num = strm.location.col_num + 1
  else:
    strm.location.col_num = strm.location.col_num + 1

proc readChar*(strm : var InputStream) : char =
  if strm.saved_char != '\0':
    result = strm.saved_char
    strm.saved_char = '\0'
  else:
    result = strm.stream.readChar()
  strm.saved_location = strm.location
  strm.updatePos(result)

proc unreadChar*(strm : var InputStream, ch : char) =
  assert strm.saved_char == '\0'
  strm.saved_char = ch
  strm.location = strm.saved_location

proc skipWhitespacesAndComments*(strm : var InputStream) =
  var ch = strm.readChar()
  while (ch in WHITESPACE) or ch == '#':
    if ch == '#':
      while not (strm.readChar() in ['\r', '\n', '\0']):
        discard
    ch = strm.readChar()
    if ch == '\0':
      return
  # Put the non-whitespace character back
  strm.unreadChar(ch)

proc parseStringToken*(strm : var InputStream, token_location : SourceLocation) : Token =
  var token = ""
  var ch : char
  while true:
    ch = strm.readChar()
    if ch == '"':
      break
    if ch == '\0':
      let error_string = "Unterminated string. Missing `\"` at position: row: "&intToStr(strm.location.line_num)&", column: "&intToStr(strm.location.col_num)
      raise newException(GrammarError, error_string)
    token = token & ch
  result = Token(location : token_location, kind : StringToken, s : token)

proc parseFloatToken*(strm : var InputStream, first_char : string, token_location : SourceLocation) : Token =
  var
    token = first_char
    ch : char
    value : float
  while true:
    ch = strm.readChar()
    if not (ch.isDigit() or ch == '.' or ch in ['e', 'E']):
      strm.unreadChar(ch)
      break
    token = token & ch
  try:
    value = token.parseFloat
  except ValueError:
      let error_string = "Location: row: "&intToStr(strm.location.line_num)&", column: "&intToStr(strm.location.col_num)&"\n"& $value&"is an invalid floating-point number"
      raise newException(GrammarError, error_string)
  result = Token(location : token_location, kind : LiteralNumberToken, value : value) 


proc parseKeywordOrIdentifierToken*(strm : var InputStream, first_char : string, token_location : SourceLocation) : Token =
#Union[KeywordToken, IdentifierToken] =
  var
    token = first_char
    ch : char
  while true:
    ch = strm.readChar()
    # Note that here we do not call "isAlpha" but "isAlphaNumeric": digits are ok after the first character ??????
    if not (ch.isAlphaNumeric() or ch=='_'):
      strm.unreadChar(ch)
      break
    token = token & ch
  try:
    # If it is a keyword, it must be listed in the KEYWORDS dictionary
    result = Token(location : token_location, kind : KeywordToken, keyword : KEYWORDS[token])
  except KeyError:
    # If we got KeyError, it is not a keyword and thus it must be an identifier
    result = Token(location : token_location, kind : IdentifierToken, identifier : token)




