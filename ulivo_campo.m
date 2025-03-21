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
[~, red_idx] = min(abs(wavelengths - 660));
[~, green_idx] = min(abs(wavelengths - 550));
[~, blue_idx] = min(abs(wavelengths - 470));
[~, nir_idx] = min(abs(wavelengths - 830));
[~, red_edge_idx] = min(abs(wavelengths - 730));

% Estrai le bande
red = double(data(:,:,red_idx));
green = double(data(:,:,blue_idx));
blue = double(data(:,:,green_idx));

nir = double(data(:,:,nir_idx));
red_edge = double(data(:,:,red_edge_idx));

% Calcola gli indici di vegetazione
% NDRE (Normalized Difference Red Edge)
ndre = (nir - red_edge) ./ (nir + red_edge);

rgb_normalized = cat(3, ...
    (red - min(red(:))) / (max(red(:)) - min(red(:))), ...
    (green - min(green(:))) / (max(green(:)) - min(green(:))), ...
    (blue - min(blue(:))) / (max(blue(:)) - min(blue(:))));
hsv = rgb2hsv(rgb_normalized);
saturation = hsv(:,:,2);


% Combina gli indici per una migliore segmentazione
% Potrebbe essere necessario regolare le soglie in base all'immagine
vegetation_mask = (ndre > 0.15) & (saturation < 0.64);

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

% Visualizza i risultati
figure;
subplot(2,3,1);
imshow(rgb_norm); title('RGB Image');
subplot(2,3,2);
imshow(vegetation_mask, []); title('vegetation\_mask');
subplot(2,3,3);
imshow(vegetation_mask_1, []); title('vegetation\_mask\_1');
subplot(2,3,4);
imshow(vegetation_mask_2, []); title('vegetation\_mask\_2');
subplot(2,3,6);
imshow(labeled_trees, []); title('Segmented Crowns');

% Calcola le proprietà degli alberi rilevati
tree_stats = regionprops(labeled_trees, 'Area', 'Centroid', 'BoundingBox');
fprintf('Numero di alberi di ulivo rilevati: %d\n', length(tree_stats));
