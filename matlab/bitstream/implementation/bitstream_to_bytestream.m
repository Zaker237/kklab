function bytestream = bitstream_to_bytestream(bitstream)
    if mod(int32(length(bitstream)), int32(8))
        throw(MException('bitstream_to_bytestream:WrongLength', 'The length of the input stream must be divisible by 8!'));
    end
    
    bytestream = zeros(1, idivide(int32(length(bitstream)), int32(8)));
    for i=1:length(bytestream)
        [bytestream(i) , bitstream] = read_from_bitstream(bitstream, 8);
    end
end