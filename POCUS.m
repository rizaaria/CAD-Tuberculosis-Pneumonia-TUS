function teleUSG_full_auto()

clc;
clear;
close all;

% =========================================================
% ==================== PILIH INPUT =========================
% =========================================================
inputFolder = uigetdir(pwd,'Pilih Folder DCM Input');

if isequal(inputFolder,0)
    error('Folder input tidak dipilih');
end

% =========================================================
% ==================== OUTPUT DCM ==========================
% =========================================================
dcmOutputFolder = uigetdir( ...
    pwd, ...
    'Pilih Folder Output DCM');

if isequal(dcmOutputFolder,0)
    error('Folder output DCM tidak dipilih');
end

% =========================================================
% ==================== OUTPUT JPG ==========================
% =========================================================
jpgOutputFolder = uigetdir( ...
    pwd, ...
    'Pilih Folder Output JPG');

if isequal(jpgOutputFolder,0)
    error('Folder output JPG tidak dipilih');
end

% =========================================================
% ==================== PREFIX ==============================
% =========================================================
answer = inputdlg( ...
    {'Masukkan prefix dataset (contoh: 22 atau 23)'}, ...
    'Prefix Dataset', ...
    [1 50], ...
    {'22'});

if isempty(answer)
    error('Prefix tidak diisi');
end

prefixName = answer{1};

% =========================================================
% ===== AMBIL FILE DCM
% =========================================================
files = dir(fullfile(inputFolder,'*.dcm'));

if isempty(files)
    error('Tidak ada file DCM ditemukan');
end

% =========================================================
% ===== LOAD SAMPLE
% =========================================================
sampleFile = fullfile(inputFolder,files(1).name);

info = dicominfo(sampleFile);

imgRaw = dicomread(info);

imgRaw = squeeze(imgRaw);

if ndims(imgRaw)==2

    img = double(imgRaw);

elseif ndims(imgRaw)==3

    img = double(imgRaw(:,:,1));

elseif ndims(imgRaw)==4

    img = double(imgRaw(:,:,:,1));

else

    error('Format DICOM tidak dikenali');

end

if ndims(img)==3
    previewImg = rgb2gray(uint8(img));
else
    previewImg = img;
end

[rows,cols] = size(previewImg);

defaultCenterX = round(cols/2);

% =========================================================
% ======================= GUI ==============================
% =========================================================
f = figure( ...
    'Name','TeleUSG Full Auto Processor', ...
    'Position',[50 50 1350 950]);

ax = axes('Parent',f,'Position',[0.05 0.42 0.9 0.53]);

imshow(previewImg,[],'Parent',ax);
hold(ax,'on');

% =========================================================
% ===== OVERLAY
% =========================================================
redMask = cat(3,ones(rows,cols),zeros(rows,cols),zeros(rows,cols));

hOverlay = imshow(redMask,'Parent',ax);

set(hOverlay,'AlphaData',zeros(rows,cols));

% =========================================================
% ===== LABEL INFO
% =========================================================
lblResult = uicontrol( ...
    'Style','text', ...
    'Position',[20 360 1250 40], ...
    'FontSize',11, ...
    'FontWeight','bold', ...
    'ForegroundColor','blue');

% =========================================================
% ===== CENTER X
% =========================================================
uicontrol('Style','text','Position',[20 300 120 20], ...
    'String','Center X');

sldX = uicontrol( ...
    'Style','slider', ...
    'Min',0,'Max',cols, ...
    'Value',defaultCenterX, ...
    'Position',[150 300 300 20], ...
    'Callback',@updateMask);

% =========================================================
% ===== CENTER Y
% =========================================================
uicontrol('Style','text','Position',[20 260 120 20], ...
    'String','Center Y');

sldY = uicontrol( ...
    'Style','slider', ...
    'Min',-1500,'Max',rows, ...
    'Value',-230, ...
    'Position',[150 260 300 20], ...
    'Callback',@updateMask);

% =========================================================
% ===== TOP RADIUS X
% =========================================================
uicontrol('Style','text','Position',[20 220 120 20], ...
    'String','Top Radius X');

sldTopX = uicontrol( ...
    'Style','slider', ...
    'Min',1,'Max',1000, ...
    'Value',320, ...
    'Position',[150 220 300 20], ...
    'Callback',@updateMask);

% =========================================================
% ===== TOP RADIUS Y
% =========================================================
uicontrol('Style','text','Position',[20 180 120 20], ...
    'String','Top Radius Y');

sldTopY = uicontrol( ...
    'Style','slider', ...
    'Min',1,'Max',1000, ...
    'Value',320, ...
    'Position',[150 180 300 20], ...
    'Callback',@updateMask);

% =========================================================
% ===== BOTTOM RADIUS X
% =========================================================
uicontrol('Style','text','Position',[20 140 120 20], ...
    'String','Bottom Radius X');

