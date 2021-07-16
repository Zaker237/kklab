function symbol = read_symbol(filename)
    % Read from image file
    image_array = imread(filename);
    
    % Convert to binary array
    Size = size(image_array);
    Dimension = length(Size);
    
    if Dimension == 2
        image_array_binary = double(image_array <= 127);
    elseif Dimension == 3
        image_array_binary = double(image_array(:,:,1) <= 127);
    else
        throw(MException('read_symbol:WrongDimensions', 'The input image must have either one or three color channels!'));
    end
    
    % Remove empty border
    top_border = 1;
    bottom_border = Size(1);
    
    for x=1:Size(2)
        left_border = x;
        if any(image_array_binary(:, left_border))
            break;
        end
    end
    
    for x=Size(2):-1:1
        right_border = x;
        if any(image_array_binary(:, right_border))
            break;
        end
    end
    
    for y=1:Size(1)
        top_border = y;
        if any(image_array_binary(top_border, :))
            break;
        end
    end
    
    for y=Size(1):-1:1
        bottom_border = y;
        if any(image_array_binary(bottom_border, :))
            break;
        end
    end
    
    image_array_binary_borderless = image_array_binary(top_border:bottom_border,left_border:right_border);
    
    % Estimate module size and resample the symbol
    min_runlength = intmax;
    
    for y=1:Size(1)
        runlength = 0;
        current_value = image_array_binary(y,1);
        
        for x=1:Size(2)
            if image_array_binary(y,x) == current_value
                runlength = runlength + 1;
            else
                min_runlength = min(min_runlength, runlength);
                runlength = 1;
                current_value = ~current_value;
            end
        end
        
        min_runlength = min(min_runlength, runlength);
    end
    
    symbol = imresize(image_array_binary_borderless, 1.0/double(min_runlength), 'nearest');
end