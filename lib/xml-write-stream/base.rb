# encoding: UTF-8

class XmlWriteStream
  class Base
    DEFAULT_INDENT = 4

    # these are probably fairly incorrect, but good enough for now
    TAG_NAME_REGEX = /\A[a-zA-Z:_][\w.\-_:]*/
    ATTRIBUTE_KEY_REGEX = /\A[a-zA-Z_][\w\-_]*/

    TEXT_ESCAPE_CHARS = /["'<>&]/
    ATTRIBUTE_ESCAPE_CHARS = /["'<>&\n\r\t]/

    TEXT_ESCAPE_HASH = {
      '"' => '&quot;',
      "'" => '&apos;',
      '<' => '&lt;',
      '>' => '&gt;',
      '&' => '&amp;'
    }

    ATTRIBUTE_ESCAPE_HASH = TEXT_ESCAPE_HASH.merge({
      "\n" => '&#xA;',
      "\r" => '&#xD;',
      "\t" => '&#x9;'
    })

    DEFAULT_HEADER_ATTRIBUTES = {
      version: '1.0',
      encoding: 'utf-8'
    }

    def write_text(text, options = {})
      escape = options.fetch(:escape, true)

      stream.write(
        escape ? escape_text(text) : text
      )
    end

    def write_header(attributes = {})
      stream.write('<?xml ')

      write_attributes(
        DEFAULT_HEADER_ATTRIBUTES.merge(attributes)
      )

      stream.write('?>')
      write_newline
    end

    protected

    def check_tag_name(tag_name)
      unless tag_name =~ TAG_NAME_REGEX
        raise InvalidTagNameError, "'#{tag_name}' is not a valid tag"
      end
    end

    def check_attributes(attributes)
      attributes.each_pair do |key, _|
        unless key =~ ATTRIBUTE_KEY_REGEX
          raise InvalidAttributeKeyError,
            "'#{key}' is not a valid attribute key"
        end
      end
    end

    def write_open_tag(tag_name, attributes)
      stream.write("<#{tag_name}")

      if attributes.size > 0
        stream.write(' ')
        write_attributes(attributes)
      end

      stream.write('>')
    end

    def write_close_tag(tag_name)
      stream.write("</#{tag_name}>")
    end

    def write_attributes(attributes)
      attributes.each_pair.with_index do |(key, val), idx|
        if idx > 0
          stream.write(' ')
        end

        stream.write("#{key}=\"#{escape_attribute(val)}\"")
      end
    end

    def write_newline
      stream.write("\n")
    end

    def escape_attribute(attribute)
      attribute.gsub(ATTRIBUTE_ESCAPE_CHARS, ATTRIBUTE_ESCAPE_HASH)
    end

    def escape_text(text)
      text.gsub(TEXT_ESCAPE_CHARS, TEXT_ESCAPE_HASH)
    end
  end
end

