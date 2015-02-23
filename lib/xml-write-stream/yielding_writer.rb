# encoding: UTF-8

class XmlWriteStream
  class YieldingWriter < Base
    attr_reader :stream, :level, :indent

    def initialize(stream, options = {})
      @stream = stream
      @level = 0
      @indent = options.fetch(:indent, Base::DEFAULT_INDENT)
    end

    def open_tag(tag_name, attributes = {})
      check_closed
      check_tag_name(tag_name)
      check_attributes(attributes)
      write_open_tag(tag_name, attributes)
      write_newline

      @level += 1
      yield self if block_given?
      @level -= 1
      write_close_tag(tag_name)
      write_newline
    end

    def write_text(text, options = {})
      check_closed

      if level == 0
        raise NoTopLevelTagError
      end

      super
    end

    def write_header(attributes = {})
      if level > 0
        raise InvalidHeaderPositionError,
          'header must be the first element written.'
      end

      super
    end

    def flush
    end

    def close
      stream.close
    end

    protected

    def check_closed
      if stream.closed?
        raise EndOfStreamError, 'end of stream.'
      end
    end

    def indent_spaces
      ' ' * (level * indent)
    end
  end
end
