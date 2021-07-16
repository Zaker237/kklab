function varargout = fehlersimulator(qrcodeData)
%  Initialization tasks
qrcodeVersion = get_version(qrcodeData);
qrcodeSize = size_from_version(qrcodeVersion);
qrcodeStructure = ref_create_structure_matrix(qrcodeVersion);
[qrcodeLevel , qrcodeMaskID] = ref_decode_format_information(ref_read_format_information(qrcodeData));
qrcodeBlockInfo = qr_block_info(qrcodeVersion, qrcodeLevel);
[qrcodeDataBlocks, qrcodeECCBlocks] = decodeQRCode();
qrcodeBlockID = zeros(size(qrcodeData), 'int32');
qrcodeBlockByteID = zeros(size(qrcodeData), 'int32');
qrcodeErrorMatrix = false(size(qrcodeData));

burstErrorCenter = round([qrcodeSize, qrcodeSize] / 2);

%  Construct the components
window = figure('name', 'Fehlersimulator', 'position', [0, 0, 1350, 850], 'menubar', 'none', 'toolbar', 'none', 'numbertitle', 'off', 'resize', 'off', 'visible', 'off', 'ResizeFcn', @layoutWindow);

plotAxes = axes('looseinset', [0, 0, 0, 0]);

showerrorsToggle = uicontrol('style', 'checkbox', 'string', 'Zeige Fehlerbits', 'value', true, 'callback', @updateFigure);
showblockidToggle = uicontrol('style', 'checkbox', 'string', 'Zeige Blockaufteilung', 'value', false, 'callback', @updateFigure);
showscanlineToggle = uicontrol('style', 'checkbox', 'string', 'Zeige 2D-Mapping', 'value', false, 'callback', @updateFigure);

interleavingToggle = uicontrol('style', 'checkbox', 'string', 'Codespreizung', 'value', true, 'callback', @update);

scanlineModePanel = uibuttongroup('title', '2D-Mapping', 'units', 'pixels', 'SelectionChangeFcn', @update, 'ResizeFcn', @layoutScanlinePanel);
scanlineModeLinearRadio = uicontrol('parent', scanlineModePanel, 'style', 'radiobutton', 'string', 'Linear', 'position', [10, 50, 100, 50]);
scanlineModeZigZagRadio = uicontrol('parent', scanlineModePanel, 'style', 'radiobutton', 'string', 'Saegezahn', 'position', [10, 10, 100, 50]);
set(scanlineModePanel, 'selectedobject', scanlineModeZigZagRadio);

errorSimulationPanel = uibuttongroup('title', 'Fehlersimulation', 'units', 'pixels', 'SelectionChangeFcn', @updateError, 'ResizeFcn', @layoutErrorSimulationPanel);
errorTypeSingleRadio = uicontrol('parent', errorSimulationPanel, 'style', 'radiobutton', 'string', 'Einzelbitfehler', 'position', [10, 50, 100, 50]);
errorSingleRateSlider = uicontrol('parent', errorSimulationPanel, 'style', 'slider', 'string', 'Fehlerrate', 'min', 0, 'max', 1, 'value', 0.05,'position', [150, 60, 200, 25], 'callback', @updateError);
errorTypeBurstRadio = uicontrol('parent', errorSimulationPanel, 'style', 'radiobutton', 'string', 'Buendelfehler', 'position', [10, 10, 100, 50]);
errorBurstRadiusSlider = uicontrol('parent', errorSimulationPanel, 'style', 'slider', 'string', 'Fehlerradius', 'min', 0, 'max', qrcodeSize / 2, 'value', 3, 'position', [150, 20, 200, 25], 'callback', @updateError);
set(errorSimulationPanel, 'selectedobject', errorTypeBurstRadio);

