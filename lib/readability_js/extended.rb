
module ReadabilityJs
  class Extended

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
      "[width='1'][height='1']",
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
      "ws-adtag",
      # taz
      "[data-for='webelement_bio']",
      "[data-for='webelement_citation']",
      "#articleTeaser",
      ".article-produktteaser-container",
      "[x-data='{}']",
      "#komune",
      ".community",
    ]

    def self.before_cleanup(html)
      pre_parser html
    end

    def self.after_cleanup(result, html)
      find_and_add_picture result, html
      clean_up_and_enrich_result result
    end

    private

    #
    # Pre-parser to clean up HTML before passing it to Readability
    #
    # SELECTOR_BLACKLIST contains CSS selectors of elements to be removed from the HTML
    # before parsing to improve content extraction.
    #
    # @param html [String] The HTML document as a string.
    # @return [String] The cleaned HTML document as a string.
    #
    def self.pre_parser(html)
      doc = Nokogiri::HTML(html)
      # Remove blacklisted elements by selector
      SELECTOR_BLACKLIST.each do |classname|
        doc.css("#{classname}").remove
      end
      doc.to_html
    end

    #
    # Post-parser to find and add lead image URL if missing.
    #
    # Will add a picture into the result hash under the key "image_url".
    #
    # Looks for Open Graph and Twitter Card meta tags to find a lead image URL.
    # If not found, it will have a look into the markdown content for the first image.
    #
    # @param result [Hash] The result hash from Readability parsing.
    # @param html [String] The original HTML document as a string.
    # @return [Hash] The updated result hash.
    #
    def self.find_and_add_picture(result, html)
      return result if result.key?("lead_image_url") && !result["lead_image_url"].to_s.strip.empty?
      doc = Nokogiri::HTML(html)
      # try to find og:image or twitter:image meta tags
      meta_tags = doc.css('meta[property="og:image"], meta[name="og:image"], meta[name="twitter:image"]')
      meta_tags.each do |meta_tag|
        content = meta_tag['content']
        if content && !content.strip.empty?
          result["image_url"] = content.strip
          break
        end
      end
      # try to find first image in markdown content if no meta tag found before
      if !result.key?("image_url") || result["image_url"].to_s.strip.empty?
        if result.key?("markdown_content")
          md_content = result["markdown_content"]
          md_content.scan(/!\[.*?\]\((.*?)\)/).each do |match|
            img_url = match[0]
            if img_url && !img_url.strip.empty?
              # check if img ends with common image file extensions
              if img_url =~ /\.(jpg|jpeg|png|gif|webp|svg|tif|avif)(\?.*)?$/i
                result["image_url"] = img_url.strip
                break
              end
            end
          end
        end
      end
      result
    end

    #
    # Post-parser to clean up extracted content after Readability processing
    #
    # Cleans up comment artifacts and beautifies HTML and adds beautified Markdown content.
    #
    # @param result [Hash] The result hash from Readability parsing.
    # @return [Hash] The cleaned result hash.
    #
    def self.clean_up_and_enrich_result(result)
      result["content"] = clean_up_comments(result["content"]) if result.key?("content")
      result["text_content"] = clean_up_comments(result["text_content"]) if result.key?("text_content")
      result["excerpt"] = clean_up_comments(result["excerpt"]) if result.key?("excerpt")
      result["byline"] = clean_up_comments(result["byline"]) if result.key?("byline")
      if result.key?("content")
        result = beautify_html_and_text(result)
        result["markdown_content"] = ReverseMarkdown.convert(result["content"]) if result.key?("content")
        result = beautify_markdown(result)
      end
      result
    end

    #
    # Remove/replace comment / artifact noise like <!--[--&gt;, <!----&gt; etc.
    #
    # @param html [String] The HTML content as a string.
    # @return [String] The cleaned HTML content as a string.
    #
    def self.clean_up_comments(html)
      copy = html.dup || ""
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

    #
    # Beautify Markdown content by adding title if not present and fixing link spacing
    #
    # @param result [Hash] The result hash from Readability parsing.
    # @return [Hash] The beautified result hash.
    #
    def self.beautify_markdown(result)
      mark_down = result["markdown_content"]
      # add title to markdown if not present
      if !mark_down.start_with?("# ") && result.key?("title") && !result["title"].to_s.strip.empty? && !mark_down.include?(result["title"])
        mark_down = "# #{result['title']}\n\n" + mark_down
      end
      # Check for image and if none is found, add after title if available
      if result.key?("image_url") && !result["image_url"].to_s.strip.empty?
        has_image = mark_down.match(/!\[.*?\]\(.*?\)/) || mark_down.match(/<img\b[^>]*>/) || mark_down.match(/<picture\b[^>]*>.*?<\/picture>/m)
        if !has_image
          img_md = "![image](#{result['image_url']})\n\n"
          mark_down = mark_down.sub(/^# .+?\n/, "\\0" + img_md)
        end
      end
      # Add a space after markdown links if immediately followed by an alphanumeric char (missing separation).
      mark_down.gsub!(/(\[[^\]]+\]\((?:[^\)"']+|"[^"]*"|'[^']*')*\))(?=[A-Za-z0-9ÄÖÜäöüß])/, '\1 ')
      result["markdown_content"] = mark_down
      result
    end

    #
    # Beautify HTML content by adding title if not present and fixing link spacing
    #
    # @param result [Hash] The result hash from Readability parsing.
    # @return [String] The beautified HTML content as a string.
    #
    def self.beautify_html_and_text(result)
      html = result["content"]
      text = result["text_content"]
      # Add title to html and text if not present
      if (html.index(/h[1-2]/) && html.index(/h[1-2]/).to_i > 128 && result.key?("title") && !result["title"].to_s.strip.empty? && !html.include?(result["title"])) || html.index(/h[1-2]/).nil?
        title_tag = "<h1>#{result['title']}</h1>\n"
        html = title_tag + html
        text = result['title'] + "\n\n" + text
      end
      # Check for image and if none is found, add after title if available
      if result.key?("image_url") && !result["image_url"].to_s.strip.empty?
        doc = Nokogiri::HTML(html)
        # check for img tags but also for picture tags
        has_image = !doc.css('img, picture').empty?
        if !has_image
          img_tag = "<p><img src=\"#{result['image_url']}\"></p>\n"
          h1 = doc.at_css('h1')
          if h1
            h1.add_next_sibling(Nokogiri::HTML::DocumentFragment.parse(img_tag))
            html = doc.to_html
          end
        end
      end
      # Add a space after a links if immediately followed by an alphanumeric char (missing separation).
      doc = Nokogiri::HTML(html)
      doc.css('a').each do |link|
        next if link.next_sibling.nil?
        if link.next_sibling.text? && link.next_sibling.content =~ /\A[A-Za-z0-9ÄÖÜäöüß]/
          link.add_next_sibling(Nokogiri::XML::Text.new(' ', doc))
        end
      end
      result["content"] = doc.to_html
      result["text_content"] = text
      result
    end
  end
end