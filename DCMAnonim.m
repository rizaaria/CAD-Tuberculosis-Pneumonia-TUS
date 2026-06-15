clc; clear;

inputFolder  = 'D:\RIZ\DCM\Mega_37th_67939134970828_';
outputFolder = 'D:\RIZ\DCM\Hasil Crop';

if ~exist(outputFolder,'dir'), mkdir(outputFolder); end

files = dir(fullfile(inputFolder,'*.dcm'));

% =======================================================
% ===== MASUKKAN PARAMETER HASIL TUNING DI SINI =====
% =======================================================
fanCenterX_Set = 512;
fanCenterY_Set = -230;

radiusTop_Set  = 321;
radiusBot_Set  = 1005;

thetaLeft_Set  = 35.9;
thetaRight_Set = 33.8;

% 🔥 TAMBAHAN BARU (WAJIB dari GUI terbaru)
offsetLeft_Set  = 51.1;
offsetRight_Set = -46.0;
% =======================================================

for i = 1:length(files)

    info = dicominfo(fullfile(inputFolder,files(i).name));
    img  = dicomread(info);

    if ndims(img)==2
        img = reshape(img,size(img,1),size(img,2),1);
    end

    [rows,cols,nFrames] = size(img);

    % ===== PRECOMPUTE GRID =====
    [X,Y] = meshgrid(1:cols,1:rows);

    dx = X - fanCenterX_Set;
    dy = Y - fanCenterY_Set;

    R = sqrt(dx.^2 + dy.^2);

    % ===================================================
    % 🔥 GANTI TOTAL LOGIKA SUDUT → GARIS + OFFSET
    % ===================================================
    leftBound  = dx >= (-tand(thetaLeft_Set) * dy + offsetLeft_Set);
    rightBound = dx <= ( tand(thetaRight_Set) * dy + offsetRight_Set);

    fanMask = (R >= radiusTop_Set) & ...
        (R <= radiusBot_Set) & ...
        leftBound & ...
        rightBound & ...
        (dy > 0);

    % ===== APPLY MASK =====
    img_clean = img;

    for f = 1:nFrames
        frame = double(img(:,:,f));
        frame(~fanMask) = 0;
        img_clean(:,:,f) = cast(frame,class(img));
    end

    % ===== SIMPAN =====
    if isfield(info,'PixelData'), info = rmfield(info,'PixelData'); end

    outName = sprintf('22%02d.dcm',i);
    dicomwrite(img_clean,fullfile(outputFolder,outName),info,'CreateMode','Copy');

    fprintf('Processed: %s\n', files(i).name);
end

disp('=== Selesai (Versi Offset FIX) ===');
