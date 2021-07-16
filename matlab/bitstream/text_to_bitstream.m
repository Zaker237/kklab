function binary = text_to_bitstream(text)
    binary = bytestream_to_bitstream(unicode2native(text));
end

