require "spec_helper"
require "tempfile"

require_relative '../lib/readability_js'

RSpec.describe ReadabilityJs do
  it "has a version number" do
    expect(ReadabilityJs::VERSION).not_to be nil
  end
end

RSpec.describe ReadabilityJs, '#parse' do
  context 'can parse valid documents' do
    it 'can parse examples' do
      source_files_path = File.expand_path(File.dirname(__FILE__)) + '/examples/*.html'
      source_files = Dir.glob(source_files_path)
      source_files.each do |source_file|
        html = File.read(source_file)
        parsed = ReadabilityJs.parse_extended(html)
        expect(parsed).to be_a(Hash)
        puts parsed.keys
        puts "title: #{parsed['title'][0..512]}"
        puts "byline: #{parsed['byline']}"
        puts "dir: #{parsed['dir']}"
        puts "lang: #{parsed['lang']}"
        puts "length: #{parsed['length']}"
        puts "excerpt: #{parsed['excerpt'][0..512]}"
        puts "site_name: #{parsed['site_name']}"
        puts "published_time: #{parsed['published_time']}"
        puts "image_url: #{parsed['image_url']}"
        File.write("tmp/" + File.basename(source_file,".html") + ".md", parsed['markdown_content'])
        File.write("tmp/" + File.basename(source_file,".html") + ".html", parsed['content'])
        File.write("tmp/" + File.basename(source_file,".html") + ".txt", parsed['text_content'])
      end
    end
  end
end


RSpec.describe ReadabilityJs, '#is_probably_readerable' do
  context 'can check documents' do
    it 'can acknowledge valid examples' do
      source_files_path = File.expand_path(File.dirname(__FILE__)) + '/examples/*.html'
      source_files = Dir.glob(source_files_path)
      source_files.each do |source_file|
        html = File.read(source_file)
        readerable = ReadabilityJs.is_probably_readerable(html)
        expect(readerable).to be(true)
      end
    end
    it 'can acknowledge short example' do
      example_path = File.expand_path(File.dirname(__FILE__)) + '/examples/short/golem.html'
      example = File.read(example_path)
      readerable = ReadabilityJs.is_probably_readerable(example)
      expect(readerable).to be(true)
    end
    it 'can acknowledge micro example because of parameters' do
      example = "<html><head><title>Test</title></head><body><article><h1>Micro Article</h1><p>This is a micro article with very little content.</p></article></body></html>"
      readerable = ReadabilityJs.is_probably_readerable(example, min_content_length: 10, min_score: 5)
      expect(readerable).to be(true)
    end
    it 'can not acknowledge micro example because of parametesr' do
      example = "<html><head><title>Test</title></head><body><article><h1>Micro Article</h1><p>This is a micro article with very little content.</p></article></body></html>"
      readerable = ReadabilityJs.is_probably_readerable(example, min_content_length: 1000, min_score: 5)
      expect(readerable).to be(false)
    end
    it 'can not acknowledge micro example because of parametesr' do
      example = "<html><head><title>Test</title></head><body><article><h1>Micro Article</h1><p>This is a micro article with very little content.</p></article></body></html>"
      readerable = ReadabilityJs.is_probably_readerable(example, min_content_length: 10, min_score: 95)
      expect(readerable).to be(false)
    end
    it 'can not acknowledge short example by parameters' do
      invalid_example_path = File.expand_path(File.dirname(__FILE__)) + '/examples/short/golem.html'
      invalid_example = File.read(invalid_example_path)
      readerable = ReadabilityJs.is_probably_readerable(invalid_example, min_content_length: 100000, min_score: 100)
      expect(readerable).to be(false)
    end
    it 'can use visibility checker to not recognize valid examples' do
      # this visibility checker makes all nodes invisible
      visibility_checker = <<~JS
        (node) => {
         return false;
        }
      JS
      source_files_path = File.expand_path(File.dirname(__FILE__)) + '/examples/*.html'
      source_files = Dir.glob(source_files_path)
      source_files.each do |source_file|
        html = File.read(source_file)
        readerable = ReadabilityJs.is_probably_readerable(html, visibility_checker: visibility_checker)
        expect(readerable).to be(false)
      end
    end
  end
end
