# encoding: UTF-8

class XmlWriteStream
  class StackItem
    attr_reader :tag_name, :multiline

    def initialize(tag_name, multiline = true)
      @tag_name = tag_name
      @multiline = multiline
    end

    alias_method :multiline?, :multiline
  end

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
      open_tag_helper(tag_name, true, attributes)
    end

    def open_single_line_tag(tag_name, attributes = {})
      open_tag_helper(tag_name, false, attributes)
    end

    def open_tag_helper(tag_name, multiline, attributes = {})
      check_eos

      if index == 0
        stack.push(StackItem.new(tag_name, multiline))
      end

      check_tag_name(tag_name)
      check_attributes(attributes)
      stream.write(indent_spaces) if index > 0 && current.multiline?
      write_open_tag(tag_name, attributes)
      write_newline if multiline

      if index > 0
        stack.push(StackItem.new(tag_name, multiline))
      end

      @index += 1
    end

    def write_text(text, options = {})
      check_eos

      if stack.size == 0
        raise NoTopLevelTagError
      end

      stream.write(indent_spaces) if current.multiline?
      super

      write_newline if current.multiline?
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
        stack_item = stack.pop
        stream.write(indent_spaces) if stack_item.multiline?
        write_close_tag(stack_item.tag_name)
        write_newline if current && current.multiline?
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

    def current
      stack.last
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
