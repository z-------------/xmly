import pkg/xmly
import std/[
  options,
  unittest,
]

test "basic":
  type
    Document = object
      root: Root
    Root = object
      myRootAttr {.attr, name: "rootattr".}: string
      metadata: Metadata
      repository: seq[Repository]
      dependencies: Dependencies
    Metadata = object
      author: string
      version: string
      someNumber: int
      someFloat {.name: "magic".}: float
    Repository = object
      name: string
      url: string
      optional {.attr.}: bool = true
    Dependencies = object
      dependency: seq[Dependency]
    Dependency = object
      name: string
      version: Option[string]

  const Xml = """
<root rootattr="hello">
  <metadata>
    <somenumber>42</somenumber>
    <author>Jimmy<ftw>huh</ftw></author>
    <version>0.1.2<wtf>yes</wtf></version>
    <magic>3.14</magic>
  </metadata>
  <repository>
    <name>First Repository</name>
    <url>https://example.com</url>
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
  <repository optional="false">
    <name>Second Repository</name>
    <url>https://example.org</url>
  </repository>
</root>
  """
  let expected = Document(
    root: Root(
      myRootAttr: "hello",
      metadata: Metadata(
        author: "Jimmy",
        version: "0.1.2",
        someNumber: 42,
        someFloat: 3.14,
      ),
      repository: @[
        Repository(
          name: "First Repository",
          url: "https://example.com",
          optional: true,
        ),
        Repository(
          name: "Second Repository",
          url: "https://example.org",
          optional: false,
        ),
      ],
      dependencies: Dependencies(
        dependency: @[
          Dependency(
            name: "myfirstdep",
            version: none(string),
          ),
          Dependency(
            name: "myseconddep",
            version: some("^1.2.4"),
          ),
        ],
      ),
    ),
  )
  let parsed = Document.fromXml(Xml)
  check parsed == expected

test "self-closing tag":
  type
    Document = object
      root: Root
    Root = object
      self: seq[Self]
      nested: Nested
    Self = object
      closing {.attr.}: string
    Nested = object
      self: Self
      with: string

  const Xml = """
<root>
  <self closing="tag"/>
  <nested>
    <self closing="another"/>
    <with>a sibling</with>
  </nested>
  <self closing="and an uncle"/>
</root>
  """
  let expected = Document(
    root: Root(
      self: @[
        Self(closing: "tag"),
        Self(closing: "and an uncle"),
      ],
      nested: Nested(
        self: Self(closing: "another"),
        with: "a sibling",
      ),
    ),
  )
  let parsed = Document.fromXml(Xml)
  check parsed == expected
