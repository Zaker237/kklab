function bitstream = string_to_bitstream(string)
    bitstream = create_bitstream();
    
    for i=1:length(string)
        if string(i) == '0'
            bitstream = write_to_bitstream(bitstream, 0, 1);
        else
            bitstream = write_to_bitstream(bitstream, 1, 1);
        end
    end
end