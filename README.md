# ReadabilityJS for Ruby
![Gem](https://img.shields.io/gem/v/readability_js?color=default&style=plastic&logo=ruby&logoColor=red)
![Gem](https://img.shields.io/gem/dt/readability_js?color=blue&style=plastic)
[![License: MIT](https://img.shields.io/badge/License-MIT-gold.svg?style=plastic&logo=mit)](LICENSE)

> Clean up web pages and extract the main content from ruby, powered by Mozilla Readability.

This is a Ruby wrapper gem for [readability](https://github.com/mozilla/readability), by running a node process with [nodo](https://github.com/mtgrosser/nodo).



# Contents

* [Installation](#installation)
* [Usage examples](#usage)
* [Documentation](#documentation)
* [Contributing](#contributing)



<a name="installation"></a>
## Installation
### Prerequisites
NodeJS >= 22.x is installed and available via commandline (in PATH).


### Gem

Add this line to your application's Gemfile:

```ruby
gem 'readability_js'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install readability_js


<a name="usage"></a>
## Usage examples


### Original parse

Using this method, only the mozilla readability parse method is called.

```ruby
    require 'readability_js'
    html = File.read("my_article.html")
    result = ReadabilityJs.parse(html)
    p result
```

### Extended parse

Using this method, the extended parse method is called, which provides more cleaned up output,
and includes a beautified markdown version of the content.

```ruby
    require 'readability_js'
    html = File.read("my_article.html")
    result = ReadabilityJs.parse_extended(html)
    p result
```

### Query parameters
You can pass all parameters supported by readability, checkout the [rubydoc for more details](https://www.rubydoc.info/gems/readability_js/ReadabilityJs).

Here an example with all parameters, the camelCase parameters are converted to snake_case in ruby:

```ruby
    require 'readability_js'
data = ReadabilityJs.parse(
  # TODO: add parameters here
)
# => Hash
```

### Query response
The response object is of type `Hash`.
It contains the data returned by readability, with hash keys transformed in snake_case.

```ruby
{
  "title" => "Article Title",
  "byline" => "Author Name",
  "dir" => "ltr",
  "content" => "<div>...</div>",
  "text_content" => "Plain text content",
  "markdown_content" => "## Markdown content", # only for extended parse
  "length" => 1234,
  "excerpt" => "This is an excerpt of the article...",
  "site_name" => "example.com",
}    
```

<a name="documentation"></a>
## Documentation
Check out the doc at RubyDoc:<br>
https://www.rubydoc.info/gems/readability_js


As this library is only a wrapper, checkout the original readability documentation:<br>
https://github.com/mozilla/readability


<a name="contributing"></a>
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/magynhard/ruby-readability_js.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
