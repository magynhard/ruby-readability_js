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
    it 'can parse BILD example' do
      source_file = File.expand_path(File.dirname(__FILE__)) + '/examples/wdr.html'
      html = File.read(source_file)
      parsed = ReadabilityJs.parse_extended(html)
      expect(parsed).to be_a(Hash)
      puts parsed.keys
      puts "title: #{parsed['title'][0..64]}"
      puts "byline: #{parsed['byline']}"
      puts "dir: #{parsed['dir']}"
      puts "lang: #{parsed['lang']}"
      puts "content: \n#{parsed['content'][0..256]}\n\n"
      puts "markdown_content: \n#{parsed['markdown_content'][0..5120]}\n\n" if parsed['markdown_content']
      #      puts "nokogiri_content: \n#{parsed['nokogiri_content'][0..5120]}\n\n"
      puts "text_content: \n#{parsed['text_content'][0..256]}\n\n"
      puts "length: #{parsed['length']}"
      puts "excerpt: #{parsed['excerpt'][0..128]}"
      puts "site_name: #{parsed['site_name']}"
      puts "published_time: #{parsed['published_time']}"
      File.write("tmp/" + File.basename(source_file,".html") + ".md", parsed['markdown_content'])
      File.write("tmp/" + File.basename(source_file,".html") + ".html", parsed['content'])
      File.write("tmp/" + File.basename(source_file,".html") + ".txt", parsed['text_content'])
    end
  end
end
