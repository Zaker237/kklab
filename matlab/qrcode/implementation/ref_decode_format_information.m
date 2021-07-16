function [level data_mask] = ref_decode_format_information(bitstream)
    global format_lut
    
    % Find the lut entry with the smallest hamming-distance
    best_lut_index = 0;
    best_hamming_distance = 16;
    
    for lut_index=1:32
        hamming_distance = sum(xor(bitstream, format_lut(lut_index, :)));
        if hamming_distance < best_hamming_distance
            best_lut_index = lut_index;
            best_hamming_distance = hamming_distance;
        end
    end
    
    format_bits = format_lut(best_lut_index, 1:5);
    
    [level_indicator format_bits] = read_from_bitstream(format_bits, 2);
    if level_indicator == 0
        level = 'M';
    elseif level_indicator == 1
        level = 'L';
    elseif level_indicator == 2
        level = 'H';
    else
        level = 'Q';
    end
    
    data_mask = read_from_bitstream(format_bits, 3);
end