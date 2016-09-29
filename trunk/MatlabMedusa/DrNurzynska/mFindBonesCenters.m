% image - obraz wej�ciowy
% skinContour - kontur sk�ry znaleziony metod� mFindSkin
% threshold1 - og�lny pr�g dla ko�ci
% threshold2 - tylko najja�niejsze elementy ko�ci
% distanceThreshold - 
% overlapThreshold - uwzgl�dniamy obiekty od g�ry obrazu. Je�eli nachodz�
% na inny to ten parametr oke�la w jakim procencie uznajemy ja za obiekty
% do usuni�cia
% type - spos�b znajdowania linii ko�ci: 0 - g�ra, 1 - �rodek

% map - binarna mapa ko�ci
% wsp�rz�dne znalezionej linii ko�ci
function [map, contours] = mFindBonesCenters(image, skinContour, threshold1, threshold2, ...
                                                    distanceThreshold, overlapThreshold, type)
 
    % znajdujemy warto�� dla jakiej podzielimy obraz
    threshold = mDefineThresholdRev(image, threshold1);%0.98

    % tworzymy obraz binarny    
    bw = zeros(size(image));
    bw(image >= threshold) = 1;
    bw = imfill(bw);
    
    % znajdujemy warto�� dla jakiej podzielimy obraz
    threshold = mDefineThresholdRev(image, threshold2);%0.9

    % tworzymy obraz binarny
    bwBig = zeros(size(image));
    bwBig(image >= threshold) = 1;
    bwBig = imfill(bwBig);
    
    map = mRemoveDarkObjects(bw, bwBig, distanceThreshold, skinContour);%20
    
    map1 = mRemoveObjectsAbove(map, overlapThreshold);%0.5

    if type
        contours = mFindThinnedData(map1);
    else
        contours = mFindBoundaries(map1);
    end
    
    if ~isempty(contours)
        contours = mSmoothContours(contours);
    end
    map = map1;  
end

function contours = mSmoothContours(contours)

    for c = 1: length(contours)
        contour = contours{c};
        
        for i = 2: size(contour, 1) - 1
            contour(i, 1) = floor(mean(contour(i - 1: i + 1, 1)));
        end
        
        contours{c} = contour;
    end
end

function map1 = mGetTwoBiggestObjects(map)

    [height, ~] = size(map);
    % dzielimy na poszczeg�lne obiekty
    CC = bwconncomp(map);

    if CC.NumObjects < 2
        map1 = map;
        return
    end
    
    objSize = zeros(CC.NumObjects, 1);
    for o = 1: CC.NumObjects        
        objSize(o) = length(CC.PixelIdxList{o});
    end
    
   
    map1 = zeros(size(map));
    for o = 1: 2
        [~, maxIdx] = max(objSize);
        
        objSize(maxIdx) = 0;
        
        % pobieramy wsp�rz�dne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{maxIdx}, height);
        map1 = mDrawObject(map1, x, y);        
    end    
end


function contours = mFindThinnedData(map)
    
    [height, width] = size(map);
    
    % dzielimy na obiekty
    CC = bwconncomp(map);
    
    contours = [];
    for o = 1: CC.NumObjects
        % pobieramy wsp�rz�dne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);
        % tworzymy mask� bie��cego obiektu
        mask = zeros(size(map));
        
        for i = 1: length(x)
            mask(y(i), x(i)) = 1;
        end
        
        contour = [];
        for x = 1: width
            first = 0;
            min = -1;
            max = -1;
            for y = 1: height
                if mask(y,x) == 1
                    if first == 0
                        min = y;
                        max = y;
                        first = 1;
                    else
                        max = y;
                    end   
                else
                    first = 0;
                end
            end
            if min ~= -1
                y = min + floor((max - min)/2);
                contour = [contour; y x];
            end
        end

        contours = [contours {contour}];
    end
    

end

