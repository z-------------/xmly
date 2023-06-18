import pkg/xmly
import std/[
  unittest,
]

test "chardata to field":
  type
    Document = object
      root: Root
    Root = object
      stuff {.text.}: int
      otherStuff: int

  const Xml = """
<root>
  42
  <otherstuff>1234</otherstuff>
</root>
  """
  let expected = Document(
    root: Root(
      stuff: 42,
      otherStuff: 1234,
    ),
  )
  let parsed = Document.fromXml(Xml)
  check parsed == expected

test "multiple chardata to field":
  type
    Document = object
      root: Root
    Root = object
      stuff {.text.}: seq[int]
      otherStuff: int

  const Xml = """
<root>
  42
  <otherstuff>1234</otherstuff>
  5678
</root>
  """
  let expected = Document(
    root: Root(
      stuff: @[42, 5678],
      otherStuff: 1234,
    ),
  )
  let parsed = Document.fromXml(Xml)
  check parsed == expected

test "leaves with attributes":
  type
    Document = object
      root: Root
    Root = object
      leaf: Leaf
    Leaf = object
      attribute {.attr.}: string
      value {.text.}: float

  const Xml = """
<root>
  <leaf attribute="hello world">3.14</leaf>
</root>
  """
  let expected = Document(
    root: Root(
      leaf: Leaf(
        attribute: "hello world",
        value: 3.14,
      ),
    ),
  )
  let parsed = Document.fromXml(Xml)
  check parsed == expected
