function ulivo_campo()
filepath = 'ulivo_campo.img';

% Leggi le informazioni dall'header
info = enviinfo('ulivo_campo.hdr');

% Leggi l'immagine
data = multibandread(filepath, [info.Height, info.Width, info.Bands], info.DataType, info.HeaderOffset, info.Interleave, info.ByteOrder);

red_idx = 20; % Rosso
green_idx = 13; % Verde
blue_idx = 6; % Blu
nir_idx = 33; % NIR
red_edge_idx = 25; % Red Edge

% Get original dimensions
[orig_height, orig_width, num_bands] = size(data);
fprintf('Original image dimensions: %d x %d pixels with %d bands\n', orig_height, orig_width, num_bands);

% Resize the image to target dimensions
target_height = 2202;
target_width = 5136;
resized_data = imresize(data, [target_height target_width], 'nearest');

fprintf('Image resized to: %d x %d pixels\n', target_height, target_width);

red_res = double(resized_data(:,:,red_idx));
green_res = double(resized_data(:,:,green_idx));
blue_res = double(resized_data(:,:,blue_idx));

nir_res = double(resized_data(:,:,nir_idx));
red_edge_res = double(resized_data(:,:,red_edge_idx));

final_mask = segmentation(red_res, green_res, blue_res, red_edge_res, nir_res, 0.15, 0.60, 10000, 2202-150:2202);

final_mask = imresize(final_mask, [orig_height orig_width], 'nearest');

red = double(data(:,:,red_idx));
green = double(data(:,:,green_idx));
blue = double(data(:,:,blue_idx));
nir = double(data(:,:,nir_idx));
red_edge = double(data(:,:,red_edge_idx));

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
title('Immagine RGB');

subplot(1,2,2);
overlay = rgb_cut;
mask = cat(3, final_mask, final_mask, final_mask);
overlay(mask == 0) = overlay(mask == 0) * 0.3; % Darken non-tree areas
imshow(overlay);
title('Overlay maschera');

% Calculate all indices and show figures
calculate_vegetation_indices(final_mask, red, green, blue, nir, red_edge, true);
