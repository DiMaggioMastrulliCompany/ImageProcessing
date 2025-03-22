function [indices, means] = calculate_vegetation_indices(mask, red, green, blue, nir, red_edge)
% Constants for indices
L = 0.5;  % Soil adjustment factor
G = 2.5;  % Gain factor for EVI
C = 6.0;  % Coefficient for EVI
eps = 1e-10; % Small epsilon to prevent division by zero

% Calculate vegetation indices
indices = struct();

% Basic indices
indices.BNDVI = (nir - blue) ./ (nir + blue + eps);
indices.DVI = nir - red;
indices.EVI = G * (nir - red) ./ (nir + C*red - C*blue + L + eps);
indices.GI = green ./ (red + eps);
indices.GNDVI = (nir - green) ./ (nir + green + eps);
indices.GRVI = nir ./ (green + eps);
indices.IRVI = red ./ (nir + eps);

% Advanced indices
indices.MCARI1 = 1.2 * (2.5*(nir - red) - 1.3*(nir - green));
indices.MCARI2 = (1.5 * (2.5*(nir - red) - 1.3*(nir - green))) ./ ...
    (sqrt((2*nir + 1).^2 - (6*nir - 5*red) - 0.5) + eps);
indices.MSR = ((nir./(red + eps)) - 1) ./ (sqrt(nir./(red + eps) + 1) + eps);
indices.MSAVI = real((2*nir + 1 - sqrt((2*nir + 1).^2 - 8*(nir - red))) / 2); % real() needed due to potential negative values under sqrt
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
indices.TVI = real(sqrt(indices.NDVI + 0.5)); % real() needed due to potential negative values under sqrt
indices.VREI = red ./ (red_edge + eps);

% Calculate means for each index using the mask
means = struct();
field_names = fieldnames(indices);
for i = 1:length(field_names)
    current_index = indices.(field_names{i});
    means.(field_names{i}) = mean(current_index(mask > 0));
end

% Display results in multiple figures
% Figure 1: Basic RGB and Primary Indices
figure('Name', 'Primary Vegetation Indices', 'WindowState', 'maximized');
subplot(3,3,1); imshow(cat(3, red./max(red(:)), green./max(green(:)), blue./max(blue(:)))); title('RGB Image');
subplot(3,3,2); imshow(indices.NDVI, []); title('NDVI'); colorbar;
subplot(3,3,3); imshow(indices.EVI, []); title('EVI'); colorbar;
subplot(3,3,4); imshow(indices.SAVI, []); title('SAVI'); colorbar;
subplot(3,3,5); imshow(indices.NDRE, []); title('NDRE'); colorbar;
subplot(3,3,6); imshow(indices.DVI, []); title('DVI'); colorbar;
subplot(3,3,7); imshow(indices.MSAVI, []); title('MSAVI'); colorbar;
subplot(3,3,8); imshow(indices.OSAVI, []); title('OSAVI'); colorbar;
subplot(3,3,9); imshow(indices.TVI, []); title('TVI'); colorbar;

% Figure 2: Modified and Advanced Indices
figure('Name', 'Modified and Advanced Indices', 'WindowState', 'maximized');
subplot(3,3,1); imshow(indices.MCARI1, []); title('MCARI1'); colorbar;
subplot(3,3,2); imshow(indices.MCARI2, []); title('MCARI2'); colorbar;
subplot(3,3,3); imshow(indices.MSR, []); title('MSR'); colorbar;
subplot(3,3,4); imshow(indices.MTVI1, []); title('MTVI1'); colorbar;
subplot(3,3,5); imshow(indices.MTVI2, []); title('MTVI2'); colorbar;
subplot(3,3,6); imshow(indices.RDVI, []); title('RDVI'); colorbar;
subplot(3,3,7); imshow(indices.TVI, []); title('TVI'); colorbar;
subplot(3,3,8); imshow(indices.VREI, []); title('VREI'); colorbar;
subplot(3,3,9); imshow(indices.NRVI, []); title('NRVI'); colorbar;

% Figure 3: Color-based and Ratio Indices
figure('Name', 'Color-based and Ratio Indices', 'WindowState', 'maximized');
subplot(3,3,1); imshow(indices.BNDVI, []); title('BNDVI'); colorbar;
subplot(3,3,2); imshow(indices.GI, []); title('GI'); colorbar;
subplot(3,3,3); imshow(indices.GNDVI, []); title('GNDVI'); colorbar;
subplot(3,3,4); imshow(indices.GRVI, []); title('GRVI'); colorbar;
subplot(3,3,5); imshow(indices.IRVI, []); title('IRVI'); colorbar;
subplot(3,3,6); imshow(indices.NGRDI, []); title('NGRDI'); colorbar;
subplot(3,3,7); imshow(indices.SR, []); title('SR'); colorbar;

% Display means
disp('Mean values of vegetation indices in masked area:');
for i = 1:length(field_names)
    fprintf('%s: %.4f\n', field_names{i}, means.(field_names{i}));
end
end
