function value = binary_to_int(binary)
    value = 0;
    place = 2^(length(binary) - 1);
    
    for i=1:length(binary)
        value = value + binary(i) * place;
        place = idivide(place, uint32(2));
    end
end