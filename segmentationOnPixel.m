function segmentationOnPixel()
    % Ottieni la lista di tutti i file .img nella cartella
    folder = 'c:\Users\mario\Desktop\ImageProcessing';
    files = dir(fullfile(folder, '*.img'));
    
    % Processa ogni file
    for i = 1:length(files)
        % Estrai il nome base del file (senza estensione)
        [~, baseName, ~] = fileparts(files(i).name);
        fprintf('\nProcessing file: %s\n', baseName);
        
        try
            % Carica l'immagine iperspettrale
            [data, info] = enviread(fullfile(folder, baseName));
            fprintf('File caricato con successo!\n');
            
            % Crea una sottocartella per i risultati
            resultFolder = fullfile(folder, 'results', baseName);
            if ~exist(resultFolder, 'dir')
                mkdir(resultFolder);
            end
            
            % Esegui la segmentazione
            processImage(data, info, resultFolder);
            
        catch err
            fprintf('Errore nel processare %s: %s\n', baseName, err.message);
            continue;
        end
    end
end

function processImage(data, info, resultFolder)
    % Ottieni le dimensioni dell'immagine
    [rows, cols, bands] = size(data);
    
    % Converti i dati in double per il processing
    data = double(data);
    
    % 1. Metodo: Thresholding semplice sulla banda NIR (banda 35 - ~865nm)
    nirBand = data(:,:,35);
    simpleThresh = nirBand > mean(nirBand(:));
    
    % 2. Metodo: Otsu thresholding
    level = graythresh(mat2gray(nirBand));
    otsuThresh = imbinarize(mat2gray(nirBand), level);
    
    % 3. Metodo: K-means clustering
    selectedBands = data(:,:,[35 20 13]);
    reshapedData = reshape(selectedBands, rows*cols, 3);
    
    [idx, centroids] = kmeans(reshapedData, 3, 'Distance', 'sqeuclidean', ...
        'Replicates', 3);
    kmeansResult = reshape(idx, rows, cols);
    
    % Visualizza e salva i risultati
    saveResults(data, simpleThresh, otsuThresh, kmeansResult, resultFolder);
end

function saveResults(data, simpleThresh, otsuThresh, kmeansResult, resultFolder)
    % Crea la figura
    fig = figure('Name', 'Segmentazione basata su pixel', 'Visible', 'off');
    
    % Visualizza immagine originale (RGB)
    subplot(2,2,1);
    rgbImg = data(:,:,[20 13 6]);
    rgbImg = mat2gray(rgbImg);
    imshow(rgbImg);
    title('Immagine RGB originale');
    
    % Visualizza risultati delle tre tecniche
    subplot(2,2,2);
    imshow(simpleThresh);
    title('Thresholding Semplice');
    
    subplot(2,2,3);
    imshow(otsuThresh);
    title('Otsu Thresholding');
    
    subplot(2,2,4);
    imagesc(kmeansResult);
    colormap('jet');
    colorbar;
    title('K-means Clustering');
    
    % Salva la figura
    saveas(fig, fullfile(resultFolder, 'segmentation_results.png'));
    
    % Salva i risultati numerici
    save(fullfile(resultFolder, 'segmentation_results.mat'), ...
        'simpleThresh', 'otsuThresh', 'kmeansResult');
    
    % Calcola e salva le metriche in un file di testo
    fid = fopen(fullfile(resultFolder, 'metrics.txt'), 'w');
    fprintf(fid, 'Analisi dei risultati:\n');
    fprintf(fid, '1. Thresholding Semplice - Percentuale area vegetazione: %.2f%%\n', ...
        100 * sum(simpleThresh(:))/numel(simpleThresh));
    fprintf(fid, '2. Otsu Thresholding - Percentuale area vegetazione: %.2f%%\n', ...
        100 * sum(otsuThresh(:))/numel(otsuThresh));
    fclose(fid);
    
    close(fig);
end

function [data, info] = enviread(filename)
    % Leggi il file header
    info = envihdrread([filename '.hdr']);
    
    % Apri il file binario
    fid = fopen([filename '.img'], 'rb'); % Aggiunto 'rb' per lettura binaria
    if fid == -1
        error('Cannot open image file.');
    end
    
    % Leggi i dati considerando il tipo di dato corretto (12 = uint16)
    data = fread(fid, [info.samples * info.lines, info.bands], 'uint16=>uint16');
    
    % Riorganizza i dati considerando il formato BSQ
    data = reshape(data, [info.samples, info.lines, info.bands]);
    data = permute(data, [2 1 3]);
    
    fclose(fid);
end

function info = envihdrread(filename)
    % Leggi il file header ENVI
    info = struct();
    fid = fopen(filename, 'r');
    
    while ~feof(fid)
        line = fgetl(fid);
        if contains(line, '=')
            [param, value] = strtok(line, '=');
            param = strtrim(param);
            value = strtrim(value(2:end));
            
            % Converti stringhe numeriche in numeri
            if strcmp(param, 'samples') || strcmp(param, 'lines') || ...
               strcmp(param, 'bands')
                info.(param) = str2double(value);
            else
                info.(param) = value;
            end
        end
    end
    fclose(fid);
end