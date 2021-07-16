function text = bitstream_to_text(binary)
    text = native2unicode(bitstream_to_bytestream(binary));
end

