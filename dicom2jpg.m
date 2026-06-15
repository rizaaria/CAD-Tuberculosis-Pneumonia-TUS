% dicom2jpg.m
clc; clear;

% ===============================
% PATH FOLDER
% ===============================
inputFolder  = 'D:\RIZ\DCM\Mega_37th_67939134970828_';
outputFolder = 'D:\RIZ\DCM\Hasil Crop';

if ~exist(outputFolder,'dir')
    mkdir(outputFolder);
end

% ===============================
% AMBIL SEMUA FILE DICOM (REKURSIF)
% ===============================
dicomFiles = dir(fullfile(inputFolder,'**','*.dcm'));
fprintf('Total DICOM ditemukan: %d\n\n', length(dicomFiles));

% ===============================
% LOOP SEMUA FILE DICOM
% ===============================
for f = 1:length(dicomFiles)

    dicomPath = fullfile(dicomFiles(f).folder, dicomFiles(f).name);
    fprintf('Processing: %s\n', dicomPath);

    img = dicomread(dicomPath);
    sz  = size(img);

    % ===============================
    % BUAT FOLDER OUTPUT SESUAI STRUKTUR
    % ===============================
    relPath = erase(dicomFiles(f).folder, inputFolder);
    saveDir = fullfile(outputFolder, relPath, dicomFiles(f).name(1:end-4));

    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end

    % ===============================
    % JUMLAH FRAME (DIMENSI TERAKHIR)
    % ===============================
    numFrames = sz(end);
    fprintf('  Jumlah frame: %d\n', numFrames);

    % ===============================
    % SIMPAN SEMUA FRAME
    % ===============================
    for i = 1:numFrames
        if ndims(img) == 4
            frame = img(:,:,:,i);   % RGB multi-frame
        else
            frame = img(:,:,i);     % grayscale multi-frame
        end

        imwrite(frame, ...
            fullfile(saveDir, sprintf('frame_%04d.jpg', i)));
    end

    fprintf('  -> selesai\n\n');
end

disp('SEMUA FILE DICOM (TERMASUK SUBFOLDER) BERHASIL DIEKSTRAK 🎉');