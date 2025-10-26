require "nodo"

node_js_app_base_path = File.expand_path(File.dirname(__FILE__) + '/node/')
Nodo.modules_root = node_js_app_base_path + '/node_modules'
Nodo.logger = Logger.new(nil) # disable logging

module ReadabilityJs
  class Nodo < Nodo::Core
    require readability: "@mozilla/readability"
    require jsdom: "jsdom"

    #
    # instance wrapper method, as nodo does not support class methods
    #
    def self.parse(html, url: nil, debug: false, max_elems_to_parse: 0, nb_top_candidates: 5, char_threshold: 500, classes_to_preserve: [], keep_classes: false, disable_json_ld: false, serializer: nil, allow_video_regex: nil, link_density_modifier: 0)
      begin
        # remove style tags from html, so jsdom does not need to process css and its warnings are not shown
        html = html.gsub(/<style[^>]*>.*?<\/style>/m, '')
        self.new.parse html, url, debug, max_elems_to_parse, nb_top_candidates, char_threshold, classes_to_preserve, keep_classes, disable_json_ld, serializer, allow_video_regex, link_density_modifier
      rescue ::Nodo::JavaScriptError => e
        raise ReadabilityJs::Error.new "#{e.message}"
      end
    end

    #
    # instance wrapper method, as nodo does not support class methods
    #
    def self.is_probably_readerable(html, min_content_length: 140, min_score: 20, visibility_checker: nil)
      begin
        # remove style tags from html, so jsdom does not need to process css and its warnings are not shown
        html = html.gsub(/<style[^>]*>.*?<\/style>/m, '')
        self.new.is_probably_readerable html, min_content_length, min_score, visibility_checker
      rescue ::Nodo::JavaScriptError => e
        raise ReadabilityJs::Error.new "#{e.message}"
      end
    end

    def self.probably_readerable(html)
      self.is_probably_readerable(html)
    end

    function :parse, <<~JS
      async (html, url, debug, maxElemsToParse, nbTopCandidates, charThreshold, classesToPreserve, keepClasses, disableJSONLD, serializer, allowVideoRegex, linkDensitiyModifier) => {
        let jsdom_options = {};
        if (url) {
          jsdom_options.url = url;
        }
        const doc = new jsdom.JSDOM(html, jsdom_options);
        
        let readability_options = {};
        if(debug !== undefined && debug !== null) readability_options.debug = debug;
        if(maxElemsToParse !== undefined && maxElemsToParse !== null) readability_options.maxElemsToParse = maxElemsToParse;
        if(nbTopCandidates !== undefined && nbTopCandidates !== null) readability_options.nbTopCandidates = nbTopCandidates;
        if(charThreshold !== undefined && charThreshold !== null) readability_options.charThreshold = charThreshold;
        if(classesToPreserve !== undefined && classesToPreserve !== null) readability_options.classesToPreserve = classesToPreserve;
        if(keepClasses !== undefined && keepClasses !== null) readability_options.keepClasses = keepClasses;
        if(disableJSONLD !== undefined && disableJSONLD !== null) readability_options.disableJSONLD = disableJSONLD;
        if(serializer !== undefined && serializer !== null) readability_options.serializer = serializer;
        if(allowVideoRegex !== undefined && allowVideoRegex !== null) readability_options.allowVideoRegex = allowVideoRegex;
        if(linkDensitiyModifier !== undefined && linkDensitiyModifier !== null) readability_options.linkDensitiyModifier = linkDensitiyModifier;
        const reader = new readability.Readability(doc.window.document, readability_options);
        return reader.parse();
      }
    JS

    function :is_probably_readerable, <<~JS
      async (html, minContentLength, minScore, visibilityChecker) => {
        const doc = new jsdom.JSDOM(html);
        
        let readability_options = {};
        if(minContentLength !== undefined && minContentLength !== null) readability_options.minContentLength = minContentLength;
        if(minScore !== undefined && minScore !== null) readability_options.minScore = minScore;
        if(visibilityChecker !== undefined && visibilityChecker !== null) {
          readability_options.visibilityChecker = eval(visibilityChecker);
        }
        return readability.isProbablyReaderable(doc.window.document, readability_options);
      }
    JS

  end
end