function main()
% Read the multispectral image
[data, ~] = imread('20240801_ulivo_bandeRED.tif');

% Convert to double for processing
red = double(data(:,:,3));
green = double(data(:,:,2));
blue = double(data(:,:,1));
red_edge = double(data(:,:,4));
nir = double(data(:,:,5));

% Convert RGB to HSV for better color discrimination
rgb_normalized = cat(3, ...
    (red - min(red(:))) / (max(red(:)) - min(red(:))), ...
    (green - min(green(:))) / (max(green(:)) - min(green(:))), ...
    (blue - min(blue(:))) / (max(blue(:)) - min(blue(:))));
hsv = rgb2hsv(rgb_normalized);
saturation = hsv(:,:,2);

% Calculate initial indices for mask creation
temp_NDRE = (nir - red_edge) ./ (nir + red_edge);

% Create vegetation mask
vegetation_mask = (temp_NDRE > 0.20) & (saturation < 0.64);
vegetation_mask(1:300, :) = 0;

% Apply morphological operations to clean up the mask
se_small_1 = strel('disk', 3);
vegetation_mask_1 = imopen(vegetation_mask, se_small_1);
vegetation_mask_1 = imclose(vegetation_mask_1, se_small_1);

se_small_2 = strel('disk', 7);
vegetation_mask_2 = imopen(vegetation_mask_1, se_small_2);
vegetation_mask_2 = imclose(vegetation_mask_2, se_small_2);

% Rilevazione specifica delle chiome
se_small_3 = strel('disk', 15);
vegetation_mask_3 = imopen(vegetation_mask_2, se_small_3);
vegetation_mask_3 = imclose(vegetation_mask_3, se_small_3);

se_small_4 = strel('disk', 25);
vegetation_mask_4 = imopen(vegetation_mask_3, se_small_4);

% Label connected components (chiome degli alberi)
[labeled_trees, ~] = bwlabel(vegetation_mask_4);

% Filter small objects (noise)
min_tree_size = 10000; % Adjust based on your image resolution
labeled_trees = bwareafilt(logical(labeled_trees), [min_tree_size inf]);

% Cut off top and bottom 2% for each color channel
red_limits = prctile(red(:), [2 98]);
green_limits = prctile(green(:), [2 98]);
blue_limits = prctile(blue(:), [2 98]);

% Clip values and normalize
red_cut = (min(max(red, red_limits(1)), red_limits(2)) - red_limits(1)) / (red_limits(2) - red_limits(1));
green_cut = (min(max(green, green_limits(1)), green_limits(2)) - green_limits(1)) / (green_limits(2) - green_limits(1));
blue_cut = (min(max(blue, blue_limits(1)), blue_limits(2)) - blue_limits(1)) / (blue_limits(2) - blue_limits(1));

rgb_cut = cat(3, red_cut, green_cut, blue_cut);

% Separate figure for segmentation steps
figure('Name', 'Segmentation Process', 'WindowState', 'maximized');
subplot(2,3,1); imshow(vegetation_mask, []); title('Initial Mask');
subplot(2,3,2); imshow(vegetation_mask_1, []); title('After 1st Operation');
subplot(2,3,3); imshow(vegetation_mask_2, []); title('After 2nd Operation');
subplot(2,3,4); imshow(vegetation_mask_3, []); title('After 3rd Operation');
subplot(2,3,5); imshow(vegetation_mask_4, []); title('After 4th Operation');
subplot(2,3,6); imshow(labeled_trees, []); title('Final Segmentation');

% Create overlay of final result on RGB
figure('Name', 'Final Result', 'WindowState', 'maximized');
overlay = rgb_cut;
mask = cat(3, labeled_trees, labeled_trees, labeled_trees);
overlay(mask == 0) = overlay(mask == 0) * 0.3; % Darken non-tree areas
imshow(overlay); title('Detected Trees Overlay');

% Calculate all indices and show figures
calculate_vegetation_indices(labeled_trees, red, green, blue, nir, red_edge);
