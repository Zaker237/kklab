function binary = int_to_binary(value, word_size)
    value = uint32(value);
    binary = zeros(1, 0);
    
    % Convert to binary representation
    while value ~= 0
        binary = [mod(value, 2) binary];
        value = idivide(value, uint32(2));
    end
    
    % Pad with zeros to utilize the full word-size
    if length(binary) > word_size
        throw(MException('int_to_binary:Overflow', 'The word-size is too small to represent the requested value!'));
    end
    
    binary = double(padarray(binary, [0 (word_size - length(binary))], 0, 'pre'));
end