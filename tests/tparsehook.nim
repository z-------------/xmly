import pkg/xmly
import std/[
  parsexml,
  times,
  unittest,
]

proc parseHook(s: string; dest: var DateTime) =
  dest = times.parse(s, "yyyy-MM-dd'T'hh:mm:ssz")

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
