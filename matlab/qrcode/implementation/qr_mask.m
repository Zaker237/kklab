function mask = qr_mask(y, x, mask_id)
    if mask_id == 0
        mask = mod(x + y - 2, 2) == 0;
    elseif mask_id == 1
        mask = mod(y - 1, 2) == 0;
    elseif mask_id == 2
        mask = mod(x - 1, 3) == 0;
    elseif mask_id == 3
        mask = mod(x + y - 2, 3) == 0;
    elseif mask_id == 4
        mask = mod(idivide(x-1, 2) + idivide(y-1, 3), 2) == 0;
    elseif mask_id == 5
        mask = mod((x-1) * (y-1), 2) + mod((x-1) * (y-1), 3) == 0;
    elseif mask_id == 6
        mask = mod(mod((x-1) * (y-1), 2) + mod((x-1) * (y-1), 3), 2) == 0;
    elseif mask_id == 7
        mask = mod(mod(x + y - 2, 2) + mod((x-1) * (y-1), 3), 2) == 0;
    else
    end
end