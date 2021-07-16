function noisy_bitstream = simulate_noise(bitstream, count, burst)
    % Disable burst errors if not specifically enabled
    if nargin() == 2
        burst = false;
    end
    
    % Create noise vector
    noise = zeros(size(bitstream));
    
    if burst
        start_position = randi(length(bitstream) - count + 1, 1);
        noise(start_position:start_position+count-1) = 1;
    else
        noise(1:count) = 1;
        noise = noise(randperm(length(bitstream)));
    end
    
    % Flip bits
    noisy_bitstream = double(xor(bitstream, noise));
end