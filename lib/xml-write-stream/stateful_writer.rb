# encoding: UTF-8

class XmlWriteStream
  class StatefulWriter < Base
    attr_reader :stream, :stack, :closed, :indent, :index
    alias :closed? :closed

    def initialize(stream, options = {})
      @stream = stream
      @stack = []
      @closed = false
      @index = 0
      @indent = options.fetch(:indent, Base::DEFAULT_INDENT)
    end

    def open_tag(tag_name, attributes = {})
      check_eos
      @index += 1

      check_tag_name(tag_name)
      check_attributes(attributes)
      write_open_tag(tag_name, attributes)
      write_newline

      stack.push(tag_name)
    end

    def write_text(text, options = {})
      check_eos

      if stack.size == 0
        raise NoTopLevelTagError
      end

      super
    end

    def write_header(attributes = {})
      if stack.size > 0
        raise InvalidHeaderPositionError,
          'header must be the first element written.'
      end

      super
    end

    def close_tag(options = {})
      if in_tag?
        tag_name = stack.pop
        write_close_tag(tag_name)
        write_newline
      end
    end

    def flush
      close_tag until stack.empty?
      @closed = true
      nil
    end

    def close
      flush
      stream.close
      nil
    end

    def in_tag?
      stack.size > 0 && !closed?
    end

    def eos?
      (stack.size == 0 && index > 0) || closed?
    end

    protected

    def indent_spaces
      ' ' * (stack.size * indent)
    end

    def check_eos
      if eos?
        raise EndOfStreamError, 'end of stream.'
      end
    end
  end
end
