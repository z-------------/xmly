import pkg/xmly
import std/[
  unittest,
]

test "it works":
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
      version: string

  const Xml = """
<root rootattr="hello">
  <metadata>
    <author>Jimmy<ftw>huh</ftw></author>
    <version>0.1.2<wtf>yes</wtf></version>
    <somenumber>42</somenumber>
    <magic>3.14</magic>
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
            version: "",
          ),
          Dependency(
            name: "myseconddep",
            version: "^1.2.4",
          ),
        ],
      ),
    ),
  )
  let parsed = Document.fromXml(Xml)
  check parsed == expected
