require 'uri'
require 'net/http'
require 'json'
require 'reverse_markdown'
require 'nokogiri'

require_relative 'readability_js/version'
require_relative 'readability_js/nodo'
require_relative 'readability_js/extended'

require_relative 'custom_errors/error'

#
# ReadabilityJs
#

module ReadabilityJs

  #
  # Parse a HTML document and extract its main content using Mozilla's Readability library.
  #
  # 'html' is a required parameters, all others are optional.
  #
  # @param html [String] The HTML document as a string.
  # @param url [String, nil] The URL of the document (optional, used for resolving relative links).
  # @param debug [Boolean] Enable debug mode (default: false).
  # @param max_elems_to_parse [Integer] Maximum number of elements to parse (default: 0, meaning no limit).
  # @param nb_top_candidates [Integer] Number of top candidates to consider (default: 5).
  # @param char_threshold [Integer] Minimum number of characters for an element to be considered (default: 500).
  # @param classes_to_preserve [Array<String>] List of CSS classes to preserve in the output (default: []).
  # @param keep_classes [Boolean] Whether to keep the original classes in the output (default: false).
  # @param disable_json_ld [Boolean] Disable JSON-LD parsing (default: false).
  # @param serializer [String, nil] Serializer to use for output (optional).
  # @param allow_video_regex [String, nil] Regular expression to allow video URLs (optional).
  # @param link_density_modifier [Float] Modifier for link density calculation (default: 0).
  # @return [Hash] A hash containing the extracted content and metadata.
  #
  # @raise [ReadabilityJs::Error] if an error occurs during execution
  #
  def self.parse(html, url: nil, debug: false, max_elems_to_parse: 0, nb_top_candidates: 5, char_threshold: 500, classes_to_preserve: [], keep_classes: false, disable_json_ld: false, serializer: nil, allow_video_regex: nil, link_density_modifier: 0)
    begin
      result = ReadabilityJs::Nodo.parse(html, url: url, debug: debug, max_elems_to_parse: max_elems_to_parse, nb_top_candidates: nb_top_candidates, char_threshold: char_threshold, classes_to_preserve: classes_to_preserve, keep_classes: keep_classes, disable_json_ld: disable_json_ld, serializer: serializer, allow_video_regex: allow_video_regex, link_density_modifier: link_density_modifier)
      normalize_result(result)
    rescue => e
      raise ReadabilityJs::Error.new e.message
    end
  end

  #
  # Like #parse but with additional pre- and post-processing to enhance content extraction.
  #
  # 'html' is a required parameters, all others are optional.
  #
  # @param html [String] The HTML document as a string.
  # @param url [String, nil] The URL of the document (optional, used for resolving relative links).
  # @param debug [Boolean] Enable debug mode (default: false).
  # @param max_elems_to_parse [Integer] Maximum number of elements to parse (default: 0, meaning no limit).
  # @param nb_top_candidates [Integer] Number of top candidates to consider (default: 5).
  # @param char_threshold [Integer] Minimum number of characters for an element to be considered (default: 500).
  # @param classes_to_preserve [Array<String>] List of CSS classes to preserve in the output (default: []).
  # @param keep_classes [Boolean] Whether to keep the original classes in the output (default: false).
  # @param disable_json_ld [Boolean] Disable JSON-LD parsing (default: false).
  # @param serializer [String, nil] Serializer to use for output (optional).
  # @param allow_video_regex [String, nil] Regular expression to allow video URLs (optional).
  # @param link_density_modifier [Float] Modifier for link density calculation (default: 0).
  # @param blacklist_selectors [Array<String>] List of CSS selectors to remove from the HTML before parsing (default: []).
  # @return [Hash] A hash containing the extracted content and metadata.
  #
  # @raise [ReadabilityJs::Error] if an error occurs during execution
  #
  def self.parse_extended(html, url: nil, debug: false, max_elems_to_parse: 0, nb_top_candidates: 5, char_threshold: 500, classes_to_preserve: [], keep_classes: false, disable_json_ld: false, serializer: nil, allow_video_regex: nil, link_density_modifier: 0, blacklist_selectors: [])
    result = Extended::before_cleanup html, blacklist_selectors: blacklist_selectors
    result = parse result, url: url, debug: debug, max_elems_to_parse: max_elems_to_parse, nb_top_candidates: nb_top_candidates, char_threshold: char_threshold, classes_to_preserve: classes_to_preserve, keep_classes: keep_classes, disable_json_ld: disable_json_ld, serializer: serializer, allow_video_regex: allow_video_regex, link_density_modifier: link_density_modifier
    Extended::after_cleanup result, html
  end

  #
  # Decides whether a document is probably readerable without parsing the whole document.
  #
  # Only 'html' is a required parameter, all others are optional.
  #
  # @param html [String] The HTML document as a string.
  # @param min_content_length [Integer] Minimum content length to consider the document readerable
  # @param min_score [Integer] Minimum score to consider the document readerable
  # @param visibility_checker [String] anonymous JavaScript function definition to check node visibility as string. Uses default visibility checker if not provided.
  # @return [Boolean] true if the document is probably readerable, false otherwise.
  #
  # @raise [ReadabilityJs::Error] if an error occurs during execution
  #
  # @example
  #
  # html = "<html>...</html>"
  #
  # visibility_checker = <<~JS
  #   (node) => {
  #    const style = node.ownerDocument.defaultView.getComputedStyle(node);
  #    return (style && style.display !== 'none' && style.visibility !== 'hidden' && parseFloat(style.opacity) > 0);
  #   }
  # JS
  #
  # ReadabilityJs.is_probably_readerable(html, min_content_length: 200, min_score: 25, visibility_checker: visibility_checker)
  #
  def self.is_probably_readerable(html, min_content_length: 140, min_score: 20, visibility_checker: nil)
    begin
      ReadabilityJs::Nodo.is_probably_readerable(html, min_content_length: min_content_length, min_score: min_score, visibility_checker: visibility_checker)
    rescue => e
      raise ReadabilityJs::Error.new e.message
    end
  end


  #
  # Decides whether a document is probably readerable without parsing the whole document.
  #
  # Only 'html' is a required parameter, all others are optional.
  #
  # @param html [String] The HTML document as a string.
  # @param min_content_length [Integer] Minimum content length to consider the document readerable
  # @param min_score [Integer] Minimum score to consider the document readerable
  # @param visibility_checker [String] anonymous JavaScript function definition to check node visibility as string. Uses default visibility checker if not provided.
  # @return [Boolean] true if the document is probably readerable, false otherwise.
  #
  # @raise [ReadabilityJs::Error] if an error occurs during execution
  #
  # @example
  #
  # html = "<html>...</html>"
  #
  # visibility_checker = <<~JS
  #   (node) => {
  #    const style = node.ownerDocument.defaultView.getComputedStyle(node);
  #    return (style && style.display !== 'none' && style.visibility !== 'hidden' && parseFloat(style.opacity) > 0);
  #   }
  # JS
  #
  # ReadabilityJs.probably_readerable?(html, min_content_length: 200, min_score: 25, visibility_checker: visibility_checker)
  #
  def self.probably_readerable?(html, min_content_length: 140, min_score: 20, visibility_checker: nil)
    self.is_probably_readerable(html, min_content_length: min_content_length, min_score: min_score, visibility_checker: visibility_checker)
  end

  private

  #
  # Normalize result keys to snake_case for ruby style
  #
  # @param result [Hash] The result hash from Readability
  # @return [Hash] The normalized result hash
  #
  def self.normalize_result(result)
    result["text_content"] = result.delete("textContent") if result.key?("textContent")
    result["site_name"] = result.delete("siteName") if result.key?("siteName")
    result["published_time"] = result.delete("publishedTime") if result.key?("publishedTime")
    result
  end


end