sldBotX = uicontrol( ...
    'Style','slider', ...
    'Min',100,'Max',3000, ...
    'Value',1000, ...
    'Position',[150 140 300 20], ...
    'Callback',@updateMask);

% =========================================================
% ===== BOTTOM RADIUS Y
% =========================================================
uicontrol('Style','text','Position',[20 100 120 20], ...
    'String','Bottom Radius Y');

sldBotY = uicontrol( ...
    'Style','slider', ...
    'Min',100,'Max',3000, ...
    'Value',1000, ...
    'Position',[150 100 300 20], ...
    'Callback',@updateMask);

% =========================================================
% ===== LEFT ANGLE
% =========================================================
uicontrol('Style','text','Position',[520 300 120 20], ...
    'String','Left Angle');

sldAngL = uicontrol( ...
    'Style','slider', ...
    'Min',1,'Max',89, ...
    'Value',35, ...
    'Position',[650 300 300 20], ...
    'Callback',@updateMask);

% =========================================================
% ===== RIGHT ANGLE
% =========================================================
uicontrol('Style','text','Position',[520 260 120 20], ...
    'String','Right Angle');

sldAngR = uicontrol( ...
    'Style','slider', ...
    'Min',1,'Max',89, ...
    'Value',35, ...
    'Position',[650 260 300 20], ...
    'Callback',@updateMask);

% =========================================================
% ===== LEFT OFFSET
% =========================================================
uicontrol('Style','text','Position',[520 220 120 20], ...
    'String','Left Offset');

sldOffL = uicontrol( ...
    'Style','slider', ...
    'Min',-1000,'Max',1000, ...
    'Value',50, ...
    'Position',[650 220 300 20], ...
    'Callback',@updateMask);

% =========================================================
% ===== RIGHT OFFSET
% =========================================================
uicontrol('Style','text','Position',[520 180 120 20], ...
    'String','Right Offset');

sldOffR = uicontrol( ...
    'Style','slider', ...
    'Min',-1000,'Max',1000, ...
    'Value',-50, ...
    'Position',[650 180 300 20], ...
    'Callback',@updateMask);

% =========================================================
% ===== ROTATION
% =========================================================
uicontrol('Style','text','Position',[520 140 120 20], ...
    'String','Fan Rotation');

sldRotate = uicontrol( ...
    'Style','slider', ...
    'Min',-90,'Max',90, ...
    'Value',0, ...
    'Position',[650 140 300 20], ...
    'Callback',@updateMask);

% =========================================================
% ===== PROCESS BUTTON
% =========================================================
uicontrol( ...
    'Style','pushbutton', ...
    'String','PROCESS ALL', ...
    'FontSize',12, ...
    'FontWeight','bold', ...
    'BackgroundColor',[0.2 0.8 0.2], ...
    'Position',[500 40 300 50], ...
    'Callback',@processAll);

% =========================================================
% ===== UPDATE MASK
% =========================================================
function updateMask(~,~)

    cX = round(get(sldX,'Value'));
    cY = round(get(sldY,'Value'));

    topRX = round(get(sldTopX,'Value'));
    topRY = round(get(sldTopY,'Value'));

    botRX = round(get(sldBotX,'Value'));
    botRY = round(get(sldBotY,'Value'));

    angL = get(sldAngL,'Value');
    angR = get(sldAngR,'Value');

    offL = get(sldOffL,'Value');
    offR = get(sldOffR,'Value');

    rotAngle = get(sldRotate,'Value');

    [X,Y] = meshgrid(1:cols,1:rows);

    dx = X - cX;
    dy = Y - cY;

    theta = deg2rad(rotAngle);

    rotX = dx * cos(theta) + dy * sin(theta);

    rotY = -dx * sin(theta) + dy * cos(theta);

    topEllipse = ...
        ((rotX.^2)/(topRX^2) + ...
         (rotY.^2)/(topRY^2));

    botEllipse = ...
        ((rotX.^2)/(botRX^2) + ...
         (rotY.^2)/(botRY^2));

    leftBound  = rotX >= (-tand(angL) * rotY + offL);

    rightBound = rotX <= ( tand(angR) * rotY + offR);

    mask = ...
        (topEllipse >= 1) & ...
        (botEllipse <= 1) & ...
        leftBound & ...
        rightBound & ...
        (rotY > 0);

    set(hOverlay,'AlphaData',~mask * 0.5);

end

