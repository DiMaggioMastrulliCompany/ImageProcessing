function main()
% Read the multispectral image
[data, map] = imread('20240801_ulivo_bandeRED.tif');

% Convert to double for processing
red = double(data(:,:,1));
green = double(data(:,:,2));
blue = double(data(:,:,3));
red_edge = double(data(:,:,4));
nir = double(data(:,:,5));

% Calculate vegetation indices
% NDVI (Normalized Difference Vegetation Index)
ndvi = (nir - red) ./ (nir + red);

% NDRE (Normalized Difference Red Edge)
ndre = (nir - red_edge) ./ (nir + red_edge);

% Convert RGB to HSV for better color discrimination
% Convert RGB to HSV
rgb_normalized = cat(3, ...
    (red - min(red(:))) / (max(red(:)) - min(red(:))), ...
    (green - min(green(:))) / (max(green(:)) - min(green(:))), ...
    (blue - min(blue(:))) / (max(blue(:)) - min(blue(:))));
hsv = rgb2hsv(rgb_normalized);
saturation = hsv(:,:,2);

% Combine color and vegetation index conditions
vegetation_mask = (ndre > 0.20) & (saturation < 0.64);

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
% vegetation_mask_4 = imclose(vegetation_mask_4, se_small_4);

% Label connected components (chiome degli alberi)
[labeled_trees, num_trees] = bwlabel(vegetation_mask_4);

% Filter small objects (noise)
min_tree_size = 10000; % Adjust based on your image resolution
labeled_trees = bwareafilt(logical(labeled_trees), [min_tree_size inf]);

% Display results - Figure 1: Input and Indices
fig1 = figure('Name', 'Input and Vegetation Indices', 'WindowState', 'maximized');
subplot(2,3,1);
imshow(cat(3, red, green, blue), []); title('RGB Image');
subplot(2,3,3);
imshow(ndvi, []); title('NDVI');
subplot(2,3,4);
imshow(ndre, []); title('NDRE');
subplot(2,3,5);
imshow(green, []); title('Green Band');
subplot(2,3,5);
imshow(green, []); title('Green Band');

% Display results - Figure 2: Segmentation Steps
fig2 = figure('Name', 'Segmentation Process', 'WindowState', 'maximized');
subplot(2,3,1);
imshow(vegetation_mask, []); title('Initial Mask');
subplot(2,3,2);
imshow(vegetation_mask_1, []); title('After 1st Operation');
subplot(2,3,3);
imshow(vegetation_mask_2, []); title('After 2nd Operation');
subplot(2,3,4);
imshow(vegetation_mask_3, []); title('After 3rd Operation');
subplot(2,3,5);
imshow(labeled_trees, []); title('Final Segmentation');
