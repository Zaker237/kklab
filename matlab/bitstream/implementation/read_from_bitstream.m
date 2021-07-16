function [ value, modified_bitstream ] = read_from_bitstream(bitstream, word_size)
    value = binary_to_int(bitstream(1:word_size));
    
    if length(bitstream) == word_size
        modified_bitstream = create_bitstream();
    else
        modified_bitstream = bitstream(word_size+1:end);
    end
end

