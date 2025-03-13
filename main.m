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

% Combine indices for better segmentation
vegetation_mask = (ndvi > 0.3) & (ndre > 0.2);

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

% Display results
figure;
subplot(2,3,1);
imshow(data(:,:,1:3)); title('RGB Image');
subplot(2,3,2);
imshow(vegetation_mask, []); title('vegetation_mask');
subplot(2,3,3);
imshow(vegetation_mask_1, []); title('vegetation_mask_1');
subplot(2,3,4);
imshow(vegetation_mask_2, []); title('vegetation_mask_2');
subplot(2,3,5);
imshow(vegetation_mask_3, []); title('vegetation_mask_3');
subplot(2,3,6);
imshow(labeled_trees, []); title('Segmented Crowns');

% Optional: Get properties of detected trees
tree_stats = regionprops(labeled_trees, 'Area', 'Centroid', 'BoundingBox');
fprintf('Number of detected olive trees: %d\n', length(tree_stats));

end
