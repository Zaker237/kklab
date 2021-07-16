
message = text_to_bitstream('this is a message');

[h g] = generate_matrizen(3);

X = message.*g;

y_error = simulate_noise(Y, 3);
y_no_error = y_error*h;

function [H G] = generate_matrizen(m)
    N = 2^m - 1;
    K = 2^m -m -1;
    
    H = hammgen(m);
    
    G = gen2par(H);
end