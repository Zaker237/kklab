function string = bitstream_to_string(bitstream)
    string = '';
    
    for i=1:length(bitstream)
        if (bitstream(i))
            string = [string '1'];
        else
            string = [string '0'];
        end
    end
end