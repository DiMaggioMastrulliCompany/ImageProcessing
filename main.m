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

% Segmentazione degli alberi di ulivo usando K-means
segmentOliveTrees(data);
end

function segmentOliveTrees(data)
% Questa funzione segmenta gli alberi di ulivo usando K-means clustering
% su un'immagine multispettrale

% Controllo quante bande ha l'immagine
[rows, cols, numBands] = size(data);
fprintf('Immagine multispettrale con %d bande\n', numBands);

% Converti l'immagine in formato adatto per clustering
dataPrep = double(data);

% Normalizzazione dei dati (importante per K-means)
for i = 1:numBands
    band_min = prctile(dataPrep(:,:,i), 2);
    band_max = prctile(dataPrep(:,:,i), 98);
    % Use element-wise operation (./) for division
    dataPrep(:,:,i) = (dataPrep(:,:,i) - band_min) ./ (band_max - band_min);
    dataPrep(:,:,i) = min(max(dataPrep(:,:,i), 0), 1);
end

% Convert to single type - imsegkmeans doesn't accept double
dataPrep = single(dataPrep);

% Applica K-means clustering con imsegkmeans invece di kmeans
% Scegliamo 3 cluster: alberi di ulivo, terreno/altro e possibili ombre/strutture
k = 3;
fprintf('Applicazione K-means con %d cluster...\n', k);
[segmentedImage, centroids] = imsegkmeans(dataPrep, k, 'NumAttempts', 3);

% Visualizza risultati
figure;
subplot(2,2,1);
% Mostra immagine RGB originale (prime 3 bande)
rgb = cat(3, data(:,:,1)/255, data(:,:,2)/255, data(:,:,3)/255);
imshow(rgb);
title('Immagine RGB originale');

subplot(2,2,2);
% Visualizza l'immagine segmentata
imagesc(segmentedImage);
colormap('jet');
title('Segmentazione K-means');
colorbar;

% Calcola l'indice di vegetazione NDVI se ci sono le bande appropriate
if numBands >= 4
    % Assumiamo che le bande siano ordinate come RGB-NIR...
    red = double(data(:,:,1));
    nir = double(data(:,:,4)); % Banda NIR (ipotetica)

    % Calcolo NDVI
    ndvi = (nir - red) ./ (nir + red + eps); % eps evita divisione per zero

    subplot(2,2,3);
    imagesc(ndvi, [-1 1]);
    colormap('jet');
    title('NDVI (Indice vegetazione)');
    colorbar;

    % Identificazione automatica del cluster che rappresenta la vegetazione
    % In genere il cluster con il valore NDVI medio più alto corrisponde alla vegetazione
    ndvi_means = zeros(k, 1);
    for i = 1:k
        mask = (segmentedImage == i);
        if (sum(mask(:)) > 0)
            ndvi_means(i) = mean(ndvi(mask));
        end
    end

    [~, vegetation_cluster] = max(ndvi_means);
    fprintf('Il cluster %d sembra rappresentare la vegetazione (NDVI medio: %.3f)\n', vegetation_cluster, ndvi_means(vegetation_cluster));

    % Crea maschera binaria degli alberi di ulivo
    oliveMask = (segmentedImage == vegetation_cluster);

    subplot(2,2,4);
    imshow(oliveMask);
    title('Maschera alberi di ulivo');
end

% Analisi dei risultati
fprintf('\nAnalisi dei cluster:\n');
for i = 1:k
    clusterSize = sum(segmentedImage(:) == i);
    percentage = clusterSize / (rows * cols) * 100;
    fprintf('Cluster %d: %d pixel (%.2f%%)\n', i, clusterSize, percentage);
    fprintf('   Centroide: ');
    fprintf('%.3f ', centroids(i,:));
    fprintf('\n');
end
end
