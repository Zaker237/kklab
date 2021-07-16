function write_symbol(symbol, filename)
    % Convert to 8bit grayscale array
    symbol_8bit = 255 * (1 - uint8(symbol));
    
    % Add empty border
    symbol_8bit_border = padarray(symbol_8bit, [4 4], 255);
    
    % Upsample the symbol
    symbol_8bit_border_resized = imresize(symbol_8bit_border, 10, 'nearest');
    
    % Write to image file
    imwrite(symbol_8bit_border_resized, filename);
end