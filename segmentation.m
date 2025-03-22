function final_mask = segmentation(red, green, blue, red_edge, nir, min_ndre, max_saturation, min_tree_size, filter_rows)
% Convert RGB to HSV for better color discrimination
rgb_normalized = cat(3, ...
    (red - min(red(:))) / (max(red(:)) - min(red(:))), ...
    (green - min(green(:))) / (max(green(:)) - min(green(:))), ...
    (blue - min(blue(:))) / (max(blue(:)) - min(blue(:))));
hsv = rgb2hsv(rgb_normalized);
saturation = hsv(:,:,2);

% Calculate initial indices for mask creation
NDRE = (nir - red_edge) ./ (nir + red_edge);

% Create vegetation mask
vegetation_mask = (NDRE > min_ndre) & (saturation < max_saturation);
vegetation_mask(filter_rows, :) = 0;

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
final_mask = bwareafilt(logical(labeled_trees), [min_tree_size inf]);

% Separate figure for segmentation steps
figure('Name', 'Segmentation Process', 'WindowState', 'maximized');
subplot(2,3,1); imshow(vegetation_mask, []); title('Rilevamento Vegetazione Grezzo');
subplot(2,3,2); imshow(vegetation_mask_1, []); title('Filtro Oggetti Piccoli (r=3)');
subplot(2,3,3); imshow(vegetation_mask_2, []); title('Filtro Oggetti Medi (r=7)');
subplot(2,3,4); imshow(vegetation_mask_3, []); title('Filtro Oggetti Grandi (r=15)');
subplot(2,3,5); imshow(vegetation_mask_4, []); title('Filtro Oggetti Finali (r=25)');
subplot(2,3,6); imshow(final_mask, []); title('Chiome Filtrate per Dimensione');
