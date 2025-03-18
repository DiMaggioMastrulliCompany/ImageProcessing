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

% Multi-scale edge-preserving segmentation
% Scale 1: Small details preservation
se_small = strel('disk', 3);
edges_small = edge(vegetation_mask, 'canny');
mask1 = imopen(vegetation_mask, se_small);
mask1 = imclose(mask1, se_small);
mask1 = mask1 | edges_small;

% Scale 2: Medium structures
se_med = strel('disk', 10);
edges_med = edge(mask1, 'canny');
mask2 = imopen(mask1, se_med);
mask2 = imclose(mask2, se_med);
mask2 = mask2 | edges_med;

% Scale 3: Large structures (crown level)
se_large = strel('disk', 20);
crown_mask = imopen(mask2, se_large);
crown_mask = imclose(crown_mask, se_large);

% Final cleanup and labeling
[labeled_trees, num_trees] = bwlabel(crown_mask);
min_tree_size = 10000;
labeled_trees = bwareafilt(logical(labeled_trees), [min_tree_size inf]);

% Display results
figure;
subplot(2,3,1);
imshow(data(:,:,1:3)); title('RGB Image');
subplot(2,3,2);
imshow(vegetation_mask, []); title('Initial Mask');
subplot(2,3,3);
imshow(mask1, []); title('Scale 1 (Small)');
subplot(2,3,4);
imshow(mask2, []); title('Scale 2 (Medium)');
subplot(2,3,5);
imshow(crown_mask, []); title('Scale 3 (Large)');
subplot(2,3,6);
imshow(labeled_trees, []); title('Final Segmentation');

% Optional: Get properties of detected trees
tree_stats = regionprops(labeled_trees, 'Area', 'Centroid', 'BoundingBox');
fprintf('Number of detected olive trees: %d\n', length(tree_stats));

end
