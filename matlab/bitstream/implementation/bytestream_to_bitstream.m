function bitstream = bytestream_to_bitstream(bytestream)
    bitstream = create_bitstream();
    
    for i=1:length(bytestream)
        bitstream = write_to_bitstream(bitstream, bytestream(i), 8);
    end
end