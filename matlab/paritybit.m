u_vector = text_to_bitstream('test labor');

parity = parity_bit(u_vector);

x_vector = [u_vector parity];

y_error_1 = simulate_noise(x_vector, 1);
y_error_2 = simulate_noise(x_vector, 2, true);
% check

y = [y_error_1];
number_of_one = sum(y(:)==1);
if mod(number_of_one, 2)==0
    disp('without parity error');
else
    disp('with paryty error')
end

y = [y_error_2];
number_of_one = sum(y(:)==1);
if mod(number_of_one, 2)==0
    disp('without parity error');
else
    disp('with paryty error')
end


parity_crc = paritybitcrc32(u_vector, CRC32);

x_vector_crc = [u_vector parity_crc];

y_crc_error = simulate_noise(x_vector_crc, 3);
%check

[result, rest] = poly_div(y_crc_error, CRC32);
if rest==0
    disp('without error');
else
    disp('with error')
end


function parity_b = parity_bit(input)
    parity_b = input(1);
    for idx = 2:length(input)
        parity_b = xor(parity_b, input(idx));
    end
end


function parity_crc = paritybitcrc32(input, crc)
    zeros_32 = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
    X_D = [input zeros_32];
    [result, rest] = poly_div(X_D, crc);
    parity_crc = rest;
end