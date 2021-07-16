function value = bitstream_to_number(bitstream, word_size)
    value = binary_to_int(bitstream(1:word_size));
end

