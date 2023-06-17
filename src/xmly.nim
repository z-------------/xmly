# Copyright 2023 Zachary Guard
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import std/[
  macros,
  parsexml,
  streams,
  strutils,
]

# TODO mixed content
# TODO Option instead of default value

template attr() {.pragma.}

template raiseXmlError(x: XmlParser) =
  raise newException(ValueError, x.errorMsg)

proc skipElement(x: var XmlParser) =
  var depth = 1
  while true:
    case x.kind
    of xmlError:
      raiseXmlError(x)
    of xmlEof:
      break
    of xmlElementOpen, xmlElementStart:
      inc depth
    of xmlElementEnd:
      dec depth
      if depth <= 0:
        break
    else:
      discard
    x.next()

proc parseHook(s: string; dest: var string) {.raises: [].} =
  dest = s

proc parseHook[T: SomeInteger](s: string; dest: var T) {.raises: [ValueError].} =
  dest = T(parseBiggestInt(s))

proc parseHook(s: string; dest: var bool) {.raises: [ValueError].} =
  dest = parseBool(s)

proc parseHook[T: SomeFloat](s: string; dest: var T) {.raises: [ValueError].} =
  dest = T(parseFloat(s))

proc parseXmlHook(x: var XmlParser; dest: var (not object)) =
  case x.kind
  of xmlCharData:
    parseHook(x.charData, dest)
  else:
    discard

proc parseXmlHook(x: var XmlParser; dest: var object) =
  var
    depth = 1
  while true:
    case x.kind
    of xmlError:
      raiseXmlError(x)
    of xmlEof:
      break
    of xmlElementStart, xmlElementOpen:
      inc depth
      let name = x.elementName
      let hasAttrs = x.kind == xmlElementOpen
      x.next()
      for key, val in dest.fieldPairs:
        if key == name:
          when typeof(val) is seq:
            var item = default(typeof(val[0]))
          else:
            var item = default(typeof(val))
          if hasAttrs:
            while true:
              case x.kind
              of xmlAttribute:
                when item is object:
                  for aKey, aVal in item.fieldPairs:
                    if aKey == x.attrKey:
                      when aVal.hasCustomPragma(attr):
                        parseHook(x.attrValue, aVal)
                      break
              of xmlElementClose:
                break
              else:
                discard
              x.next()
          parseXmlHook(x, item)
          when typeof(val) is seq:
            val.add(item)
          else:
            val = item
          break
      skipElement(x)
      continue
    of xmlElementEnd:
      dec depth
      if depth <= 0:
        break
    of xmlCharData, xmlCData, xmlElementClose, xmlAttribute, xmlEntity, xmlWhitespace, xmlComment, xmlPI, xmlSpecial:
      discard
    x.next()

proc fromXml*(t: typedesc; x: var XmlParser): t =
  x.next()
  parseXmlHook(x, result)

proc fromXml*(t: typedesc; s: string): t =
  let input = newStringStream(s)
  var x = XmlParser()
  x.open(input, filename = "")
  defer: x.close()
  fromXml(t, x)

when isMainModule:
  import pkg/pretty

  type
    Document = object
      root: Root
    Root = object
      myrootattr {.attr.}: string
      metadata: Metadata
      repository: seq[Repository]
      dependencies: Dependencies
    Metadata = object
      author: string
      version: string
      somenumber: int
      somefloat: float
    Repository = object
      name: string
      url: string
      optional {.attr.}: bool = true
    Dependencies = object
      dependency: seq[Dependency]
    Dependency = object
      name: string
      version: string

  const Xml = """
<root myrootattr="hello">
  <metadata>
    <author>Jimmy<ftw>huh</ftw></author>
    <version>0.1.2<wtf>yes</wtf></version>
    <somenumber>42</somenumber>
    <somefloat>3.14</somefloat>
  </metadata>
  <repository>
    <name>First Repository</name>
    <url>https://example.com</url>
  </repository>
  <repository optional="false">
    <name>Second Repository</name>
    <url>https://example.org</url>
  </repository>
  <dependencies>
    <dependency>
      <name>myfirstdep</name>
    </dependency>
    <dependency>
      <name>myseconddep</name>
      <version>^1.2.4</version>
    </dependency>
  </dependencies>
</root>
  """
  let myRoot = Document.fromXml(Xml)
  print myRoot
