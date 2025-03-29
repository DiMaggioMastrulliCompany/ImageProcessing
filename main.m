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
fprintf('Vegetation indices of all trees:\n');
% calculate_vegetation_indices(final_mask, red, green, blue, nir, red_edge, true);

% red ones
% [x, y]
% [[655, 782], [635, 1002], [615,1221], [865, 762], [845, 1002], [825, 1231],
% [1503, 761], [1458, 981], [1695, 761], [1662, 1229], [1402, 1675], [1605, 1692]]

% Centers coordinates
red_centers = [
    655, 782;
    635, 1002;
    615, 1221;
    865, 762;
    845, 1002;
    802, 1231;
    1503, 761;
    1458, 981;
    1695, 761;
    1656, 1229;
    1402, 1675;
    1600, 1692;
    2482, 1211;
    2450, 1434;
    2422, 1673;
    2696, 1427;
    2668, 1653;
    ];

green_centers = [
    2730, 998;
    3140, 1002;
    3131, 1236;
    3117, 1441;
    3315, 1441;
    3369, 765;
    3346, 993;
    ];

red_mask = compute_single_trees_indeces(final_mask, red_centers);
fprintf('Vegetation indices of red trees:\n');
calculate_vegetation_indices(red_mask, red, green, blue, nir, red_edge, false);


green_mask = compute_single_trees_indeces(final_mask, green_centers);
fprintf('Vegetation indices of green trees:\n');
calculate_vegetation_indices(green_mask, red, green, blue, nir, red_edge, false);
end

function trees_mask = compute_single_trees_indeces(final_mask, centers)
% Get dimensions
[rows, cols] = size(final_mask);
centers_mask = false(rows, cols);

% Create circular masks around each center
for i = 1:size(centers, 1)
    [X, Y] = meshgrid(1:cols, 1:rows);
    distance = sqrt((X - centers(i,1)).^2 + (Y - centers(i,2)).^2);
    centers_mask = centers_mask | (distance <= 110);
end

% Combine with final mask
trees_mask = final_mask & centers_mask;

% Display red trees mask
figure('Name', 'Trees Mask');
imshow(trees_mask);
title('Trees Mask');

% Calculate indices for the masked area
end
