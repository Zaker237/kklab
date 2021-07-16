function bitstream = ref_read_format_information(symbol)
    global format_mask
    
    % Read format information from the symbol
    bitstream = zeros(1, 15);
    bitstream(15) = symbol(1, 9);
    bitstream(14) = symbol(2, 9);
    bitstream(13) = symbol(3, 9);
    bitstream(12) = symbol(4, 9);
    bitstream(11) = symbol(5, 9);
    bitstream(10) = symbol(6, 9);
    bitstream(9) = symbol(8, 9);
    bitstream(8) = symbol(9, 9);
    bitstream(7) = symbol(9, 8);
    bitstream(6) = symbol(9, 7);
    bitstream(5) = symbol(9, 5);
    bitstream(4) = symbol(9, 4);
    bitstream(3) = symbol(9, 3);
    bitstream(2) = symbol(9, 2);
    bitstream(1) = symbol(9, 1);
    
    % Remove mask
    bitstream = xor(bitstream, format_mask);
end