blockinfoTableColumnNames = {'Blocklaenge', 'Informationswoerter', 'Pruefwoerter', 'Fehlerwoerter', 'Fehlerbits'};
blockinfoTableRowNames = horzcat(strcat({'Block '}, strtrim(cellstr(num2str([1:size(qrcodeBlockInfo, 2)]'))')), 'Summe');
blockinfoTable = uitable('columnname', blockinfoTableColumnNames, 'rowname', blockinfoTableRowNames);

layoutWindow();
movegui(window, 'center');
set(window, 'visible', 'on');

%  Initialization tasks
[qrcodeFigureBaseLayer, qrcodeFigureErrorLayer, qrcodeFigureLinearPathLayer, qrcodeFigureZigZagPathLayer] = createFigure();

updateErrorMatrix();
update();

%  Callbacks and utility functions
    function axesClicked(src, event)
        if get(errorSimulationPanel, 'selectedobject') == errorTypeBurstRadio
            currentPoint = get(get(src, 'parent'), 'currentpoint');
            burstErrorCenter = round(currentPoint(1,2:-1:1));
            
            updateError(src, event);
        end
    end

    function update(varargin)
        encodeQRCode();
        updateErrorTable();
        updateFigure();
    end

    function updateError(src, event)
        % Do not sample new error locations if a slider for a different
        % error type was manipulated
        if (get(errorSimulationPanel, 'selectedobject') == errorTypeSingleRadio && src == errorBurstRadiusSlider) || ...
           (get(errorSimulationPanel, 'selectedobject') == errorTypeBurstRadio && src == errorSingleRateSlider)
            return
        end
        
        % Create new error locations and update the table in the GUI
        updateErrorMatrix();
        updateErrorTable();
    end
    
    function updateErrorMatrix(varargin)
        if get(errorSimulationPanel, 'selectedobject') == errorTypeSingleRadio
            % Single errors are drawn independently from a bernoulli
            % distribution with the user selected error-rate
            errorRate = get(errorSingleRateSlider, 'value');
            qrcodeErrorMatrix = random('bino', 1, errorRate, qrcodeSize, qrcodeSize);
        elseif get(errorSimulationPanel, 'selectedobject') == errorTypeBurstRadio
            % Burst errors are always circular with a user selected center
            % and radius
            qrcodeErrorMatrix = false(qrcodeSize, qrcodeSize);
            [X, Y] = meshgrid(1:qrcodeSize, 1:qrcodeSize);
            
            errorRadius = get(errorBurstRadiusSlider, 'value');
            qrcodeErrorMatrix(sqrt((X - burstErrorCenter(2)).^2 + (Y - burstErrorCenter(1)).^2) < errorRadius) = true;
        else
            throw MException('fehlersimulator::updateErrorMatrix(): invalid error type!');
        end
        
        %plotQRCode();
        updateFigure();
    end

    function updateErrorTable(varargin)
        % Count erroneous data bytes in each block
        % Multiple bit errors for the same data byte count as one error
        erroneousBitCounts = zeros(size(qrcodeBlockInfo, 2), 1);
        erroneousByteCounts = zeros(size(qrcodeBlockInfo, 2), 1);
        
        for i=1:size(qrcodeBlockInfo, 2)
            temp1 = qrcodeBlockByteID(qrcodeBlockID == i & qrcodeErrorMatrix == true);
            temp2 = tabulate(double(temp1));
            
            if isempty(temp1)
                erroneousBitCounts(i) = 0;
            else
                erroneousBitCounts(i) = length(temp1);
            end
            
            if isempty(temp2)
                erroneousByteCounts(i) = 0;
            else
                erroneousByteCounts(i) = length(find(temp2(:,2) > 0));
            end
        end
        
        % Update the GUI
        blockinfoTableData = horzcat(sum(qrcodeBlockInfo)', qrcodeBlockInfo', erroneousByteCounts, erroneousBitCounts);
        set(blockinfoTable, 'data', vertcat(blockinfoTableData, sum(blockinfoTableData, 1)));
    end

    function layoutWindow(varargin)
        margin = 15;
        menuYMargin = 5;
        menuWidth = 500;
        
        figurePosition = get(gcf, 'position');
        [figureWidth, figureHeight] = deal(figurePosition(3), figurePosition(4));
        
        % Place axes on the left
        set(plotAxes, 'outerposition', [0, 0, min(figureHeight/figureWidth, figureWidth/figureHeight), 1]);
        
        % Place menu on the right
        menuLeft = figureWidth - menuWidth - margin;
        currentY = figureHeight - margin;
        
        itemPosition = get(showerrorsToggle, 'position');
        set(showerrorsToggle, 'position', [menuLeft, currentY - itemPosition(4), menuWidth, itemPosition(4)]);
        currentY = currentY - itemPosition(4) - menuYMargin;
        
        itemPosition = get(showblockidToggle, 'position');
        set(showblockidToggle, 'position', [menuLeft, currentY - itemPosition(4), menuWidth, itemPosition(4)]);
        currentY = currentY - itemPosition(4) - menuYMargin;
        
        itemPosition = get(interleavingToggle, 'position');
        set(interleavingToggle, 'position', [menuLeft, currentY - itemPosition(4), menuWidth, itemPosition(4)]);
        currentY = currentY - itemPosition(4) - menuYMargin;
        
        itemPosition = get(showscanlineToggle, 'position');
        set(showscanlineToggle, 'position', [menuLeft, currentY - itemPosition(4), menuWidth, itemPosition(4)]);
        currentY = currentY - itemPosition(4) - menuYMargin;
        
        itemPosition = get(scanlineModePanel, 'position');
        set(scanlineModePanel, 'position', [menuLeft, currentY - itemPosition(4), menuWidth, itemPosition(4)]);
        currentY = currentY - itemPosition(4) - menuYMargin;

        itemPosition = get(errorSimulationPanel, 'position');
        set(errorSimulationPanel, 'position', [menuLeft, currentY - itemPosition(4), menuWidth, itemPosition(4)]);
        currentY = currentY - itemPosition(4) - menuYMargin;
        
        itemPosition = get(blockinfoTable, 'position');
        set(blockinfoTable, 'position', [menuLeft, currentY - 150, menuWidth, 150]);
        currentY = currentY - 150 - menuYMargin;
    end

    function layoutScanlinePanel(varargin)
        margin = 5;
        menuYMargin = 1;
        
        panelPosition = get(scanlineModePanel, 'position');
        panelWidth = panelPosition(3) - 2 * margin - 10;
        
        currentY = margin;
        
        itemPosition = get(scanlineModeZigZagRadio, 'position');
        set(scanlineModeZigZagRadio, 'position', [margin, currentY, panelWidth, itemPosition(4)]);
        currentY = currentY + itemPosition(4) + menuYMargin;
        
        itemPosition = get(scanlineModeLinearRadio, 'position');
        set(scanlineModeLinearRadio, 'position', [margin, currentY, panelWidth, itemPosition(4)]);
        currentY = currentY + itemPosition(4) + menuYMargin;
        
        panelPosition(4) = currentY - menuYMargin + margin + 15;
        set(scanlineModePanel, 'position', panelPosition);
    end

    function layoutErrorSimulationPanel(varargin)
        margin = 5;
        menuYMargin = 1;
        
        panelPosition = get(errorSimulationPanel, 'position');
        panelWidth = panelPosition(3) - 2 * margin - 10;
        
        currentY = margin;
        
        itemPosition = get(errorTypeBurstRadio, 'position');
        set(errorTypeBurstRadio, 'position', [margin, currentY, panelWidth / 4, itemPosition(4)]);
        set(errorBurstRadiusSlider, 'position', [margin + panelWidth / 4, currentY, 3 * panelWidth / 4, itemPosition(4)]);
        currentY = currentY + itemPosition(4) + menuYMargin;
        
        itemPosition = get(errorTypeSingleRadio, 'position');
        set(errorTypeSingleRadio, 'position', [margin, currentY, panelWidth / 4, itemPosition(4)]);
        set(errorSingleRateSlider, 'position', [margin + panelWidth / 4, currentY, 3 * panelWidth / 4, itemPosition(4)]);
        currentY = currentY + itemPosition(4) + menuYMargin;
        
        panelPosition(4) = currentY - menuYMargin + margin + 15;
        set(errorSimulationPanel, 'position', panelPosition);
    end

    function updateFigure(varargin)
        % Update base layer: symbol + blockid overlay
        symbolImage = ind2rgb(255*(1-qrcodeData), colormap('gray')) + 0.3;
        symbolImage(symbolImage > 1) = 1;
        
        if get(showblockidToggle, 'value')
            cmap = colormap('lines');
            blockidImage = ind2rgb(qrcodeBlockID, cat(1, [0.75, 0.75, 0.75], cmap(1:end-1,:) * 0.5 + 0.5));
            blockidImage(blockidImage > 1) = 1;

            blendedImage = (1 - 2 * symbolImage) .* blockidImage .* blockidImage + 2 * symbolImage .* blockidImage;
            blendedImage(repmat(qrcodeBlockID, [1, 1, 3]) == 0) = symbolImage(repmat(qrcodeBlockID, [1, 1, 3]) == 0);
            
            set(qrcodeFigureBaseLayer, 'cdata', blendedImage);
        else
            set(qrcodeFigureBaseLayer, 'cdata', symbolImage);
        end
        
        % Update error layer
        if get(showerrorsToggle, 'value')
            errorImage = qrcodeErrorMatrix;
            errorImage(:,:,2:3) = 0;
            
            set(qrcodeFigureErrorLayer, {'cdata', 'alphadata', 'visible'}, {errorImage, qrcodeErrorMatrix, 'on'});
        else
            set(qrcodeFigureErrorLayer, 'visible', 'off');
        end
        
        % Activate scanline path visualization
        set(qrcodeFigureLinearPathLayer, 'visible', 'off');
        set(qrcodeFigureZigZagPathLayer, 'visible', 'off');
        
        if get(showscanlineToggle, 'value')
            if get(scanlineModePanel, 'selectedobject') == scanlineModeLinearRadio
                set(qrcodeFigureLinearPathLayer, 'visible', 'on');
            elseif get(scanlineModePanel, 'selectedobject') == scanlineModeZigZagRadio
                set(qrcodeFigureZigZagPathLayer, 'visible', 'on');
            end
        end
    end

    function [baseLayer, errorLayer, linearPathLayer, zigzagPathLayer] = createFigure()
        reset(plotAxes);
        axes(plotAxes);
        hold on;
        
        % Create base layer: symbol + blockid overlay
        baseLayer = imshow(zeros(qrcodeSize, qrcodeSize, 3));
        set(baseLayer, 'ButtonDownFcn', @axesClicked);
        
        % Create error layer
        errorLayer = imshow(zeros(qrcodeSize, qrcodeSize, 3));
        set(errorLayer, 'visible', 'off');
        set(errorLayer, 'ButtonDownFcn', @axesClicked);
        
        % Create linear scanline path visualization
        linearPathLayer = [];
        
        % Get line segment endpoints
        scanLines = cell(qrcodeSize);
        for y=1:qrcodeSize
            dataIndices = find(qrcodeStructure(y,:) == 'D');

            if isempty(dataIndices)
                continue;
            end

            scanLines{y} = [dataIndices(1)];
            for i=2:numel(dataIndices)
                if dataIndices(i) - dataIndices(i-1) > 1
                    scanLines{y} = [scanLines{y} dataIndices(i-1) dataIndices(i)];
                end
            end
            scanLines{y} = [scanLines{y} dataIndices(end)];
        end

        % Plot line segments; line segments not corresponding to
        % data are plotted with non-solid lines
        prevY = 0;
        index = 1;
        
        for y=1:qrcodeSize
            if isempty(scanLines{y})
                continue;
            end

            if prevY > 0
                linearPathLayer(index) = line([scanLines{prevY}(end), scanLines{y}(1)], [prevY, y], 'color', 'red', 'linewidth', 2.0, 'linestyle', ':');
                index = index + 1;
            end
            prevY = y;

            dataMode = true;
            for i=2:numel(scanLines{y})
                if dataMode
                    linearPathLayer(index) = line([scanLines{y}(i-1), scanLines{y}(i)], [y, y], 'color', 'red', 'linewidth', 2.0);
                else
                    linearPathLayer(index) = line([scanLines{y}(i-1), scanLines{y}(i)], [y, y], 'color', 'red', 'linewidth', 2.0, 'linestyle', ':');
                end
                dataMode = ~dataMode;
                
                index = index + 1;
            end
        end

        % Plot scanline-sequence begin and end markers
        linearPathLayer(index) = rectangle('position', [scanLines{1}(1)-0.25, 1-0.25, 0.5, 0.5], 'curvature', [1, 1], 'linestyle', 'none', 'facecolor', 'red', 'visible', 'off');
        linearPathLayer(index+1) = patch([scanLines{qrcodeSize}(end)-0.25, scanLines{qrcodeSize}(end)-0.25, scanLines{qrcodeSize}(end)+0.25], [qrcodeSize+0.25, qrcodeSize-0.25, qrcodeSize], 'red', 'linestyle', 'none', 'visible', 'off');
        
        % Create zigzag scanline path visualization
        zigzagPathLayer = [];
        
        % Follow the zig-zag scan and plot each line segment in a
        % turtle-like fashion
        turtlePosition = [qrcodeSize qrcodeSize];
        turtleOldPosition = turtlePosition;
        turtleDirection = [-1 -1];
        index = 1;

        while turtlePosition(2) > 2 || turtlePosition(1) < qrcodeSize - 7
            if qrcodeStructure(turtlePosition(1), turtlePosition(2)) ~= 'D' || qrcodeStructure(turtleOldPosition(1), turtleOldPosition(2)) ~= 'D'
                zigzagPathLayer(index) = line([turtleOldPosition(2), turtlePosition(2)], [turtleOldPosition(1), turtlePosition(1)], 'color', 'red', 'linewidth', 2.0, 'linestyle', ':');
            else
                zigzagPathLayer(index) = line([turtleOldPosition(2), turtlePosition(2)], [turtleOldPosition(1), turtlePosition(1)], 'color', 'red', 'linewidth', 2.0);
            end

            turtleOldPosition = turtlePosition;
            turtlePosition(2) = turtlePosition(2) + turtleDirection(2);
            turtleDirection(2) = turtleDirection(2) * -1;
            index = index + 1;

            if turtleDirection(2) < 0
                turtlePosition(1) = turtlePosition(1) + turtleDirection(1);
                if turtlePosition(1) < 1 || turtlePosition(1) > qrcodeSize
                    turtlePosition(1) = turtlePosition(1) - turtleDirection(1);
                    turtleDirection(1) = turtleDirection(1) * -1;

                    turtlePosition(2) = turtlePosition(2) - 2;

                    if turtlePosition(2) == 7
                        turtlePosition(2) = 6;
                    end
                end
            end
        end

        % Plot scanline-sequence begin and end markers
        zigzagPathLayer(index) = rectangle('position', [qrcodeSize-0.25, qrcodeSize-0.25, 0.5, 0.5], 'curvature', [1, 1], 'linestyle', 'none', 'facecolor', 'red');
        zigzagPathLayer(index+1) = patch([turtleOldPosition(2)-0.25, turtleOldPosition(2)+0.25, turtleOldPosition(2)+0.25], [turtleOldPosition(1), turtleOldPosition(1)-0.25, turtleOldPosition(1)+0.25], 'red', 'linestyle', 'none');
        
        hold off;
    end

    function [dataBlocks, eccBlocks] = decodeQRCode()
        totalWords = sum(qrcodeBlockInfo, 2);
        interleavedDataStream = zeros(1, 8*sum(totalWords));
        
        % Follow the zig-zag scan
        turtlePosition = int32([qrcodeSize qrcodeSize]);
        turtleDirection = int32([-1 -1]);
        
        streamPosition = 1;
        while streamPosition <= length(interleavedDataStream)
            if qrcodeStructure(turtlePosition(1), turtlePosition(2)) == 'D'
                interleavedDataStream(streamPosition) = xor(qrcodeData(turtlePosition(1), turtlePosition(2)), qr_mask(turtlePosition(1), turtlePosition(2), qrcodeMaskID));
                streamPosition = streamPosition + 1;
            end

            turtlePosition(2) = turtlePosition(2) + turtleDirection(2);
            turtleDirection(2) = turtleDirection(2) * -1;

            if turtleDirection(2) < 0
                turtlePosition(1) = turtlePosition(1) + turtleDirection(1);
                if turtlePosition(1) < 1 || turtlePosition(1) > qrcodeSize
                    turtlePosition(1) = turtlePosition(1) - turtleDirection(1);
                    turtleDirection(1) = turtleDirection(1) * -1;

                    turtlePosition(2) = turtlePosition(2) - 2;

                    if turtlePosition(2) == 7
                        turtlePosition(2) = 6;
                    end
                end
            end
        end
        
        % Initialize data blocks
        dataBlocks = cell(1, size(qrcodeBlockInfo, 2));
        eccBlocks = cell(1, size(qrcodeBlockInfo, 2));

        for i=1:length(dataBlocks)
            dataBlocks{i} = zeros(1, 8 * qrcodeBlockInfo(1, i));
            eccBlocks{i} = zeros(1, 8 * qrcodeBlockInfo(2, i));
        end

        % Deinterleave
        streamPosition = 1;
        blockPosition = 1;
        while true
            for i=1:length(dataBlocks)
                if blockPosition+7 <= length(dataBlocks{i})
                    dataBlocks{i}(blockPosition:blockPosition+7) = interleavedDataStream(streamPosition:streamPosition+7);
                    streamPosition = streamPosition + 8;
                end
            end

            if streamPosition >= 8*totalWords(1)
                break;
            else
                blockPosition = blockPosition + 8;
            end
        end

        blockPosition = 1;
        while true
            for i=1:length(eccBlocks)
                if blockPosition+7 <= length(eccBlocks{i})
                    eccBlocks{i}(blockPosition:blockPosition+7) = interleavedDataStream(streamPosition:streamPosition+7);
                    streamPosition = streamPosition + 8;
                end
            end

            if streamPosition >= length(interleavedDataStream)
                break;
            else
                blockPosition = blockPosition + 8;
            end
        end
    end
    
    function encodeQRCode()
        totalWords = sum(qrcodeBlockInfo, 2);
        interleavedDataStream = zeros(1, 8*sum(totalWords));
        interleavedDataStreamBlockID = zeros(1, 8*sum(totalWords));
        interleavedDataStreamBlockByteID = zeros(1, 8*sum(totalWords));
        
        qrcodeData(qrcodeStructure == 'D') = 0;
        qrcodeBlockID(qrcodeStructure == 'D') = 0;
        qrcodeBlockByteID(qrcodeStructure == 'D') = 0;
        
        % Interleave
        if get(interleavingToggle, 'value')
            streamPosition = 1;
            blockPosition = 1;
            while true
                for i=1:length(qrcodeDataBlocks)
                    if blockPosition+7 <= length(qrcodeDataBlocks{i})
                        interleavedDataStream(streamPosition:streamPosition+7) = qrcodeDataBlocks{i}(blockPosition:blockPosition+7);
                        interleavedDataStreamBlockID(streamPosition:streamPosition+7) = i;
                        interleavedDataStreamBlockByteID(streamPosition:streamPosition+7) = (blockPosition-1) / 8 + 1;
                        streamPosition = streamPosition + 8;
                    end
                end

                if streamPosition >= 8*totalWords(1)
                    break;
                else
                    blockPosition = blockPosition + 8;
                end
            end
            
            blockPosition = 1;
            while true
                for i=1:length(qrcodeECCBlocks)
                    if blockPosition+7 <= length(qrcodeECCBlocks{i})
                        interleavedDataStream(streamPosition:streamPosition+7) = qrcodeECCBlocks{i}(blockPosition:blockPosition+7);
                        interleavedDataStreamBlockID(streamPosition:streamPosition+7) = i;
                        interleavedDataStreamBlockByteID(streamPosition:streamPosition+7) = (blockPosition-1) / 8 + 1 + qrcodeBlockInfo(1, i);
                        streamPosition = streamPosition + 8;
                    end
                end

                if streamPosition >= length(interleavedDataStream)
                    break;
                else
                    blockPosition = blockPosition + 8;
                end
            end
        else
            streamPosition = 1;
            for i=1:length(qrcodeDataBlocks)
                dataBlockSize = length(qrcodeDataBlocks{i});
                eccBlockSize = length(qrcodeECCBlocks{i});
                
                interleavedDataStreamBlockByteID(streamPosition:streamPosition+dataBlockSize+eccBlockSize-1) = kron([1:sum(qrcodeBlockInfo(:,i))], ones(1,8));
                
                interleavedDataStream(streamPosition:streamPosition+dataBlockSize-1) = qrcodeDataBlocks{i}(:);
                interleavedDataStreamBlockID(streamPosition:streamPosition+dataBlockSize-1) = i;
                streamPosition = streamPosition + dataBlockSize;
                
                interleavedDataStream(streamPosition:streamPosition+eccBlockSize-1) = qrcodeECCBlocks{i}(:);
                interleavedDataStreamBlockID(streamPosition:streamPosition+eccBlockSize-1) = i;
                streamPosition = streamPosition + eccBlockSize;
            end
        end
        
        % 2D-Mapping
        if get(scanlineModePanel, 'selectedobject') == scanlineModeLinearRadio
            streamPosition = 1;
            
            for y=1:qrcodeSize
                for x=1:qrcodeSize
                    if streamPosition <= length(interleavedDataStream) && qrcodeStructure(y, x) == 'D'
                        qrcodeData(y, x) = xor(interleavedDataStream(streamPosition), qr_mask(int32(y), int32(x), qrcodeMaskID));
                        qrcodeBlockID(y, x) = interleavedDataStreamBlockID(streamPosition);
                        qrcodeBlockByteID(y, x) = interleavedDataStreamBlockByteID(streamPosition);
                        streamPosition = streamPosition + 1;
                    end
                end
            end
        elseif get(scanlineModePanel, 'selectedobject') == scanlineModeZigZagRadio
            turtlePosition = int32([qrcodeSize qrcodeSize]);
            turtleDirection = int32([-1 -1]);
            streamPosition = 1;

            while streamPosition <= length(interleavedDataStream)
                if qrcodeStructure(turtlePosition(1), turtlePosition(2)) == 'D'
                    qrcodeData(turtlePosition(1), turtlePosition(2)) = xor(interleavedDataStream(streamPosition), qr_mask(turtlePosition(1), turtlePosition(2), qrcodeMaskID));
                    qrcodeBlockID(turtlePosition(1), turtlePosition(2)) = interleavedDataStreamBlockID(streamPosition);
                    qrcodeBlockByteID(turtlePosition(1), turtlePosition(2)) = interleavedDataStreamBlockByteID(streamPosition);
                    streamPosition = streamPosition + 1;
                end

                turtlePosition(2) = turtlePosition(2) + turtleDirection(2);
                turtleDirection(2) = turtleDirection(2) * -1;

                if turtleDirection(2) < 0
                    turtlePosition(1) = turtlePosition(1) + turtleDirection(1);
                    if turtlePosition(1) < 1 || turtlePosition(1) > qrcodeSize
                        turtlePosition(1) = turtlePosition(1) - turtleDirection(1);
                        turtleDirection(1) = turtleDirection(1) * -1;

                        turtlePosition(2) = turtlePosition(2) - 2;

                        if turtlePosition(2) == 7
                            turtlePosition(2) = 6;
                        end
                    end
                end
            end
        else
            throw MException('fehlersimulator::encodeQRCode(): invalid scaline mode!');
        end
    end
end