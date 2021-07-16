function block_info = qr_block_info(version, level)
    if version == 1
        if level == 'L'
            block_info = [19 ; 7];
        elseif level == 'M'
            block_info = [16 ; 10];
        elseif level == 'Q'
            block_info = [13 ; 13];
        elseif level == 'H'
            block_info = [9 ; 17];
        end
    elseif version == 2
        if level == 'L'
            block_info = [34 ; 10];
        elseif level == 'M'
            block_info = [28 ; 16];
        elseif level == 'Q'
            block_info = [22 ; 22];
        elseif level == 'H'
            block_info = [16 ; 28];
        end
    elseif version == 3
        if level == 'L'
            block_info = [55 ; 15];
        elseif level == 'M'
            block_info = [44 ; 26];
        elseif level == 'Q'
            block_info = [17 17 ; 18 18];
        elseif level == 'H'
            block_info = [13 13 ; 22 22];
        end
    elseif version == 4
        if level == 'L'
            block_info = [80 ; 20];
        elseif level == 'M'
            block_info = [32 32 ; 18 18];
        elseif level == 'Q'
            block_info = [24 24 ; 26 26];
        elseif level == 'H'
            block_info = [9 9 9 9 ; 16 16 16 16];
        end
    elseif version == 5
        if level == 'L'
            block_info = [108 ; 26];
        elseif level == 'M'
            block_info = [43 43 ; 24 24];
        elseif level == 'Q'
            block_info = [15 15 16 16 ; 18 18 18 18];
        elseif level == 'H'
            block_info = [11 11 12 12 ; 22 22 22 22];
        end
    elseif version == 6
        if level == 'L'
            block_info = [68 68 ; 18 18];
        elseif level == 'M'
            block_info = [27 27 27 27 ; 16 16 16 16];
        elseif level == 'Q'
            block_info = [19 19 19 19; 24 24 24 24];
        elseif level == 'H'
            block_info = [15 15 15 15 ; 28 28 28 28];
        end
    else
        throw(MException('qr_block_info:UnsupportedVersion', 'Es werden nur QR-Codes der Version 1-6 unterst?tzt!'));
    end
end