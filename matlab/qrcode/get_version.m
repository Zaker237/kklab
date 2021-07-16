function version = get_version(symbol)
    Size = size(symbol);
    Dimension = length(Size);
    
    if Dimension ~= 2
        throw(MException('get_version:WrongDimensions', 'The symbol must be two-dimensional!'));
    end
    
    if Size(1) ~= Size(2)
        throw(MException('get_version:WrongDimensions', 'The symbol must be square!'));
    end
        
    version = (Size(1) - 21)/4 + 1;
end