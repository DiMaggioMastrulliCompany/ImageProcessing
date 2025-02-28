% Basic MATLAB script to read and display a TIF file (with potential multiple bands)
function main()
% Read the TIF file
[data, ~] = imread('20240801_ulivo_bandeRED.tif');

% Get information about the data
[rows, cols, bands] = size(data);
fprintf('Image dimensions: %d rows x %d columns with %d bands\n', rows, cols, bands);

% Check data type
fprintf('Data type: %s\n', class(data));

% If multiple bands, display each separately
if bands > 1
    for b = 1:bands
        figure;
        imagesc(data(:,:,b));
        colormap gray;
        colorbar;
        title(['Band ' num2str(b)]);
    end
else
    % Single band display
    figure;
    imagesc(data);
    colormap gray;
    colorbar;
    title('Image Data');
end

% Display histogram to see data distribution
figure;
if bands > 1
    for b = 1:bands
        subplot(bands, 1, b);
        histogram(double(data(:,:,b)));
        title(['Histogram for Band ' num2str(b)]);
    end
else
    histogram(double(data));
    title('Data Histogram');
end
end
