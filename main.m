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
se_small = strel('disk', 3);
vegetation_mask = imopen(vegetation_mask, se_small);
vegetation_mask = imclose(vegetation_mask, se_small);

% Rilevazione specifica delle chiome
se_crown = strel('disk', 20);  % raggio di circa 67 pixel per le chiome
crown_mask = imopen(vegetation_mask, se_crown);
crown_mask = imclose(crown_mask, se_crown);

% Label connected components (chiome degli alberi)
[labeled_trees, num_trees] = bwlabel(crown_mask);

% Filter small objects (noise)
min_tree_size = 10000; % Adjust based on your image resolution
labeled_trees = bwareafilt(logical(labeled_trees), [min_tree_size inf]);

% Display results
figure;
subplot(2,3,1);
imshow(data(:,:,1:3)); title('RGB Image');
subplot(2,3,2);
imshow(ndvi, []); title('NDVI');
subplot(2,3,3);
imshow(ndre, []); title('NDRE');
subplot(2,3,4);
imshow(vegetation_mask, []); title('Vegetation Mask');
subplot(2,3,5);
imshow(crown_mask, []); title('Crown Detection');
subplot(2,3,6);
imshow(labeled_trees, []); title('Segmented Crowns');

% Optional: Get properties of detected trees
tree_stats = regionprops(labeled_trees, 'Area', 'Centroid', 'BoundingBox');
fprintf('Number of detected olive trees: %d\n', length(tree_stats));

end
