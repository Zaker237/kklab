
message = text_to_bitstream('this is a message');

[h g] = generate_matrizen(3);

X = message*g;

function [H G] = generate_matrizen(m)
    N = 2^m - 1;
    K = 2^m -m -1;
    h(1,m) = 1;
    disp(h);
    for i=1:(m-1)
        h(1,i) = 0;
    end
    for j = 2:N
        a = de2bi(i);
        b = fliplr(a);
        [c, d] = size(b);
        if(d<m)
           e = [0];
           for f = 1:(m-d)
              e(1,f) = 0;
           end
           g = [e b];
           h(j,:) = g;
        end
        if d==m
           h(j,:) = b; 
        end
    end
    disp(h);
    
    T = h';
    [a2,b2] = size(h);
    P = T(1:m, (b2-K+1):b2);
    G = [eye(K) P'];
    H = [P eye(m)];
end