% filepath: /c:/Users/Valerio/Mega/Uni/Image Processing - Computer Vision I/ImageProcessing/ulivo2.m
% Read ulivo_campo.hdr and ulivo_campo.img file
fprintf('Reading ulivo_campo image files...\n');

% Define filenames
filename = 'ulivo_campo';
hdrFile = [filename '.hdr'];
imgFile = [filename '.img'];

% Read the header file to extract necessary information
fileID = fopen(hdrFile, 'r');
if fileID == -1
    error('Cannot open the header file. Make sure it exists in the current directory.');
end

% Initialize variables
samples = 0;
lines = 0;
bands = 0;
dataType = '';
interleave = '';
byteOrder = '';

% Parse the header file
tline = fgetl(fileID);
while ischar(tline)
    % Improved parsing logic
    if contains(lower(tline), 'samples')
        % Extract everything after the equals sign and convert to number
        eq_pos = strfind(tline, '=');
        if ~isempty(eq_pos)
            samples = str2double(strtrim(tline(eq_pos(1)+1:end)));
        end
    elseif contains(lower(tline), 'lines')
        eq_pos = strfind(tline, '=');
        if ~isempty(eq_pos)
            lines = str2double(strtrim(tline(eq_pos(1)+1:end)));
        end
    elseif contains(lower(tline), 'bands') && ~contains(lower(tline), 'default bands')
        eq_pos = strfind(tline, '=');
        if ~isempty(eq_pos)
            bands = str2double(strtrim(tline(eq_pos(1)+1:end)));
        end
    elseif contains(lower(tline), 'data type')
        eq_pos = strfind(tline, '=');
        if ~isempty(eq_pos)
            dataType = strtrim(tline(eq_pos(1)+1:end));
        end
    elseif contains(lower(tline), 'interleave')
        eq_pos = strfind(tline, '=');
        if ~isempty(eq_pos)
            interleave = lower(strtrim(tline(eq_pos(1)+1:end)));
        end
    elseif contains(lower(tline), 'byte order')
        eq_pos = strfind(tline, '=');
        if ~isempty(eq_pos)
            byteOrder = strtrim(tline(eq_pos(1)+1:end));
        end
    end
    tline = fgetl(fileID);
end
fclose(fileID);

% Report what we found in the header
fprintf('Header information:\n');
fprintf('  - Samples: %d\n', samples);
fprintf('  - Lines: %d\n', lines);
fprintf('  - Bands: %d\n', bands);
fprintf('  - Data Type: %s\n', dataType);
fprintf('  - Interleave: %s\n', interleave);
fprintf('  - Byte Order: %s\n', byteOrder);

% Check if we have all necessary information
if samples == 0 || lines == 0 || bands == 0
    error('Could not extract all necessary information from header file.');
end

% Map ENVI data types to MATLAB data types
if isempty(dataType)
    precision = 'uint8';
    fprintf('Data type not specified, defaulting to uint8\n');
else
    switch dataType
        case '1'
            precision = 'uint8';
        case '2'
            precision = 'int16';
        case '3'
            precision = 'int32';
        case '4'
            precision = 'single';
        case '5'
            precision = 'double';
        case '12'
            precision = 'uint16';
        case '13'
            precision = 'uint32';
        otherwise
            precision = 'uint8';
            fprintf('Unsupported data type %s, defaulting to uint8\n', dataType);
    end
end

% Default to BSQ if interleave is not specified
if isempty(interleave)
    interleave = 'bsq';
    fprintf('Interleave not specified, defaulting to BSQ\n');
end

% Default to little-endian if byte order is not specified
if isempty(byteOrder)
    byteOrder = 'ieee-le';
    fprintf('Byte order not specified, defaulting to little-endian\n');
else
    if strcmp(byteOrder, '0')
        byteOrder = 'ieee-le'; % little-endian
    else
        byteOrder = 'ieee-be'; % big-endian
    end
end

% Read the image data
try
    fprintf('Reading image data...\n');
    img = multibandread(imgFile, [lines, samples, bands], precision, 0, interleave, byteOrder);
    fprintf('Image read successfully.\n');

    % Display the first band
    figure;
    imagesc(img(:,:,1));
    colormap gray;
    title('First band of ulivo\_campo image');
    colorbar;

    % If it's an RGB image (3 or more bands), show as color composite
    if bands >= 3
        figure;
        % Create RGB composite using first three bands
        rgbImg = zeros(lines, samples, 3);
        for i = 1:3
            band = img(:,:,i);
            rgbImg(:,:,i) = (band - min(band(:))) / (max(band(:)) - min(band(:)));
        end
        imshow(rgbImg);
        title('RGB composite using first three bands');
    end

    % Store the image in a variable
    ulivo_campo = img;
    fprintf('Image stored in variable ulivo_campo\n');
catch e
    fprintf('Error reading image file: %s\n', e.message);
end
