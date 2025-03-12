% Check if SPM is in the path
if ~exist('spm_vol', 'file')
    % SPM is not in the path
    addSPMtoPath();
end

try
    V = spm_vol('ulivo_campo.hdr');
    [Y,XYZ] = spm_read_vols(V);

    % Display the image
    figure;
    imagesc(Y);
    colormap gray;
    axis image;
    title('Image: ulivo_campo');
catch err
    fprintf('Error: %s\n', err.message);
    fprintf('Make sure SPM is installed and the image file exists.\n');
end
