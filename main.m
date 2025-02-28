function displayQGISLikeImage()
% Read the image
[data, ~] = imread('20240801_ulivo_bandeRED.tif');

% Convert to double for processing
red = double(data(:,:,1));
green = double(data(:,:,2));
blue = double(data(:,:,3));

% Method 1: Use the exact values from QGIS
% These are the values from your QGIS screenshot
red_norm1 = (red - 0.0302391) / (0.135319 - 0.0302391);
green_norm1 = (green - 0.044019) / (0.161973 - 0.044019);
blue_norm1 = (blue - 0.0365742) / (0.237924 - 0.0365742);

% Method 2: Calculate values using percentile cutoffs (similar to QGIS's cumulative cut)
% This excludes outliers by using 2% and 98% percentiles instead of absolute min/max
red_min2 = prctile(red(:), 2);
red_max2 = prctile(red(:), 98);
green_min2 = prctile(green(:), 2);
green_max2 = prctile(green(:), 98);
blue_min2 = prctile(blue(:), 2);
blue_max2 = prctile(blue(:), 98);

red_norm2 = (red - red_min2) / (red_max2 - red_min2);
green_norm2 = (green - green_min2) / (green_max2 - green_min2);
blue_norm2 = (blue - blue_min2) / (blue_max2 - blue_min2);

% Clip values to 0-1 range for both methods
red_norm1 = min(max(red_norm1, 0), 1);
green_norm1 = min(max(green_norm1, 0), 1);
blue_norm1 = min(max(blue_norm1, 0), 1);

red_norm2 = min(max(red_norm2, 0), 1);
green_norm2 = min(max(green_norm2, 0), 1);
blue_norm2 = min(max(blue_norm2, 0), 1);

% Create RGB images
rgb1 = cat(3, red_norm1, green_norm1, blue_norm1);
rgb2 = cat(3, red_norm2, green_norm2, blue_norm2);

% Display both versions
figure;
subplot(1,2,1);
imshow(rgb1);
title('Using QGIS Values');

subplot(1,2,2);
imshow(rgb2);
title('Using Percentile Cut (2-98%)');

% Print the calculated percentile values for comparison
fprintf('Red band - 2%%: %f, 98%%: %f\n', red_min2, red_max2);
fprintf('Green band - 2%%: %f, 98%%: %f\n', green_min2, green_max2);
fprintf('Blue band - 2%%: %f, 98%%: %f\n', blue_min2, blue_max2);
end