% =========================================================
% ===== PROCESS ALL
% =========================================================
function processAll(~,~)

    cX = round(get(sldX,'Value'));
    cY = round(get(sldY,'Value'));

    topRX = round(get(sldTopX,'Value'));
    topRY = round(get(sldTopY,'Value'));

    botRX = round(get(sldBotX,'Value'));
    botRY = round(get(sldBotY,'Value'));

    angL = get(sldAngL,'Value');
    angR = get(sldAngR,'Value');

    offL = get(sldOffL,'Value');
    offR = get(sldOffR,'Value');

    rotAngle = get(sldRotate,'Value');

    theta = deg2rad(rotAngle);

    waitbarHandle = waitbar(0,'Processing DICOM...');

    cropFolder = fullfile(dcmOutputFolder,'Crop');

    notCropFolder = fullfile(dcmOutputFolder,'Not Crop');

    if ~exist(cropFolder,'dir')
        mkdir(cropFolder);
    end

    if ~exist(notCropFolder,'dir')
        mkdir(notCropFolder);
    end

    if ~exist(jpgOutputFolder,'dir')
        mkdir(jpgOutputFolder);
    end

    % =====================================================
    % ===== LOOP FILE
    % =====================================================
    for i = 1:length(files)

        waitbar( ...
            i/length(files), ...
            waitbarHandle, ...
            sprintf('Processing %d/%d',i,length(files)));

        dicomPath = fullfile(inputFolder,files(i).name);

        info = dicominfo(dicomPath);

        img = dicomread(info);

        dims = size(img);

        if ndims(img) == 2

            rows2 = dims(1);
            cols2 = dims(2);
            nFrames = 1;
            isRGB = false;

        elseif ndims(img) == 3

            rows2 = dims(1);
            cols2 = dims(2);

            if dims(3) == 3

                nFrames = 1;
                isRGB = true;

            else

                nFrames = dims(3);
                isRGB = false;

            end

        elseif ndims(img) == 4

            rows2 = dims(1);
            cols2 = dims(2);

            nFrames = dims(4);
            isRGB = true;

        else

            error('Format DICOM tidak dikenali');

        end

        fprintf('File: %s | Frames: %d\n', ...
            files(i).name, nFrames);

        [X,Y] = meshgrid(1:cols2,1:rows2);

        dx = X - cX;
        dy = Y - cY;

        rotX = dx * cos(theta) + dy * sin(theta);

        rotY = -dx * sin(theta) + dy * cos(theta);

        topEllipse = ...
            ((rotX.^2)/(topRX^2) + ...
             (rotY.^2)/(topRY^2));

        botEllipse = ...
            ((rotX.^2)/(botRX^2) + ...
             (rotY.^2)/(botRY^2));

        leftBound  = rotX >= (-tand(angL) * rotY + offL);

        rightBound = rotX <= ( tand(angR) * rotY + offR);

        fanMask = ...
            (topEllipse >= 1) & ...
            (botEllipse <= 1) & ...
            leftBound & ...
            rightBound & ...
            (rotY > 0);

        img_clean = img;

        % =================================================
        % ===== APPLY MASK
        % =================================================
        for f = 1:nFrames

            if isRGB

                if ndims(img)==4
                    frame = double(img(:,:,:,f));
                else
                    frame = double(img);
                end

                for ch = 1:3

                    temp = frame(:,:,ch);

                    temp(~fanMask) = 0;

                    frame(:,:,ch) = temp;

                end

                if ndims(img)==4
                    img_clean(:,:,:,f) = cast(frame,class(img));
                else
                    img_clean = cast(frame,class(img));
                end

            else

                frame = double(img(:,:,f));

                frame(~fanMask) = 0;

                img_clean(:,:,f) = cast(frame,class(img));

            end

        end

        % =================================================
        % ===== FILE NAME
        % =================================================
        baseName = sprintf('%s%02d',prefixName,i);

        cropName = [baseName '-crop.dcm'];

        notCropName = [baseName '-notcrop.dcm'];

        % =================================================
        % ===== SAVE NOT CROP
        % =================================================
        infoNotCrop = info;

        if isfield(infoNotCrop,'PixelData')
            infoNotCrop = rmfield(infoNotCrop,'PixelData');
        end

        dicomwrite( ...
            img, ...
            fullfile(notCropFolder,notCropName), ...
            infoNotCrop, ...
            'CreateMode','Copy');

        % =================================================
        % ===== SAVE CROP
        % =================================================
        infoCrop = info;

        if isfield(infoCrop,'PixelData')
            infoCrop = rmfield(infoCrop,'PixelData');
        end

        dicomwrite( ...
            img_clean, ...
            fullfile(cropFolder,cropName), ...
            infoCrop, ...
            'CreateMode','Copy');

        % =================================================
        % ===== SAVE JPG
        % =================================================
        saveDir = fullfile(jpgOutputFolder,baseName);

        if ~exist(saveDir,'dir')
            mkdir(saveDir);
        end

        for f = 1:nFrames

            if isRGB

                if ndims(img_clean)==4
                    frame = img_clean(:,:,:,f);
                else
                    frame = img_clean;
                end

            else

                frame = img_clean(:,:,f);

            end

            frame = uint8(255 * mat2gray(frame));

            imwrite( ...
                frame, ...
                fullfile( ...
                saveDir, ...
                sprintf('frame_%04d.jpg',f)));

        end

        fprintf('Processed: %s\n',baseName);

    end

    close(waitbarHandle);

    msgbox('SEMUA FILE BERHASIL DIPROSES 🎉');

end

updateMask();

end