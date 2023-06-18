import pkg/xmly
import std/[
  parsexml,
  strutils,
  times,
  unittest,
]

proc parseHook(s: string; dest: var DateTime) =
  dest = times.parse(s, "yyyy-MM-dd'T'hh:mm:ssz")

proc parseHook(s: string; dest: var bool) =
  dest = not parseBool(s)

test "custom parse hooks":
  type
    Document = object
      date: DateTime

  const Xml = "<date>2023-06-18T05:13:48Z</date>"
  let expected = Document(
    date: dateTime(2023, mJun, 18, 5, 13, 48, zone = utc()),
  )
  let parsed = Document.fromXml(Xml)
  check parsed == expected

test "override builtin parse hook":
  type
    Document = object
      myBool: seq[bool]

  const Xml = """
<myBool>false</myBool>
<myBool>true</myBool>
<myBool>false</myBool>
<myBool>false</myBool>
<myBool>true</myBool>
  """
  let expected = Document(
    myBool: @[true, false, true, true, false],
  )
  let parsed = Document.fromXml(Xml)
  check parsed == expected
