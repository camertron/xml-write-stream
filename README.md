xml-write-stream
=================

[![Build Status](https://travis-ci.org/camertron/xml-write-stream.svg?branch=master)](http://travis-ci.org/camertron/xml-write-stream)

An easy, streaming way to generate XML.

## Installation

`gem install xml-write-stream`

## Usage

```ruby
require 'xml-write-stream'
```

### Examples for the Impatient

There are two types of XML write stream: one that uses blocks and `yield` to write tags, and one that's purely stateful. Here are two examples that produce the same output:

Yielding:

```ruby
stream = StringIO.new
XmlWriteStream.from_stream(stream) do |writer|
  writer.open_tag('foo', bar: 'baz') do |foo_writer|
    foo_writer.open_tag('no-text')
    foo_writer.write_text('blarg')
  end
end
```

Stateful:

```ruby
stream = StringIO.new
writer = XmlWriteStream.from_stream(stream)
writer.open_tag('foo', bar: 'baz')
writer.open_tag('no-text')
writer.close_tag
writer.write_text('blarg')
writer.close  # automatically adds closing tags for all unclosed tags
```

Output:

```ruby
stream.string # => <foo bar="baz"><no-text/>blarg</foo>
```

### Yielding Writers

As far as yielding writers go, the example above contains everything you need. The stream will be automatically closed when the outermost block terminates.

### Stateful Writers

Stateful writers have a number of additional methods:

```ruby
stream = StringIO.new
writer = XmlWriteStream.from_stream(stream)
writer.open_tag('foo')

writer.eos?             # => false, the stream is open and the outermost tag hasn't been closed yet

writer.open_tag         # explicitly close the current tag
writer.eos?             # => true, the outermost tag has been closed

writer.open_tag('foo')  # => raises XmlWriteStream::EndOfStreamError

writer.closed?          # => false, the stream is still open
writer.close            # close the stream
writer.closed?          # => true, the stream has been closed
```

### Writing to a File

XmlWriteStream also supports streaming to a file via the `open` method:

Yielding:

```ruby
XmlWriteStream.open('path/to/file.xml') do |writer|
  writer.open_tag('foo') do |foo_writer|
    ...
  end
end
```

Stateful:

```ruby
writer = XmlWriteStream.open('path/to/file.xml')
writer.open_tag('foo')
...
writer.close
```

## Requirements

No external requirements.

## Running Tests

`bundle exec rake` should do the trick. Alternatively you can run `bundle exec rspec`, which does the same thing.

## Authors

* Cameron C. Dutro: http://github.com/camertron
