# encoding: UTF-8

require 'spec_helper'

describe XmlWriteStream::YieldingWriter do
  let(:stream) do
    StringIO.new.tap do |io|
      io.set_encoding(Encoding::UTF_8)
    end
  end

  let(:stream_writer) do
    XmlWriteStream::YieldingWriter.new(stream)
  end

  def utf8(str)
    str.encode(Encoding::UTF_8)
  end

  describe '#write_header' do
    it 'writes the header with default attributes' do
      stream_writer.write_header
      stream_writer.close

      expect(stream.string).to eq(
        utf8("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
      )
    end

    it 'allows header attributes to be overwritten' do
      stream_writer.write_header(version: '2.0')
      stream_writer.close

      expect(stream.string).to eq(
        utf8("<?xml version=\"2.0\" encoding=\"utf-8\"?>\n")
      )
    end

    it 'raises an error if tags have already been written' do
      expect do
        stream_writer.open_tag('foo') do |foo|
          foo.write_header
        end
      end.to raise_error(XmlWriteStream::InvalidHeaderPositionError)
    end
  end

  describe '#open_tag' do
    it 'writes an opening tag' do
      stream_writer.open_tag('maytag')
      expect(stream.string).to eq(
        utf8("<maytag>\n</maytag>\n")
      )
    end

    it 'yields the writer and allows nesting' do
      stream_writer.open_tag('maytag') do |maytag|
        expect(maytag).to be_a(XmlWriteStream::YieldingWriter)
        maytag.open_tag('machine')
      end

      expect(stream.string).to eq(
        utf8("<maytag>\n    <machine>\n    </machine>\n</maytag>\n")
      )
    end

    it 'writes an opening tag with attributes' do
      stream_writer.open_tag('maytag', { type: 'washing_machine' })
      expect(stream.string).to eq(
        utf8("<maytag type=\"washing_machine\">\n</maytag>\n")
      )
    end

    it 'raises an error if one of the attribute keys is invalid' do
      expect do
        stream_writer.open_tag('maytag', '0foo' => '')
      end.to raise_error(XmlWriteStream::InvalidAttributeKeyError)
    end

    it 'raises an error if the tag name is invalid' do
      expect do
        stream_writer.open_tag('9foo') {}
      end.to raise_error(XmlWriteStream::InvalidTagNameError)
    end

    it 'allows digits and colons in the tag name' do
      stream_writer.open_tag('foo9') do |foo|
        foo.open_tag('bar:baz')
      end

      expect(stream.string).to eq(
        utf8("<foo9>\n    <bar:baz>\n    </bar:baz>\n</foo9>\n")
      )
    end

    it 'raises an error if the stream is already closed' do
      stream_writer.close

      expect do
        stream_writer.open_tag('foo')
      end.to raise_error(XmlWriteStream::EndOfStreamError)
    end
  end

  describe '#write_text' do
    it 'writes escaped text by default' do
      stream_writer.open_tag('places') do |places|
        places.write_text("Alaska & Hawai'i")
      end

      expect(stream.string).to eq(
        utf8("<places>\n    Alaska &amp; Hawai&apos;i\n</places>\n")
      )
    end

    it 'writes raw text if asked not to escape' do
      stream_writer.open_tag('places') do |places|
        places.write_text("Alaska & Hawai'i", escape: false)
      end

      expect(stream.string).to eq(
        utf8("<places>\n    Alaska & Hawai'i\n</places>\n")
      )
    end

    it 'raises an error if no tag has been written yet' do
      expect do
        stream_writer.write_text('foo')
      end.to raise_error(XmlWriteStream::NoTopLevelTagError)
    end

    it 'raises an error if the stream is already closed' do
      stream_writer.close

      expect do
        stream_writer.write_text('foo')
      end.to raise_error(XmlWriteStream::EndOfStreamError)
    end
  end

  describe '#close' do
    it 'closes the stream' do
      stream_writer.close
      expect(stream).to be_closed
    end
  end
end
