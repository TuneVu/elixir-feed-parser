defmodule XmlNodeTest do
  use ExUnit.Case

  alias ElixirFeedParser.XmlNode

  test "parsing an element with text" do
    sample_xml = "<title>test title</title>"
    xml = XmlNode.parse_string(sample_xml)
    assert XmlNode.find(xml, "/title") |> XmlNode.text == "test title"
  end

  test "parsing an element with colon name" do
    sample_xml = "<content:encoded>test title</content:encoded>"
    xml = XmlNode.parse_string(sample_xml)
    assert XmlNode.find(xml, "/content:encoded") |> XmlNode.text == "test title"
  end

  test "parsing an element with a CDATA section" do
    sample_xml = "<content><![CDATA[<div>Hello</div>]]></content>"
    xml = XmlNode.parse_string(sample_xml)
    assert XmlNode.find(xml, "/content") |> XmlNode.text == "<div>Hello</div>"
  end

  # TODO: implement me
  # test "parsing an element with html escaped text" do
  #   sample_xml = """
  #   <content type="html">&lt;em&gt;test&lt;/em&gt;</content>
  #   """
  #   xml = XmlNode.parse_string(sample_xml)
  #   assert "<em>test</em>" == XmlNode.find(xml, "/p") |> XmlNode.text
  # end

  test "parsing an element with single attribute" do
    sample_xml = """
    <content type="text">test</content>
    """
    xml = XmlNode.parse_string(sample_xml)
    assert XmlNode.find(xml, "/content") |> XmlNode.attr("type") == "text"
  end

  test "parsing nested elements" do
    sample_xml = """
    <feed xmlns="http://www.w3.org/2005/Atom">
      <author>
        <name>John Doe</name>
      </author>
    </feed>
    """
    xml = XmlNode.parse_string(sample_xml)
    assert XmlNode.find(xml, "/feed/author/name") |> XmlNode.text == "John Doe"
  end

  test "parsing xml namespace" do
    sample_xml = """
    <feed xmlns="http://www.w3.org/2005/Atom">
    </feed>
    """
    xml = XmlNode.parse_string(sample_xml)
    assert XmlNode.find(xml, "/feed") |> XmlNode.namespace() == "http://www.w3.org/2005/Atom"
  end

  test "parsing list of entry elements" do
    sample_xml = """
    <feed xmlns="http://www.w3.org/2005/Atom">
      <entry>
        <title>Example title 1</title>
      </entry>
      <entry>
        <title>Example title 2</title>
      </entry>
    </feed>
    """
    xml = XmlNode.parse_string(sample_xml)

    titles = XmlNode.map_children(xml, "entry/title", fn(e) -> XmlNode.text(e) end)
    assert titles == ["Example title 1", "Example title 2"]
  end

end