function contours = mFindBoundaries(map)
    
    [height, width] = size(map);
    
    % dzielimy na obiekty
    CC = bwconncomp(map);
    
    contours = [];
    for o = 1: CC.NumObjects
        % pobieramy wsp�rz�dne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);
        % tworzymy mask� bie��cego obiektu
        mask = zeros(size(map));
        
        for i = 1: length(x)
            mask(y(i), x(i)) = 1;
        end
        
        % znajdujemy otoczk� obiektu
        border = bwmorph(mask,'remove');
        
        % znajdujemy g�r� otoczki
        contour = zeros(max(x) - min(x), 2);
        index = 1;
        for xx = 1: width
            for yy = 1: height
                if border(yy,xx) == 1
                    contour(index, 1) = yy;
                    contour(index, 2) = xx;
                    index = index + 1;
                    break;
                end
            end
        end
        
        contours = [contours {contour}];
    end
    

end


function map = mProbabilityMap(map, image, penalty, threshold)

    [height, width] = size(map);
    % podzia� na obiekty
    CC = bwconncomp(map);

    map = zeros(size(map));
    
    for o = 1 : CC.NumObjects
        
        % pobieramy wsp�rz�dne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);
        
        % tworzymy mask� bie��cego obiektu
        mask = zeros(size(map));        
        mask = mDrawObject(mask, x, y);
        
        % tworzymy mape prawdopodobie�stwa opart� na skali szaro�ci
        probability = double(image);
        probability(mask == 0) = 0;
        % skalujemy warto�ci do przedzia�u 0 - 1
        maxV = max(probability(:));
        probability(mask == 0) = 255;
        minV = min(probability(:));
        probability = (probability - minV)./(maxV - minV);
        probability(mask == 0) = 0;
        
        % tworzymy map� odleg�o�ci
        brightness = image;
        brightness(mask == 0) = 0;
        maxBrightness = max(brightness(:));
        distances = zeros(size(probability));       
        for i = 1: length(x)
            minDistance = width * height;
            minDistanceX = width;
            minDistanceY = height;
            for j = i + 1: length(x)
                if image(y(i), x(i)) == maxBrightness
                    distance = sqrt((y(i) - y(j))^2 + (x(i) - x(j))^2);
                    if distance < minDistance
                        minDistance = distance;
                        minDistanceX = x(j);
                        minDistanceY = y(j);
                    end
                end                 
            end
            
            % sprawdzamy czy ta odleg�o�� nie wymaga przejscia poza
            % obiektem
            minX = min(x(i), minDistanceX);
            maxX = max(x(i), minDistanceX);
            minY = min(y(i), minDistanceY);
            maxY = max(y(i), minDistanceY);
            
            area = (maxX - minX + 1)*(maxY - minY + 1);
            subMask = mask(minY:maxY, minX:maxX);
            objectArea = sum(subMask(:));
            
            if objectArea < area
                minDistance = minDistance + penalty;
            end            
            distances(y(i), x(i)) = minDistance;
        end
        
        % skalujemy warto�ci do przedzia�u 0 - 1
        maxV = max(distances(:));
        distances(mask == 0) = 255;
        minV = min(distances(:));
        distances = 1.0 - (distances - minV)./(maxV - minV);
        distances(mask == 0) = 0;
        
        % ��czymy obydwie informacje
        % probability = (probability + distances)./2;
        probability = distances;
        
        prob100 = floor(100*probability);
        histogram = zeros(101, 1);
        for i = 1: length(x)
            histogram(prob100(y(i), x(i)) + 1) = histogram(prob100(y(i), x(i)) + 1) + 1;
        end
        
        histogram = histogram ./ sum(histogram);
        dystrybuanta = zeros(101, 1);
        dystrybuanta(1) = histogram(1);
        for i = 2: 101
            dystrybuanta(i) = dystrybuanta(i - 1) + histogram(i);
            if dystrybuanta(i) > threshold
                threshold = (i*1.0)/100;
                break;
            end
        end
        
        
        % usuwamy punkty, kt�re maj� najni�sze prawdopodobie�stwo
        for i = 1: length(x)
            if probability(y(i), x(i)) > threshold
                map(y(i), x(i)) = 1; 
            end
        end
    end
end



