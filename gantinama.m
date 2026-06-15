% gantinama.m
clc;
clear;

% =========================================
% ===== KONFIGURASI (EDIT DI SINI) =====
% =========================================
basePath   = 'D:\RIZ\DCM\';
oldFolder  = 'Mega_37th_67939134970828_'; % folder lama
newFolder  = '22';                          % folder baru
prefixName = '22';                          % prefix file (1201,1202,...)
% =========================================

oldPath = fullfile(basePath, oldFolder);
newPath = fullfile(basePath, newFolder);

% ===== CEK FOLDER =====
if ~isfolder(oldPath)
    error('Folder asal tidak ditemukan!');
end

% ===== BUAT FOLDER BARU =====
if ~exist(newPath,'dir')
    mkdir(newPath);
end

% ===== AMBIL FILE =====
files = dir(fullfile(oldPath, '*.dcm'));

if isempty(files)
    error('Tidak ada file .dcm ditemukan!');
end

fprintf('Mulai rename + pindah folder...\n\n');

for i = 1:length(files)

    oldName = files(i).name;
    oldFullPath = fullfile(oldPath, oldName);

    % ===== FORMAT NAMA BARU =====
    newName = sprintf('%s%02d.dcm', prefixName, i);
    newFullPath = fullfile(newPath, newName);

    % ===== HANDLE DUPLIKAT =====
    if exist(newFullPath, 'file')
        warning('File sudah ada, skip: %s', newName);
        continue;
    end

    % ===== PINDAH + RENAME =====
    movefile(oldFullPath, newFullPath);

    fprintf('Moved: %s -> %s\n', oldName, newName);
end

fprintf('\n=== SELESAI ===\n');