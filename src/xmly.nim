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
  options,
  parsexml,
  streams,
  strutils,
]

template attr*() {.pragma.}

template name*(name: string) {.pragma.}

template text*() {.pragma.}

func replace(s: string; subs: openArray[string]; by: string): string {.raises: [].} =
  result = s
  for sub in subs:
    result = result.replace(sub, by)

func eqName(a, b: string): bool =
  if a == b:
    true
  else:
    let
      aNorm = a.toLowerAscii.replace(["_", "-"], "")
      bNorm = b.toLowerAscii.replace(["_", "-"], "")
    aNorm == bNorm

template nameMatches(key: string; val: untyped; elName: string): bool =
  when val.hasCustomPragma(xmly.name):
    val.getCustomPragmaVal(xmly.name) == elName
  else:
    key.eqName(elName)

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
  dest = T(parseBiggestInt(s.strip))

proc parseHook(s: string; dest: var bool) {.raises: [ValueError].} =
  dest = parseBool(s.strip)

proc parseHook[T: SomeFloat](s: string; dest: var T) {.raises: [ValueError].} =
  dest = T(parseFloat(s.strip))

proc parseHook[T](s: string; dest: var Option[T]) =
  var val: T
  parseHook(s, val)
  dest = some(val)

proc parseXmlHook(x: var XmlParser; dest: var object)

template handleElementBegin(x: var XmlParser; dest: var object) =
  let elName = x.elementName
  let hasAttrs = x.kind == xmlElementOpen
  x.next()
  for key, val in dest.fieldPairs:
    if nameMatches(key, val, elName):
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
                if nameMatches(aKey, aVal, x.attrKey):
                  when aVal.hasCustomPragma(attr):
                    parseHook(x.attrValue, aVal)
                  break
          of xmlEof, xmlElementClose:
            break
          else:
            discard
          x.next()
      when compiles(parseHook("", item)):
        if x.kind == xmlCharData:
          parseHook(x.charData, item)
      else:
        parseXmlHook(x, item)
      when typeof(val) is seq:
        val.add(item)
      else:
        val = item
      break
  skipElement(x)

proc parseXmlHook(x: var XmlParser; dest: var object) =
  var depth = 1
  while true:
    case x.kind
    of xmlError:
      raiseXmlError(x)
    of xmlEof:
      break
    of xmlCharData:
      for key, val in dest.fieldPairs:
        when val.hasCustomPragma(text):
          when val is seq:
            var item = default(typeof(val[0]))
            parseHook(x.charData, item)
            val.add(item)
          else:
            parseHook(x.charData, val)
          break
    of xmlElementStart, xmlElementOpen:
      inc depth
      handleElementBegin(x, dest)
      continue
    of xmlElementEnd:
      dec depth
      if depth <= 0:
        break
    of xmlCData, xmlElementClose, xmlAttribute, xmlEntity, xmlWhitespace, xmlComment, xmlPI, xmlSpecial:
      discard
    x.next()

proc fromXml*(t: typedesc; x: var XmlParser): t =
  x.next()
  parseXmlHook(x, result)

proc fromXml*(t: typedesc; s: Stream): t =
  var x = XmlParser()
  x.open(s, filename = "")
  defer: x.close()
  fromXml(t, x)

proc fromXml*(t: typedesc; f: File): t =
  let stream = newFileStream(f)
  fromXml(t, stream)

proc fromXml*(t: typedesc; s: string): t =
  let stream = newStringStream(s)
  fromXml(t, stream)
