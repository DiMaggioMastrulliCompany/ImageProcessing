function main()
[data, ~] = imread('20240801_ulivo_bandeRED.tif');

% Convert to double for processing
red = double(data(:,:,3));
green = double(data(:,:,2));
blue = double(data(:,:,1));
red_edge = double(data(:,:,4));
nir = double(data(:,:,5));


final_mask = segmentation(red, green, blue, red_edge, nir, 0.20, 0.64, 10000, 1:300);


% Cut off top and bottom 2% for each color channel
red_limits = prctile(red(:), [2 98]);
green_limits = prctile(green(:), [2 98]);
blue_limits = prctile(blue(:), [2 98]);

% Clip values and normalize
red_cut = (min(max(red, red_limits(1)), red_limits(2)) - red_limits(1)) / (red_limits(2) - red_limits(1));
green_cut = (min(max(green, green_limits(1)), green_limits(2)) - green_limits(1)) / (green_limits(2) - green_limits(1));
blue_cut = (min(max(blue, blue_limits(1)), blue_limits(2)) - blue_limits(1)) / (blue_limits(2) - blue_limits(1));

rgb_cut = cat(3, red_cut, green_cut, blue_cut);

% Create overlay of final result on RGB
figure('Name', 'Final Result', 'WindowState', 'maximized');
subplot(1,2,1);
imshow(rgb_cut);
title('RGB Image');

subplot(1,2,2);
overlay = rgb_cut;
mask = cat(3, final_mask, final_mask, final_mask);
overlay(mask == 0) = overlay(mask == 0) * 0.3; % Darken non-tree areas
imshow(overlay);
title('Detected Trees Overlay');

% Calculate all indices and show figures
calculate_vegetation_indices(labeled_trees, red, green, blue, nir, red_edge);
