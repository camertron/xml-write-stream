# encoding: UTF-8

require 'spec_helper'
require 'tempfile'

describe XmlWriteStream do
  let(:yielding_writer) { XmlWriteStream::YieldingWriter }
  let(:stateful_writer) { XmlWriteStream::StatefulWriter }
  let(:stream_writer) { XmlWriteStream }
  let(:tempfile) { Tempfile.new('temp') }
  let(:stream) { StringIO.new }

  describe '#from_stream' do
    it 'yields a yielding stream if given a block' do
      stream_writer.from_stream(stream) do |writer|
        expect(writer).to be_a(yielding_writer)
        expect(writer.stream).to equal(stream)
      end
    end

    it 'returns a stateful writer if not given a block' do
      writer = stream_writer.from_stream(stream)
      expect(writer).to be_a(stateful_writer)
      expect(writer.stream).to equal(stream)
    end

    it 'supports specifying a different encoding' do
      stream_writer.from_stream(stream, Encoding::UTF_16BE) do |writer|
        writer.open_tag('foo') do |tag_writer|
          tag_writer.write_text('bar')
        end
      end

      expect(stream.string.bytes.to_a).to_not eq(
        "<foo>\n    bar\n</foo>\n".bytes.to_a
      )

      expect(stream.string.encode(Encoding::UTF_8).bytes.to_a).to eq(
        "<foo>\n    bar\n</foo>\n".bytes.to_a
      )
    end
  end

  describe '#open' do
    it 'opens a file and yields a yielding stream if given a block' do
      stream_writer.open(tempfile) do |writer|
        expect(writer).to be_a(yielding_writer)
        expect(writer.stream.path).to eq(tempfile.path)
      end
    end

    it 'opens a file and returns a stateful writer if not given a block' do
      writer = stream_writer.open(tempfile)
      expect(writer).to be_a(stateful_writer)
      expect(writer.stream.path).to eq(tempfile.path)
    end

    it 'supports specifying a different encoding' do
      stream_writer.open(tempfile, Encoding::UTF_16BE) do |writer|
        writer.open_tag('foo') do |tag_writer|
          tag_writer.write_text('bar')
        end
      end

      written = tempfile.read
      written.force_encoding(Encoding::UTF_16BE)

      expect(written.bytes.to_a).to_not eq(
        "<foo>\n    bar\n</foo>\n".bytes.to_a
      )

      expect(written.encode(Encoding::UTF_8).bytes.to_a).to eq(
        "<foo>\n    bar\n</foo>\n".bytes.to_a
      )
    end
  end
end
