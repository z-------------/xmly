# xmly

## Example

```nim
import pkg/xmly
import std/times

type
  Document = object
    foo: Foo
    bar: Bar
  Foo = object
    items {.name: "thing".}: seq[int]
    subObject: SubObject
  SubObject = object
    pi {.attr.}: float
  Bar = object
    key {.attr.}: string
    value {.text.}: DateTime

proc parseHook(s: string; dest: var DateTime) =
  dest = times.parse(s, "yyyy-MM-dd'T'hh:mm:ssz")

let xml = """
<foo>
  <thing>1</thing>
  <sub-object pi="3.14"/>
  <thing>42</thing>
</foo>
<bar key="something">2023-08-12T06:20:00Z</bar>
"""
let doc = Document.fromXml(xml)
echo doc
# (foo: (items: @[1, 42], subObject: (pi: 3.14)), bar: (key: "something", value: 2023-08-12T06:20:00+00:00))
```
