function [ modified_bitstream ] = write_to_bitstream(bitstream, value, word_size)
    modified_bitstream = [bitstream, int_to_binary(value, word_size)];
end

