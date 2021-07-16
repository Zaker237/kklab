addpath(genpath('.'));

% Define CRC32 polynomial
global CRC32
CRC32 = logical([1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1]);

% Load predefined variables and make them global for easy access from
% functions and unit-tests
global format_lut format_mask
load('format_information.mat');

% global G H Syndrome_LUT
% load('code.mat');