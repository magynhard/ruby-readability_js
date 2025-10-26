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
