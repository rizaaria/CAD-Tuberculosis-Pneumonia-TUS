% mat2txt.m
clc; clear; close all;

% ===============================
% PATH
% ===============================
matFile = 'D:\RIZ\Anotasi\MAT\2105.mat';
imgFolder = 'D:\RIZ\JPG\21_JPG\2105';
outputFolder = 'D:\RIZ\Anotasi\YOLO\BB\2105';

if ~exist(outputFolder,'dir')
    mkdir(outputFolder);
end

% ===============================
% LOAD GROUND TRUTH
% ===============================
data = load(matFile);
gTruth = data.gTruth;
labelData = gTruth.LabelData;

totalData = height(labelData);
disp(['Total data: ', num2str(totalData)]);
disp('Convert ke YOLO...');

% ===============================
% MAIN LOOP
% ===============================
for i = 1:totalData

    name = sprintf('frame_%04d', i);
    imgFullPath = fullfile(imgFolder, [name '.jpg']);

    if ~isfile(imgFullPath)
        disp(['Tidak ditemukan: ', imgFullPath]);
        continue;
    end

    img = imread(imgFullPath);
    [H,W,~] = size(img);

    txtFile = fullfile(outputFolder, [name '.txt']);
    fileID = fopen(txtFile,'w');

    if fileID == -1
        error(['Gagal membuat file: ', txtFile]);
    end

    % ===============================
    % CLASS MAPPING SESUAI YAML
    % ===============================
    if ismember('kavitas', labelData.Properties.VariableNames)
        processClass(labelData.kavitas{i},0,W,H,fileID);
    end

    if ismember('pola_b', labelData.Properties.VariableNames)
        processClass(labelData.pola_b{i},1,W,H,fileID);
    end

    if ismember('konsolidasi', labelData.Properties.VariableNames)
        processClass(labelData.konsolidasi{i},2,W,H,fileID);
    end

    if ismember('penebalan_pleura', labelData.Properties.VariableNames)
        processClass(labelData.penebalan_pleura{i},3,W,H,fileID);
    end

    if ismember('bullae', labelData.Properties.VariableNames)
        processClass(labelData.bullae{i},4,W,H,fileID);
    end

    if ismember('infiltrat_terkonsolidasi', labelData.Properties.VariableNames)
        processClass(labelData.infiltrat_terkonsolidasi{i},5,W,H,fileID);
    end

    if ismember('pleura_ireguler', labelData.Properties.VariableNames)
        processClass(labelData.pleura_ireguler{i},6,W,H,fileID);
    end

    fclose(fileID);

    disp(['Saved: ', name, '.txt']);
end

disp('SELESAI');

% ============================================================
% FUNCTION: PROCESS CLASS
% ============================================================
function processClass(dataClass,classID,W,H,fileID)

    if isempty(dataClass)
        return
    end

    % ===============================
    % CELL (polygon)
    % ===============================
    if iscell(dataClass)
        for k = 1:length(dataClass)
            poly = dataClass{k};
            writeBBoxFromPolygon(poly,classID,W,H,fileID);
        end

    % ===============================
    % POLYGON Nx2
    % ===============================
    elseif size(dataClass,2) == 2
        writeBBoxFromPolygon(dataClass,classID,W,H,fileID);

    % ===============================
    % BBOX Nx4
    % ===============================
    elseif size(dataClass,2) == 4
        for b = 1:size(dataClass,1)
            bbox = dataClass(b,:);
            writeYOLO(bbox,classID,W,H,fileID);
        end

    % ===============================
    % OBB Nx5 → convert ke AABB
    % ===============================
    elseif size(dataClass,2) == 5
        for b = 1:size(dataClass,1)
            obb = dataClass(b,:);
            bbox = obb2aabb(obb);
            writeYOLO(bbox,classID,W,H,fileID);
        end
    end
end

% ============================================================
% FUNCTION: POLYGON → AABB
% ============================================================
function writeBBoxFromPolygon(poly,classID,W,H,fileID)

    if isempty(poly)
        return
    end

    x_min = min(poly(:,1));
    y_min = min(poly(:,2));
    x_max = max(poly(:,1));
    y_max = max(poly(:,2));

    bbox = [x_min y_min x_max-x_min y_max-y_min];

    writeYOLO(bbox,classID,W,H,fileID);
end

% ============================================================
% FUNCTION: OBB → AABB
% ============================================================
function bbox = obb2aabb(obb)
% Format: [cx cy w h angle(degree)]

    cx = obb(1);
    cy = obb(2);
    w  = obb(3);
    h  = obb(4);
    angle = deg2rad(obb(5));

    corners = [
        -w/2, -h/2;
         w/2, -h/2;
         w/2,  h/2;
        -w/2,  h/2
    ];

    R = [cos(angle) -sin(angle); sin(angle) cos(angle)];
    rotated = (R * corners')';

    rotated(:,1) = rotated(:,1) + cx;
    rotated(:,2) = rotated(:,2) + cy;

    x_min = min(rotated(:,1));
    y_min = min(rotated(:,2));
    x_max = max(rotated(:,1));
    y_max = max(rotated(:,2));

    bbox = [x_min, y_min, x_max-x_min, y_max-y_min];
end

% ============================================================
% FUNCTION: WRITE YOLO FORMAT
% ============================================================
function writeYOLO(bbox,classID,W,H,fileID)

    x_center = (bbox(1) + bbox(3)/2) / W;
    y_center = (bbox(2) + bbox(4)/2) / H;
    bw = bbox(3) / W;
    bh = bbox(4) / H;

    fprintf(fileID,'%d %.6f %.6f %.6f %.6f\n', ...
        classID,x_center,y_center,bw,bh);
end