function map = mRemoveBranches(map)

    [height, width] = size(map);
    
    % usuwamy rozga��zienia
    CC = bwconncomp(map);
    for o = 1 : CC.NumObjects
        
        % pobieramy wsp�rz�dne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);
        % tworzymy mask� bie��cego obiektu
        mask = zeros(size(map));        
        mask = mDrawObject(mask, x, y);
        
        % przegl�damy obiekt kolumnami
        for xx = min(x): max(x)
            branchSize = [];
            branchStartStop = [];            
            background = 0;
            currentBranch = 0;
            % bie��ca kolumna
            for yy = 1: height                
                
                if background == 1 && mask(yy,xx) == 1
                   % kontynuujem obiekt
                   currentBranch = currentBranch + 1;
                end
                
                if background == 0 && mask(yy,xx) == 1
                   % rozpoczyna sie obiekt 
                   currentBranch = 1;
                   background = 1;
                   branchStartStop = [branchStartStop; yy];
                end
                
                if background == 1 && mask(yy,xx) == 0
                   % zako�czy�a si� ga���
                   branchSize = [branchSize; currentBranch];
                   branchStartStop = [branchStartStop; yy - 1];
                   currentBranch = 0;
                   background = 0;
                end
            end
            
            % sprawdzamy liczb� rozga��zie�
            if length(branchSize) > 1
                 [maxOne, idxOne] = max(branchSize);
                 branchSize(idxOne) = 0;
                 [maxTwo, idxTwo] = max(branchSize);
                 
                 if maxOne > 3 * maxTwo
                     % wybierz maxOne
                     for b = 1: length(branchSize)
                         if b ~= idxOne
                             startY = branchStartStop(2 * (b - 1) + 1);
                             stopY = branchStartStop(2 * (b - 1) + 2);                         
                             mask(startY:stopY, xx) = 0;
                             map(startY:stopY, xx) = 0;
                         end
                     end
                 else
                     % wybierz pierwszy od do�u
                     if idxTwo > idxOne
                         idxOne = idxTwo;
                     end
                     for b = 1: length(branchSize)
                         if b ~= idxOne
                             startY = branchStartStop(2 * (b - 1) + 1);
                             stopY = branchStartStop(2 * (b - 1) + 2);                         
                             mask(startY:stopY, xx) = 0;
                             map(startY:stopY, xx) = 0;
                         end
                     end
                 end                 
            end
        end
    end
end


function map = mJoinBranches(map)

    [height, ~] = size(map);
    
    % usuwamy rozga��zienia
    CC = bwconncomp(map);
    for o = 1 : CC.NumObjects
        
        % pobieramy wsp�rz�dne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);
        % tworzymy mask� bie��cego obiektu
        mask = zeros(size(map));        
        mask = mDrawObject(mask, x, y);
        
        % przegl�damy obiekt kolumnami
        for xx = min(x): max(x)

            minY = height;
            maxY = 0;
            background = 0;
            % bie��ca kolumna
            for yy = 1: height                
                if background == 0 && mask(yy,xx) == 1
                   % rozpoczyna sie obiekt 
                   if minY == height
                       minY = yy;
                   end
                   background = 1;
                end
                
                if background == 1 && mask(yy,xx) == 0
                    maxY = yy - 1;
                    background = 0;
                end
            end
            
            mask(minY:maxY, xx) = 1;
        end
        map = map + mask;
    end
    map(map > 1) = 1;
end

