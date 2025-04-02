function [indices, means] = calculate_vegetation_indices(mask, red, green, blue, nir, red_edge, show_imgs)

% Parametri per EVI
L = 1.0;
G = 2.5;
C1 = 6.0;
C2 = 7.5;

eps = 1e-10; % Per evitare divisione per zero

indices = struct();

indices.BNDVI = (nir - blue) ./ (nir + blue + eps);
indices.DVI = nir - red;
indices.EVI = G * (nir - red) ./ (nir + C1*red - C2*blue + L + eps);
indices.GI = green ./ (red + eps);
indices.GNDVI = (nir - green) ./ (nir + green + eps);
indices.GRVI = nir ./ (green + eps);
indices.IRVI = red ./ (nir + eps);

indices.MCARI1 = 1.2 * (2.5*(nir - red) - 1.3*(nir - green));
indices.MCARI2 = (1.5 * (2.5*(nir - red) - 1.3*(nir - green))) ./ ...
    (sqrt((2*nir + 1).^2 - (6*nir - 5*red) - 0.5) + eps);
indices.MSR = ((nir./(red + eps)) - 1) ./ (sqrt(nir./(red + eps) + 1) + eps);
indices.MSAVI = real((2*nir + 1 - sqrt((2*nir + 1).^2 - 8*(nir - red))) / 2); % real() in caso di numeri negativi sotto radice
indices.MTVI1 = 1.2 * (1.2*(nir - green) - 2.5*(red - green));
indices.MTVI2 = (1.5 * (1.2*(nir - green) - 2.5*(red - green))) ./ ...
    (sqrt((2*nir + 1).^2 - (6*nir - 5*red) - 0.5) + eps);
indices.NGRDI = (green - red) ./ (green + red + eps);
indices.NDRE = (nir - red_edge) ./ (nir + red_edge + eps);
indices.SR = nir ./ (red + eps);
indices.NDVI = (nir - red) ./ (nir + red + eps);
indices.NRVI = (indices.SR - 1) ./ (indices.SR + 1 + eps);
indices.OSAVI = 1.16 * (nir - red) ./ (nir + red + 0.16 + eps);
indices.RDVI = (nir - red) ./ (sqrt(nir + red + eps));
indices.SAVI = ((nir - red) ./ (nir + red + L + eps)) * (1 + L);
indices.TVI = real(sqrt(indices.NDVI + 0.5)); % real() in caso di numeri negativi sotto radice
indices.VREI = red ./ (red_edge + eps);

means = struct();
field_names = fieldnames(indices);
for i = 1:length(field_names)
    current_index = indices.(field_names{i});
    means.(field_names{i}) = mean(current_index(mask > 0));
end

disp('Mean values of vegetation indices in masked area:');
for i = 1:length(field_names)
    fprintf('%s: %.4f\n', field_names{i}, means.(field_names{i}));
end

if show_imgs
    figure('Name', 'Primary Vegetation Indices', 'WindowState', 'maximized');
    subplot(3,3,1); imshow(cat(3, red./max(red(:)), green./max(green(:)), blue./max(blue(:)))); title('RGB Image');
    subplot(3,3,2); show_index_normalized(indices.NDVI, 'NDVI');
    subplot(3,3,3); show_index_normalized(indices.EVI, 'EVI');
    subplot(3,3,4); show_index_normalized(indices.SAVI, 'SAVI');
    subplot(3,3,5); show_index_normalized(indices.NDRE, 'NDRE');
    subplot(3,3,6); show_index_normalized(indices.DVI, 'DVI');
    subplot(3,3,7); show_index_normalized(indices.MSAVI, 'MSAVI');
    subplot(3,3,8); show_index_normalized(indices.OSAVI, 'OSAVI');
    subplot(3,3,9); show_index_normalized(indices.SR, 'SR');

    figure('Name', 'Modified and Advanced Indices', 'WindowState', 'maximized');
    subplot(3,3,1); show_index_normalized(indices.MCARI1, 'MCARI1');
    subplot(3,3,2); show_index_normalized(indices.MCARI2, 'MCARI2');
    subplot(3,3,3); show_index_normalized(indices.MSR, 'MSR');
    subplot(3,3,4); show_index_normalized(indices.MTVI1, 'MTVI1');
    subplot(3,3,5); show_index_normalized(indices.MTVI2, 'MTVI2');
    subplot(3,3,6); show_index_normalized(indices.RDVI, 'RDVI');
    subplot(3,3,7); show_index_normalized(indices.TVI, 'TVI');
    subplot(3,3,8); show_index_normalized(indices.VREI, 'VREI');
    subplot(3,3,9); show_index_normalized(indices.NRVI, 'NRVI');

    figure('Name', 'Color-based and Ratio Indices', 'WindowState', 'maximized');
    subplot(3,3,1); show_index_normalized(indices.BNDVI, 'BNDVI');
    subplot(3,3,2); show_index_normalized(indices.GI, 'GI');
    subplot(3,3,3); show_index_normalized(indices.GNDVI, 'GNDVI');
    subplot(3,3,4); show_index_normalized(indices.GRVI, 'GRVI');
    subplot(3,3,5); show_index_normalized(indices.IRVI, 'IRVI');
    subplot(3,3,6); show_index_normalized(indices.NGRDI, 'NGRDI');

end
end

function show_index_normalized(index_image, title_text)
percentile_range = [2 98];

limits = prctile(index_image(:), percentile_range);

imshow(index_image, limits);
title(title_text);
colorbar;
end
