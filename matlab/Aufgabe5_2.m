symbol_1 = read_symbol('testdaten/Aufgabe_2_1.png');
symbol_2 = read_symbol('testdaten/Aufgabe_2_2.png');
symbol_3 = read_symbol('testdaten/Aufgabe_2_3.png');

function [F_masked, F, F_decode] = decode_symbol(symbol)
    line_8 = symbol_1(8,:);
    first_ = line_8(0,8)
end