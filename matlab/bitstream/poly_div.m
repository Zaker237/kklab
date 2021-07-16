function [result, rest] = poly_div(arg, divisor)
    arg = arg(find(arg, 1, 'first'):end);
    divisor = divisor(find(divisor, 1, 'first'):end);
    
    if length(arg) < length(divisor)
        result = 0;
        rest = arg;
    elseif length(divisor) == 1
        result = arg;
        rest = 0;
    else
        result = zeros(1, length(arg)-length(divisor)+1);
        
        for i=1:length(result)
            result(i) = arg(i);
            arg(i:i+length(divisor)-1) = arg(i:i+length(divisor)-1) - result(i) * divisor;
        end
        
        result = mod(result, 2);
        rest = mod(arg(end-length(divisor)+2:end), 2);
    end
end
