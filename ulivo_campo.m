% Percorso del file immagine .img
filepath = 'ulivo_campo.img';

% Leggi le informazioni dall'header
info = enviinfo('ulivo_campo.hdr');

% Leggi l'immagine
data = multibandread(filepath, [info.Height, info.Width, info.Bands], info.DataType, info.HeaderOffset, info.Interleave, info.ByteOrder);

% Visualizza un'immagine RGB usando le bande predefinite
default_bands = info.DefaultBands;  % Queste sono le bande [20, 13, 6] come indicato nell'header

% Crea immagine RGB
rgb = zeros(info.Height, info.Width, 3);
for i = 1:3
    rgb(:,:,i) = data(:,:,default_bands(i));
end

% Normalizza per la visualizzazione
rgb_norm = rgb / max(rgb(:));

% Estrai le bande utili per la segmentazione basata su vegetazione
% Identifichiamo le bande più vicine a quelle dell'esempio precedente
wavelengths = info.Wavelength;

% Trova gli indici delle bande più vicine a:
% - Rosso (~650-670 nm)
% - NIR (~800-850 nm)
% - Red Edge (~720-740 nm)
[~, red_idx] = min(abs(wavelengths - 652));
[~, green_idx] = min(abs(wavelengths - 552));
[~, blue_idx] = min(abs(wavelengths - 452));
[~, nir_idx] = min(abs(wavelengths - 830));
[~, red_edge_idx] = min(abs(wavelengths - 730));

fprintf('Bande selezionate per la segmentazione:\n');
fprintf('Rosso: %.2f nm (banda %d)\n', wavelengths(red_idx), red_idx);
fprintf('Verde: %.2f nm (banda %d)\n', wavelengths(green_idx), green_idx);
fprintf('Blu: %.2f nm (banda %d)\n', wavelengths(blue_idx), blue_idx);
fprintf('NIR: %.2f nm (banda %d)\n', wavelengths(nir_idx), nir_idx);
fprintf('Red Edge: %.2f nm (banda %d)\n', wavelengths(red_edge_idx), red_edge_idx);

% Estrai le bande
red = double(data(:,:,red_idx));
green = double(data(:,:,green_idx));
blue = double(data(:,:,blue_idx));

nir = double(data(:,:,nir_idx));
red_edge = double(data(:,:,red_edge_idx));

rgb_normalized = cat(3, ...
    (red - min(red(:))) / (max(red(:)) - min(red(:))), ...
    (green - min(green(:))) / (max(green(:)) - min(green(:))), ...
    (blue - min(blue(:))) / (max(blue(:)) - min(blue(:))));
hsv = rgb2hsv(rgb_normalized);
saturation = hsv(:,:,2);

% Combina gli indici per una migliore segmentazione
% Potrebbe essere necessario regolare le soglie in base all'immagine
vegetation_mask = (indices.NDRE > 0.15) & (saturation < 0.64);

vegetation_mask(end-10:end, :) = 0;

% Applica operazioni morfologiche per migliorare la maschera
se_small_1 = strel('disk', 1);
vegetation_mask_1 = imopen(vegetation_mask, se_small_1);
vegetation_mask_1 = imclose(vegetation_mask_1, se_small_1);

se_small_2 = strel('disk', 2);
vegetation_mask_2 = imopen(vegetation_mask_1, se_small_2);

% Etichetta le componenti connesse (chiome degli alberi)
[labeled_trees, ~] = bwlabel(vegetation_mask_2);

% Filtra gli oggetti piccoli (rumore)
min_tree_size = 45; % Regola in base alla risoluzione dell'immagine
labeled_trees = bwareafilt(logical(labeled_trees), [min_tree_size inf]);

% Cut off top and bottom 2% for each color channel
red_limits = prctile(red(:), [2 98]);
green_limits = prctile(green(:), [2 98]);
blue_limits = prctile(blue(:), [2 98]);

fprintf('Red limits: %.2f to %.2f\n', red_limits(1), red_limits(2));
fprintf('Green limits: %.2f to %.2f\n', green_limits(1), green_limits(2));
fprintf('Blue limits: %.2f to %.2f\n', blue_limits(1), blue_limits(2));

% Clip values and normalize
red_cut = (min(max(red, red_limits(1)), red_limits(2)) - red_limits(1)) / (red_limits(2) - red_limits(1));
green_cut = (min(max(green, green_limits(1)), green_limits(2)) - green_limits(1)) / (green_limits(2) - green_limits(1));
blue_cut = (min(max(blue, blue_limits(1)), blue_limits(2)) - blue_limits(1)) / (blue_limits(2) - blue_limits(1));

rgb_cut = cat(3, red_cut, green_cut, blue_cut);

% Figura separata per i passi di segmentazione
figure('Name', 'Segmentation Process', 'WindowState', 'maximized');
subplot(2,3,1); imshow(vegetation_mask, []); title('Initial Mask');
subplot(2,3,2); imshow(vegetation_mask_1, []); title('After 1st Operation');
subplot(2,3,3); imshow(vegetation_mask_2, []); title('After 2nd Operation');
subplot(2,3,4); imshow(labeled_trees, []); title('Labeled Trees');

% Crea overlay del risultato finale su RGB
figure('Name', 'Final Result', 'WindowState', 'maximized');
subplot(1,2,1);
imshow(rgb_cut);
title('Original Image');

subplot(1,2,2);
overlay = rgb_cut;
mask = cat(3, labeled_trees, labeled_trees, labeled_trees);
overlay(mask == 0) = overlay(mask == 0) * 0.3; % Darken non-tree areas
imshow(overlay);
title('Detected Trees Overlay');

calculate_vegetation_indices(labeled_trees, red, green, blue, nir, red_edge);
