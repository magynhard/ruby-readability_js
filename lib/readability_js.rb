require 'uri'
require 'net/http'
require 'json'
require 'reverse_markdown'
require 'nokogiri'

require_relative 'readability_js/version'
require_relative 'readability_js/nodo'

require_relative 'custom_errors/error'

#
# ReadabilityJs
#

module ReadabilityJs

  SELECTOR_BLACKLIST = [
    ".Article-Partner",
    ".Article-Partner-Text",
    ".Article-Comments-Button",
    "#isl-5-AdCarousel",
    "#isl-10-ArticleComments",
    "*[data-element-tracking-name]",
    "*[aria-label='Anzeige']",
    "nav[aria-label='breadcrumb']",
    # heise
    "a-video",
    "a-gift",
    "a-collapse",
    "a-opt-in",
    # spiegel
    "[data-area='related_articles']",
    # welt
    "nav[aria-label='Breadcrumb']",
    ".c-inline-teaser-list",
    # golem
    ".go-alink-list",
    # faz
    "[data-external-selector='related-articles-entries']",
    ".BigBox",
    # frankfurter rundschau
    ".id-Breadcrumb-item",
    ".id-Story-interactionBar",
    "revenue-reel",
    ".id-StoryElement-factBox",
    # stern
    ".breadcrumb",
    ".teaser",
    ".group-teaserblock__items",
    ".title__kicker",
    # taz
    "[data-for='webelement_bio']",
    "[data-for='webelement_citation']",
    "#articleTeaser",
    ".article-produktteaser-container",
    "[x-data='{}']",
    "#komune",
    ".community",
  ]

  #
  # Parse a HTML document and extract its main content using Mozilla's Readability library.
  # Raises ReadabilityJs::Error on failure.
  #
  # 'html' is a required parameters, all others are optional.
  #
  def self.parse(html, url: nil, debug: false, max_elems_to_parse: 0, nb_top_candidates: 5, char_threshold: 500, classes_to_preserve: [], keep_classes: false, disable_json_ld: false, serializer: nil, allow_video_regex: nil, link_density_modifier: 0)
    begin
      result = ReadabilityJs::Nodo.parse(html, url: url, debug: debug, max_elems_to_parse: max_elems_to_parse, nb_top_candidates: nb_top_candidates, char_threshold: char_threshold, classes_to_preserve: classes_to_preserve, keep_classes: keep_classes, disable_json_ld: disable_json_ld, serializer: serializer, allow_video_regex: allow_video_regex, link_density_modifier: link_density_modifier)
      normalize_result(result)
    rescue => e
      raise ReadabilityJs::Error.new e.message
    end
  end

  def self.parse_extended(html, url: nil, debug: false, max_elems_to_parse: 0, nb_top_candidates: 5, char_threshold: 500, classes_to_preserve: [], keep_classes: false, disable_json_ld: false, serializer: nil, allow_video_regex: nil, link_density_modifier: 0)
    result = pre_parser html
    result = parse result, url: url, debug: debug, max_elems_to_parse: max_elems_to_parse, nb_top_candidates: nb_top_candidates, char_threshold: char_threshold, classes_to_preserve: classes_to_preserve, keep_classes: keep_classes, disable_json_ld: disable_json_ld, serializer: serializer, allow_video_regex: allow_video_regex, link_density_modifier: link_density_modifier
    clean_up_result result
  end

  def self.is_probably_readerable(html, min_content_length: 140, min_score: 20, visibility_checker: 'isNodeVisible')
    begin
      ReadabilityJs::Nodo.is_probably_readerable(html, min_content_length: min_content_length, min_score: min_score, visibility_checker: visibility_checker)
    rescue => e
      raise ReadabilityJs::Error.new e.message
    end
  end

  def self.probably_readerable?(html)
    self.is_probably_readerable(html)
  end

  private

  def self.normalize_result(result)
    result["text_content"] = result.delete("textContent") if result.key?("textContent")
    result["site_name"] = result.delete("siteName") if result.key?("siteName")
    result["published_time"] = result.delete("publishedTime") if result.key?("publishedTime")
    result
  end

  def self.clean_up_result(result)
    result["content"] = clean_up_comments(result["content"]) if result.key?("content")
    result["text_content"] = clean_up_comments(result["text_content"]) if result.key?("text_content")
    result["excerpt"] = clean_up_comments(result["excerpt"]) if result.key?("excerpt")
    result["byline"] = clean_up_comments(result["byline"]) if result.key?("byline")
    if result.key?("content")
      result["content"] = beautify_html(result["content"])
      result["markdown_content"] = ReverseMarkdown.convert(result["content"]) if result.key?("content")
      result = beautify_markdown(result)
    end
    result
  end

  # Replaces comment / artifact noise like <!--[--&gt;, <!----&gt; etc.
  def self.clean_up_comments(html)
    copy = html.dup

    # Turn \x3C before comment start into '<'
    copy.gsub!(/\\x3C(?=!--)/, '<')

    # Decode encoded comment end --&gt; to -->
    copy.gsub!(/--&gt;/, '-->')

    # Remove fully empty or artifact comments ([], only whitespace)
    copy.gsub!(/<!--\s*(?:\[|\]|)*\s*-->/, '')

    # Collapse multiple dummy comment chains
    copy.gsub!(/(?:<!--\s*-->\s*)+/, '')

    # Remove remaining comment artifacts like <!--[-->, <!--]-->
    copy.gsub!(/<!--\[\]-->|<!--\[\s*-->|<!--\]\s*-->/, '')

    # Remove any remaining regular comments
    copy.gsub!(/<!--.*?-->/m, '')

    # Reduce excessive whitespace / blank lines (real newlines)
    copy.gsub!(/\n[ \t]+\n/, "\n")
    copy.gsub!(/\n{3,}/, "\n\n")

    # Remove any remaining script tags (including encoded variants)
    copy.gsub!(/(?:\\x3C|<)script\b[^>]*?(?:>|\\x3E|&gt;).*?(?:\\x3C|<)\/script(?:>|\\x3E|&gt;)/im, '')

    # Preserve blocks where whitespace/newlines matter
    preserve_tags = %w[pre code textarea]
    preserved = {}
    preserve_tags.each_with_index do |tag, idx|
      copy.scan(/<#{tag}[^>]*?>.*?<\/#{tag}>/mi).each do |block|
        key = "__PRESERVE_BLOCK_#{tag.upcase}_#{idx}_#{preserved.size}__"
        preserved[key] = block
        copy.sub!(block, key)
      end
    end

    # Remove literal backslash+n sequences (if they exist as textual artifacts) outside preserved blocks
    copy.gsub!(/\\n\s*/, ' ')

    # Collapse whitespace between tags to a single space or nothing
    # Remove whitespace-only text nodes represented by spaces/newlines between tags
    copy.gsub!(/>\s+</, '><')

    # Normalize multiple spaces to a single space
    copy.gsub!(/ {2,}/, ' ')

    # Trim spaces directly inside tags (e.g., <p> text </p>)
    copy.gsub!(/>\s+([^<])/) { ">#{$1}" }

    # Restore preserved blocks
    preserved.each { |k, v| copy.sub!(k, v) }
    copy.strip
  end

  def self.beautify_markdown(result)
    mark_down = result["markdown_content"]
    # add title to markdown if not present
    if !mark_down.start_with?("# ") && result.key?("title") && !result["title"].to_s.strip.empty? && !mark_down.include?(result["title"])
      mark_down = "# #{result['title']}\n\n" + mark_down
    end
    # Add a space after markdown links if immediately followed by an alphanumeric char (missing separation).
    mark_down.gsub!(/(\[[^\]]+\]\((?:[^\)"']+|"[^"]*"|'[^']*')*\))(?=[A-Za-z0-9ÄÖÜäöüß])/, '\1 ')
    result["markdown_content"] = mark_down
    result
  end

  def self.beautify_html(html)
    doc = Nokogiri::HTML(html)
    # Add a space after a links if immediately followed by an alphanumeric char (missing separation).
    doc.css('a').each do |link|
      next if link.next_sibling.nil?
      if link.next_sibling.text? && link.next_sibling.content =~ /\A[A-Za-z0-9ÄÖÜäöüß]/
        link.add_next_sibling(Nokogiri::XML::Text.new(' ', doc))
      end
    end
    doc.to_html
  end

  def self.pre_parser(html)
    doc = Nokogiri::HTML(html)
    # Remove blacklisted classes
    SELECTOR_BLACKLIST.each do |classname|
      doc.css("#{classname}").remove
    end
    doc.to_html
  end

end
