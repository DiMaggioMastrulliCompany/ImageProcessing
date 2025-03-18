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
se = strel('disk', 3);
vegetation_mask = imopen(vegetation_mask, se);
vegetation_mask = imclose(vegetation_mask, se);

% Label connected components (individual trees)
[labeled_trees, num_trees] = bwlabel(vegetation_mask);

% Filter small objects (noise)
min_tree_size = 13000; % Adjust based on your image resolution
labeled_trees = bwareafilt(logical(labeled_trees), [min_tree_size inf]);

% Display results
figure;
subplot(2,2,1);
imshow(data(:,:,1:3)); title('RGB Image');
subplot(2,2,2);
imshow(ndvi, []); title('NDVI');
subplot(2,2,3);
imshow(ndre, []); title('NDRE');
subplot(2,2,4);
imshow(labeled_trees, []); title('Segmented Trees');

% Optional: Get properties of detected trees
tree_stats = regionprops(labeled_trees, 'Area', 'Centroid', 'BoundingBox');
fprintf('Number of detected olive trees: %d\n', length(tree_stats));
end
