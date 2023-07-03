import pkg/xmly
import std/[
  os,
  streams,
  unittest,
]

const Filename = currentSourcePath().parentDir / "data" / "xml.xml"

type
  Document = object
    foo: Foo
  Foo = object
    bar: Bar
  Bar = object
    baz {.attr.}: string
    text {.text.}: string

let expected = Document(
  foo: Foo(
    bar: Bar(
      baz: "qux",
      text: "Lorem",
    ),
  ),
)

test "parse from file":
  let f = open(Filename, fmRead)
  let parsed = Document.fromXml(f)
  check parsed == expected

test "parse from stream":
  let s = openFileStream(Filename, fmRead)
  let parsed = Document.fromXml(s)
  check parsed == expected
