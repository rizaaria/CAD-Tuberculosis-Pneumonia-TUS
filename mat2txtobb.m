% =====================================================
% KONVERSI groundTruth .mat → YOLO OBB FORMAT
% =====================================================

matFolder  = 'D:\RIZ\Anotasi\MAT';          % folder .mat
imgFolder  = 'D:\RIZ\DCM\21\Crop';           % folder gambar aktual
outputBase = 'D:\RIZ\Anotasi\YOLO\OBB';

matList = dir(fullfile(matFolder, '*.mat'));

classNames = {'kavitas','pola_b','konsolidasi','penebalan_pleura',...
              'bullae','infltrat_terkonsolidasi','pleura_ireguler','normal'};
classMap   = containers.Map(classNames, {0,1,2,3,4,5,6,7});

for f = 1:length(matList)

    matPath = fullfile(matFolder, matList(f).name);
    [~, matName, ~] = fileparts(matList(f).name);
    fprintf('\n=== %s ===\n', matList(f).name);

    % Load dengan suppress warning dulu
    warnState = warning('off','all');
    raw = load(matPath);
    warning(warnState);

    fn     = fieldnames(raw);
    gTruth = raw.(fn{1});

    if ~isprop(gTruth, 'LabelData')
        warning('Bukan groundTruth: %s', matList(f).name);
        continue;
    end

    % ── Remap path gambar ──────────────────────────────
    try
        oldSrc = gTruth.DataSource.Source;
        if ischar(oldSrc), oldSrc = cellstr(oldSrc); end

        newSrc = cell(size(oldSrc));
        for k = 1:length(oldSrc)
            [~, nm, ext] = fileparts(oldSrc{k});
            % Coba .jpg dulu, fallback ke ekstensi asli
            jpgPath = fullfile(imgFolder, [nm '.jpg']);
            if exist(jpgPath, 'file')
                newSrc{k} = jpgPath;
            else
                newSrc{k} = fullfile(imgFolder, [nm ext]);
            end
        end

        gTruth = changeFilePaths(gTruth, oldSrc, newSrc);
        imageFiles = gTruth.DataSource.Source;
        if ischar(imageFiles), imageFiles = cellstr(imageFiles); end

    catch ME
        warning('changeFilePaths gagal (%s), pakai fallback.', ME.message);
        % Fallback: generate nama dari LabelData row index
        nFrames    = height(gTruth.LabelData);
        imageFiles = cell(nFrames, 1);
        for k = 1:nFrames
            imageFiles{k} = fullfile(imgFolder, sprintf('%s_%03d.jpg', matName, k));
        end
    end

    labelData  = gTruth.LabelData;
    labelCols  = labelData.Properties.VariableNames;

    outFolder = fullfile(outputBase, matName);
    if ~exist(outFolder, 'dir'), mkdir(outFolder); end

    % ── Loop per frame ─────────────────────────────────
    for i = 1:height(labelData)

        [~, imgName, imgExt] = fileparts(imageFiles{i});

        % Baca ukuran gambar
        W = 1024; H = 768;
        imgPath = fullfile(imgFolder, [imgName imgExt]);
        if ~exist(imgPath, 'file')
            % Coba ekstensi lain
            for ext = {'.jpg','.png','.bmp','.dcm'}
                tryPath = fullfile(imgFolder, [imgName ext{1}]);
                if exist(tryPath, 'file')
                    imgPath = tryPath;
                    imgExt  = ext{1};
                    break;
                end
            end
        end
        if exist(imgPath, 'file')
            try
                info = imfinfo(imgPath);
                W = info.Width; H = info.Height;
            catch, end
        end

        txtPath = fullfile(outFolder, [imgName '.txt']);
        fid     = fopen(txtPath, 'w');
        hasLabel = false;

        for c = 1:length(labelCols)
            colName = labelCols{c};

            % Skip kolom yang bukan class kita
            if ~isKey(classMap, colName), continue; end

            boxes = labelData.(colName){i};
            if isempty(boxes), continue; end

            hasLabel = true;
            classID  = classMap(colName);

            for b = 1:size(boxes, 1)
                cx    = boxes(b,1); cy = boxes(b,2);
                w     = boxes(b,3); h  = boxes(b,4);
                theta = deg2rad(boxes(b,5));

                R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
                corners = [-w/2 -h/2; w/2 -h/2; w/2 h/2; -w/2 h/2];
                pts = (R * corners')' + [cx cy];

                pts(:,1) = pts(:,1) / W;
                pts(:,2) = pts(:,2) / H;

                fprintf(fid, '%d %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f\n', ...
                    classID, ...
                    pts(1,1), pts(1,2), pts(2,1), pts(2,2), ...
                    pts(3,1), pts(3,2), pts(4,1), pts(4,2));
            end
        end

        fclose(fid);

        if hasLabel
            fprintf('  ✓ %s.txt\n', imgName);
        else
            fprintf('  ○ %s.txt\n', imgName);
        end
    end

    fprintf('Selesai: %s (%d frames)\n', matName, height(labelData));
end

disp('SEMUA SELESAI!');