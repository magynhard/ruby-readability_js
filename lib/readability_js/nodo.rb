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
        self.new.parse html
      rescue ::Nodo::JavaScriptError => e
        raise ReadabilityJs::Error.new "#{e.message}"
      end
    end

    def self.is_probably_readerable(html, min_content_length: 140, min_score: 20, visibility_checker: 'isNodeVisible')
      begin
        self.new.is_probably_readerable html
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
      async (html) => {
        const doc = new jsdom.JSDOM(html);
        return readability.Readability.isProbablyReaderable(doc);
      }
    JS

  end
end