function map = mRemoveObjectsAbove(map, param)

    [height, width] = size(map);
    % dzielimy na poszczeg�lne obiekty
    CC = bwconncomp(map);
    
    minX = width * ones(CC.NumObjects, 1);
    minY = height * ones(CC.NumObjects, 1);
    maxX = zeros(CC.NumObjects, 1);
    maxY = zeros(CC.NumObjects, 1);
    coefficients = cell(CC.NumObjects, 1);
    for o = 1: CC.NumObjects
        % pobieramy wsp�rz�dne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);

        coefficients(o) = {[x y]};
        % okre�lamy prostok�t go okalaj�cy
        minX(o) = min(x);
        minY(o) = min(y);
        maxX(o) = max(x);
        maxY(o) = max(y);
    end    
    % usuwamy obiekty, kt�re znajduj� si� nad innym obiektem (czyli maj�
    % takie same Xy a mniejsze Yki
    
    map = zeros(size(map));
    for o = 1: CC.NumObjects
        bDraw = 1;
        objWidth = maxX(o) - minX(o);
        objOverlap = 0;
        
        for oo = 1: CC.NumObjects
            if o ~= oo
                overlapWidth = 0;              
                % je�eli o jest wy�ej od oo
                if maxY(o) < maxY(oo)
                    % sprawdzamy czy obiekt o rozpoczyna si� nad obiektem oo
                    if minX(o) >= minX(oo) && minX(o) <= maxX(oo)
                        % sprawdzamy czy obiekt o ko�czy si� nad obietem oo
                        if maxX(o) >= minX(oo) && maxX(o) <= maxX(oo)
                            % to teraz sprawdzamy, kt�ry jest wy�ej                
                            if maxY(o) < maxY(oo)
                                % nie odrysujemy o
                                bDraw = 0;
                                break;
                            end                        
                        else
                            % sprawdzamy jaka cz�� obiektu o nachodzi nad
                            % obiekt oo
                            overlapWidth = maxX(oo) - minX(o);                      
                        end                    
                    end
                    % sprawdzamy czy obiekt o ko�czy si� nad obietem oo
                    if maxX(o) >= minX(oo) && maxX(o) <= maxX(oo)
                        % sprawdzamy jaka cz�� obiektu o nachodzi nad
                        % obiekt oo
                        overlapWidth = maxX(o) - minX(oo);                       
                    end
                
                    % sprawdzamy czy obiekt o ca�y jest nad obiektem oo
                    if minX(o) <= minX(oo) && maxX(o) >= maxX(oo)
                       overlapWidth = maxX(oo) - minX(oo);                 
                    end
                    if overlapWidth > 0
                        objOverlap = objOverlap + overlapWidth;
                        if overlapWidth / objWidth > param
                            % nie odrysujemy o
                            bDraw = 0;
                            break;
                        end                    
                    end                
                end                                
            end
        end
        if objOverlap / objWidth > param 
            bDraw = 0;
        end
        if bDraw == 1
            % pobieramy wsp�rz�dne obiektu
%             [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);
            coeffs = coefficients{o};
            x = coeffs(:,1);
            y = coeffs(:, 2);
            map = mDrawObject(map, x, y);
        end
    end
end

function [map] = mRemoveDarkObjects(bw, bwBig, maxMinDistance, skinContour)

    maxMinDistance = maxMinDistance*maxMinDistance;
    [height, ~] = size(bw);
    
    bw = bw + bwBig;
    % tam gdzie mamy 2 to jest to co nas najbardziej interesuje
    % tam gdzie mamy 1 to interesuje nas tylko je�eli wewn�trz jest 2

    % dzielimy na poszczeg�lne obiekty
    CC = bwconncomp(bwBig); 
    
    map = zeros(size(bw));
    for o = 1: CC.NumObjects
        % pobieramy wsp�rz�dne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);

        % usuwamy te obiekty, kt�re nie maj� w bw warto�ci 2
        bRemove = 1;
        for i = 1: length(x)
            if bw(y(i), x(i)) == 2
                bRemove = 0;
                break;
            end
        end

        if bRemove == 0
            
            % usuwamy obiekty za blisko sk�ry                    
            minDistance = height*height;
            % szukamy jego odleg�o�ci od konturu sk�ry
            for s = 1: length(skinContour)
                distances = ((y - skinContour(s)).^2 + (x - s).^2);
%                 distances = sqrt((y - skinContour(s)).^2 + (x - s).^2);
                distance = min(distances);
                if distance < minDistance
                    minDistance = distance;
                end
            end
            
            % poza dystansem trzeba sprawdzi� czy obiekt jest poni�ej sk�ry
            if (minDistance > maxMinDistance) && (min(y) > max(skinContour))           
                map = mDrawObject(map, x, y);
            end
        end
    end
end

function map = mDrawObject(map, x, y)
    for i = 1: length(x)
        map(y(i), x(i)) = 1;
    end
end

function threshold = mDefineThresholdRev(image, threshold)

    [height, width] = size(image);
    % obliczamy histogram
    [histogram, ~] = imhist(image);
    % normalizujemy histogram
    histogram = histogram ./ (width * height);
    % obliczamy dystrybuante
    dystrybuanta = zeros(255, 1);
    dystrybuanta(1) = histogram(1);
    for h = 2: 256
        dystrybuanta(h) = dystrybuanta(h-1) + histogram(h);
    end
    % znajdujemy X% najja�niejszych pikseli
    for h = 256: -1: 1
        if dystrybuanta(h) < threshold
            threshold = h;
            break; 
        end
    end    
end