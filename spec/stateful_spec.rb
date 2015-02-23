# encoding: UTF-8

require 'spec_helper'

describe XmlWriteStream::YieldingWriter do
  let(:stream) do
    StringIO.new.tap do |io|
      io.set_encoding(Encoding::UTF_8)
    end
  end

  let(:stream_writer) do
    XmlWriteStream::StatefulWriter.new(stream)
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
      stream_writer.open_tag('foo')

      expect do
        stream_writer.write_header
      end.to raise_error(XmlWriteStream::InvalidHeaderPositionError)
    end
  end

  describe '#open_tag' do
    it 'writes an opening tag' do
      stream_writer.open_tag('maytag')
      stream_writer.close

      expect(stream.string).to eq(
        utf8("<maytag>\n</maytag>\n")
      )
    end

    it 'writes an opening tag with attributes' do
      stream_writer.open_tag('maytag', type: 'washing_machine')
      stream_writer.close

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
        stream_writer.open_tag('9foo')
      end.to raise_error(XmlWriteStream::InvalidTagNameError)
    end

    it 'allows digits and colons in the tag name' do
      stream_writer.open_tag('foo9')
      stream_writer.open_tag('bar:baz')
      stream_writer.close

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

  describe '#close_tag' do
    it 'closes the currently open tag' do
      stream_writer.open_tag('maytag')
      stream_writer.close_tag

      expect(stream.string).to eq(
        utf8("<maytag>\n</maytag>\n")
      )
    end
  end

  describe '#write_text' do
    it 'writes escaped text by default' do
      stream_writer.open_tag('places')
      stream_writer.write_text("Alaska & Hawai'i")
      stream_writer.close

      expect(stream.string).to eq(
        utf8("<places>\n    Alaska &amp; Hawai&apos;i\n</places>\n")
      )
    end

    it 'writes raw text if asked not to escape' do
      stream_writer.open_tag('places')
      stream_writer.write_text("Alaska & Hawai'i", escape: false)
      stream_writer.close

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

  describe '#flush' do
    it 'closes all open tags' do
      stream_writer.open_tag('foo')
      stream_writer.open_tag('bar')
      stream_writer.open_tag('baz')
      stream_writer.flush

      expect(stream.string).to eq(
        utf8("<foo>\n    <bar>\n        <baz>\n        </baz>\n    </bar>\n</foo>\n")
      )

      expect(stream).to_not be_closed
      expect(stream_writer).to be_eos
    end
  end

  describe '#close' do
    it 'closes all open tags and closes the stream' do
      stream_writer.open_tag('foo')
      stream_writer.open_tag('bar')
      stream_writer.open_tag('baz')
      stream_writer.close

      expect(stream.string).to eq(
        utf8("<foo>\n    <bar>\n        <baz>\n        </baz>\n    </bar>\n</foo>\n")
      )

      expect(stream).to be_closed
      expect(stream_writer).to be_eos
    end
  end

  describe '#in_tag?' do
    it 'returns true if currently writing a tag, false otherwise' do
      expect(stream_writer).to_not be_in_tag
      stream_writer.open_tag('foo')
      expect(stream_writer).to be_in_tag
    end
  end

  describe '#eos?' do
    it 'returns true if the stream is closed, false if it is still open' do
      expect(stream_writer).to_not be_eos
      stream_writer.close
      expect(stream_writer).to be_eos
    end
  end
end
