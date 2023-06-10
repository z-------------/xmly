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
  streams,
  parsexml,
  options,

  sugar,
]

# TODO attributes
# TODO mixed content
# TODO Option instead of default value

template raiseXmlError(x: XmlParser) =
  raise newException(ValueError, x.errorMsg)

proc skipElement(x: var XmlParser) =
  var depth = 1
  while depth > 0:
    x.next()
    case x.kind
    of xmlError:
      raiseXmlError(x)
    of xmlEof:
      break
    of xmlElementOpen, xmlElementStart:
      inc depth
    of xmlElementEnd:
      dec depth
    else:
      discard

proc parseHook(t: typedesc[string]; x: var XmlParser): t =
  x.next()
  case x.kind
  of xmlCharData:
    result = x.charData
  else:
    discard

proc parseHook(t: typedesc[object]; x: var XmlParser): t =
  template parseField(elementName: string) =
    var found = false
    for key, val in result.fieldPairs:
      dump (key, val, elementName)
      if key == elementName:
        echo "matched key '", key, "'"
        when typeof(val) is seq:
          val.add(parseHook(typeof(val[0]), x))
        else:
          val = parseHook(typeof(val), x)
        found = true
        break
    if not found:
      echo "no match for '", elementName, "', skipping"
      skipElement(x)

  var
    depth = 1
    openedElementName = string.none
  while depth > 0:
    x.next()
    dump x.kind
    case x.kind
    of xmlError:
      raiseXmlError(x)
    of xmlEof:
      break
    of xmlCharData, xmlCData:
      dump x.charData
    of xmlElementStart:
      dump x.elementName
      inc depth
      let name = x.elementName
      parseField(name)
    of xmlElementOpen:
      dump x.elementName
      inc depth
      openedElementName = x.elementName.some
    of xmlElementEnd:
      dump x.elementName
      dec depth
    of xmlElementClose:
      if openedElementName.isSome:
        let name = openedElementName.get
        openedElementName = string.none
        parseField(name)
    of xmlAttribute:
      dump (x.attrKey, x.attrValue)
    of xmlEntity:
      dump x.entityName
    of xmlWhitespace, xmlComment, xmlPI, xmlSpecial:
      discard

proc fromXml*(t: typedesc; x: var XmlParser): t =
  parseHook(t, x)

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
      metadata: Metadata
      repository: seq[Repository]
      dependencies: Dependencies
    Metadata = object
      author: string
      version: string
    Repository = object
      name: string
      url: string
    Dependencies = object
      dependency: seq[Dependency]
    Dependency = object
      name: string
      version: string

  const Xml = """
<root myrootattr="hello">
  <metadata>
    <author>Jimmy</author>
    <version>0.1.2</version>
  </metadata>
  <repository>
    <name>First Repository</name>
    <url>https://example.com</url>
  </repository>
  <repository>
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
