% tuningfan.m
function tuningfan_ultimate()
        clc;
    
        % === KONFIGURASI FOLDER ===
        folderName = 'D:\RIZ\DCM\22'; 
        files = dir(fullfile(folderName, '*.dcm'));
        if isempty(files), error('File tidak ditemukan!'); end
        filename = fullfile(folderName, files(1).name); 
        
        % === BACA GAMBAR ===
        info = dicominfo(filename);
        imgRaw = dicomread(info);
        imgRaw = squeeze(imgRaw); 
        
        if ndims(imgRaw) == 2
            img = double(imgRaw);
        elseif ndims(imgRaw) == 3
            img = double(imgRaw(:,:,1)); 
        elseif ndims(imgRaw) == 4
            img = double(imgRaw(:,:,1,1));
        else
            error('Format dimensi gambar tidak dikenali.');
        end
    
        [rows, cols] = size(img);
        defaultCenterX = round(cols / 2);
    
        % === GUI ===
        f = figure('Name', 'Kalibrasi Ultimate (OFFSET FIX)', 'Position', [50, 50, 1000, 820]);
        ax = axes('Parent', f, 'Position', [0.05, 0.40, 0.9, 0.55]);
        imshow(img, [], 'Parent', ax); hold(ax, 'on');
        
        % Overlay
        redMask = cat(3, ones(rows,cols), zeros(rows,cols), zeros(rows,cols));
        hOverlay = imshow(redMask, 'Parent', ax);
        set(hOverlay, 'AlphaData', zeros(rows,cols)); 
    
        lblResult = uicontrol('Style', 'text', 'Position', [20, 300, 950, 40], ...
            'FontSize', 11, 'FontWeight', 'bold', 'ForegroundColor', 'blue');
    
        % ========================
        % SLIDERS
        % ========================
    
        % Center X
        uicontrol('Style','text','Position',[20,260,120,20],'String','Center X:');
        sldX = uicontrol('Style','slider','Min',0,'Max',cols,'Value',defaultCenterX,...
            'Position',[150,260,300,20],'Callback',@updateMask);
    
        % Center Y
        uicontrol('Style','text','Position',[20,220,120,20],'String','Center Y:');
        sldY = uicontrol('Style','slider','Min',-1000,'Max',rows,'Value',-230,...
            'Position',[150,220,300,20],'Callback',@updateMask);
    
        % Radius Top
        uicontrol('Style','text','Position',[20,180,120,20],'String','Top Radius:');
        sldRMin = uicontrol('Style','slider','Min',0,'Max',600,'Value',350,...
            'Position',[150,180,300,20],'Callback',@updateMask);
    
        % Radius Bottom
        uicontrol('Style','text','Position',[20,140,120,20],'String','Bottom Radius:');
        sldRMax = uicontrol('Style','slider','Min',500,'Max',1500,'Value',900,...
            'Position',[150,140,300,20],'Callback',@updateMask);
    
        % Left Angle
        uicontrol('Style','text','Position',[500,260,120,20],'String','Left Angle:');
        sldAngL = uicontrol('Style','slider','Min',10,'Max',80,'Value',38,...
            'Position',[650,260,300,20],'Callback',@updateMask);
    
        % Right Angle
        uicontrol('Style','text','Position',[500,220,120,20],'String','Right Angle:');
        sldAngR = uicontrol('Style','slider','Min',10,'Max',80,'Value',38,...
            'Position',[650,220,300,20],'Callback',@updateMask);
    
        % 🔥 NEW: Left Offset
        uicontrol('Style','text','Position',[500,180,120,20],'String','Left Offset:');
        sldOffL = uicontrol('Style','slider','Min',-300,'Max',300,'Value',-50,...
            'Position',[650,180,300,20],'Callback',@updateMask);
    
        % 🔥 NEW: Right Offset
        uicontrol('Style','text','Position',[500,140,120,20],'String','Right Offset:');
        sldOffR = uicontrol('Style','slider','Min',-300,'Max',300,'Value',50,...
            'Position',[650,140,300,20],'Callback',@updateMask);
    
        % ========================
        % UPDATE FUNCTION
        % ========================
        function updateMask(~,~)
    
            % Ambil parameter
            cX   = round(get(sldX,'Value'));
            cY   = round(get(sldY,'Value'));
            rMin = round(get(sldRMin,'Value'));
            rMax = round(get(sldRMax,'Value'));
            angL = get(sldAngL,'Value');
            angR = get(sldAngR,'Value');
            offL = get(sldOffL,'Value');
            offR = get(sldOffR,'Value');
    
            % Grid
            [X, Y] = meshgrid(1:cols, 1:rows);
            dx = X - cX;
            dy = Y - cY;
    
            % Radius
            R = sqrt(dx.^2 + dy.^2);
    
            % 🔥 GARIS BATAS (INI YANG FIX)
            leftBound  = dx >= (-tand(angL) * dy + offL);
            rightBound = dx <= ( tand(angR) * dy + offR);
    
            % Mask final
            mask = (R >= rMin) & ...
                   (R <= rMax) & ...
                   leftBound & ...
                   rightBound & ...
                   (dy > 0);
    
            % Update overlay
            set(hOverlay, 'AlphaData', ~mask * 0.5);
    
            % Output parameter
            msg = sprintf(['fanCenterX=%d; fanCenterY=%d; rTop=%d; rBot=%d; ' ...
                           'angL=%.1f; angR=%.1f; offL=%.1f; offR=%.1f;'], ...
                           cX, cY, rMin, rMax, angL, angR, offL, offR);
    
            set(lblResult,'String',msg);
        end
    
        updateMask();
    end