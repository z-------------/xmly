import pkg/xmly
import std/[
  unittest,
]

test "eof while reading tag contents":
  type
    Document = object
      stuff: Stuff
    Stuff = object
      foo {.attr.}: string
      bar: string

  const Xml = """
<stuff foo="hi"
  """
  let expected = Document(
    stuff: Stuff(
      foo: "hi",
    ),
  )
  let parsed = Document.fromXml(Xml)
  check parsed == expected
