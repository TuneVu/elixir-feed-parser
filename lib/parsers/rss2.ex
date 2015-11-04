defmodule ElixirFeedParser.Parsers.RSS2 do
  import ElixirFeedParser.Parsers.Helper
  alias ElixirFeedParser.XmlNode

  def can_parse?(xml) do
    xml
    |> XmlNode.find("/rss")
    |> XmlNode.attr("version") == "2.0"
  end

  def parse(xml) do
    feed = XmlNode.find(xml, "/rss/channel")

    link      = feed |> element("link")
    atom_link = feed |> element("atom:link[@rel='self']", [attr: "href"])
    url       = link || atom_link

    %{
      title:                 feed |> element("title"),
      description:           feed |> element("description"),
      url:                   url,
      hubs:                  hubs(feed),
      "atom:link":           atom_link,
      "rss2:link":           feed |> element("link"),
      language:              feed |> element("language"),
      copyright:             feed |> element("copyright"),
      "rss2:managingEditor": feed |> element("managingEditor"),
      "rss2:webMaster":      feed |> element("webMaster"),
      # TODO: also work with pubdate or publicationDate
      updated:               feed |> element("pubDate"),
      "rss2:pubDate":        feed |> element("pubDate"),
      "rss2:lastBuildDate":  feed |> element("lastBuildDate"),
      categories:            feed |> elements("category"),
      generator:             feed |> element("generator"),
      "rss2:ttl":            feed |> element("ttl"),
      # TODO: integer
      skip_hours:            feed |> elements("skipHours/hour"),
      "rss2:skipHours":      feed |> elements("skipHours/hour"),
      skip_days:             feed |> elements("skipDays/day"),
      "rss2:skipDays":       feed |> elements("skipDays/day"),

      image:                 feed |> XmlNode.find("image") |> parse_image,
      entries:               parse_entries(feed)
    }
  end

  defp hubs(feed) do
    case feed_burner_namespace?(feed) do
      true  -> feed |> elements("atom10:link[@rel='hub']", [attr: "href"])
      false -> [feed |> element("atom:link[@rel='self']", [attr: "href"])]
    end
  end

  def feed_burner_namespace?(feed) do
    XmlNode.namespaces(feed)["feedburner"] == "http://rssnamespace.org/feedburner/ext/1.0"
  end

  defp parse_image(nil), do: nil
  defp parse_image(image) do
    %{
      title:       image |> element("title"),
      link:        image |> element("link"),
      url:         image |> element("url"),
      width:       image |> element("width"),
      height:      image |> element("height"),
      description: image |> element("description")
    }
  end

  defp parse_entries(feed) do
    XmlNode.map_children(feed, "item", fn(e) -> parse_entry(feed, e) end)
  end

  defp parse_entry(feed, entry) do
    author     = entry |> element("author")
    dc_creator = entry |> element("dc:creator")

    %{
      title:          entry |> element("title"),
      url:            feed_entry_url(feed, entry),
      "rss2:link":    entry |> element("link"),
      description:    entry |> element("description"),
      author:         author || dc_creator,
      "rss2:dc:creator": entry |> element("dc:creator"),
      categories:     entry |> elements("category"),
      # support dc:identifier too
      id:             entry |> element("guid"),
      "rss2:guid":    entry |> element("guid"),
      comments:       entry |> element("comments"),
      # TODO: also work with pubdate or publicationDate, dc:date, dc:Date, dcterms:created
      updated:        entry |> element("pubDate"),
      "rss2:pubDate": entry |> element("pubDate"),
      source:         entry |> element("source", [attr: "url"]),
      content:        entry |> element("content:encoded"),
      enclosure:      entry |> XmlNode.find("enclosure") |> parse_enclosure
    }
  end

  defp feed_entry_url(feed, entry) do
    link = entry |> element("link")
    feed_burner_original_link = entry |> element("feedburner:origLink", [attr: "url"])

    case feed_burner_namespace?(feed) do
      true  -> feed_burner_original_link
      false -> link
    end
  end

  defp parse_enclosure(nil), do: nil
  defp parse_enclosure(enclosure) do
    %{
      url:    enclosure |> XmlNode.attr("url"),
      length: enclosure |> XmlNode.attr("length"),
      type:   enclosure |> XmlNode.attr("type")
    }
  end
end
