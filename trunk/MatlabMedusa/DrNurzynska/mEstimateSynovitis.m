% image - obraz wej�ciowy
% skinContour - kontur sk�ry uzyskany metod� mFindSkin
% boneContour - kontur ko�ci uzyskany metoa mDefineBoneContour
% jointX,jointY - wsp�rz�dne stawu z metody mTestBone
% threshold - pr�g wyznaczania synovitis

% output - region synovitis
function [output] = mEstimateSynovitis(image, skinContour, ...
                                                         boneContour, jointX, ...
                                                         jointY, threshold)

    borders = [];
    
    threshold = mDefineThreshold(image, threshold);%0.65
    
    % tworzymy obraz binarny
    bw = zeros(size(image));
    bw(image < threshold) = 1;  
    bw = imfill(bw);
    
    [height, width] = size(bw);
    
    % zmiana uwzgl�dniaj�ca to, �e kontury nie pokrywaj� ca�ej d�ugo�ci
    boneContourOrg = boneContour;
    maxV = max(boneContour);
    boneContour(boneContour == 0) = maxV;
    
    % zmiana pozwalaj�ca na poszukiwania troch� ni�ej, bo inaczej trac� tak
    % na prawd� staw
    boneContour = boneContour + 20;
    boneContour(boneContour > height) = height;

    % usuwam elementy, kt�re s� nad sk�r� oraz pod konturem ko�ci
    for i = 1: length(skinContour)
        bw(1:skinContour(i), i) = 0; 
        val = floor(boneContour(i));
        bw(val:height, i) = 0;
        % KN 25.12.2015 obkiczamy �redni� odleg�o�c mi�dzy skor� a konturem
        dist = floor((boneContour(i) - skinContour(i)) / 2);
        bw(skinContour(i):skinContour(i) + dist, i) = 0;
    end
    
    
    
    % KN 25.12.2015 obliczamy otoczk� wypuk�� dla ka�dego obiektu
    bw = bwconvhull(bw,'objects');    
    % wyg�adzamy j� 2016,01,09
    bw = imgaussfilt(double(bw),4); 
    bw(bw > 0.5) = 1;
    bw(bw <= 0.5) = 0;



    % KN 2016.01.10 jeszcze raz usuwamy eleenty, kt�re s� pod skor�, a
    % wysz�y po zaokr�glaniu obiekt�w powy�ej
    % usuwam elementy, kt�re s� nad sk�r� oraz pod konturem ko�ci
    for i = 1: length(skinContour)
        bw(1:skinContour(i), i) = 0; 
        val = floor(boneContour(i));
        bw(val:height, i) = 0;
        % KN 25.12.2015 obkiczamy �redni� odleg�o�c mi�dzy skor� a konturem
        dist = floor((boneContour(i) - skinContour(i)) / 2);
        bw(skinContour(i):skinContour(i) + dist, i) = 0;
    end
        
    % dziel� na obiekty
    CC = bwconncomp(bw);
    
    output = zeros(size(bw));
    removed = zeros(size(bw));

    distMeasure = 0.05 * width;
    distMeasure = distMeasure* distMeasure;
    
    divider = 1.0 / (width*width);
    
    distMeasure2 = 0.05 * height;
    distMeasure2 = distMeasure2 * distMeasure2;
    
    divider2 = 1.0 / (height * height);
    
    minSize = 0.001 * width * height;
    
    for o = 1: CC.NumObjects
        % pobieramy wsp�rz�dne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);        
        
        % rozmiar
        objSize = length(x);
        if objSize < minSize
            continue;            
        end
        
        % �rodek cie�ko�ci
        objX = mean(x);
        objY = mean(y);
        
        % sprawdzamy czy obiekt nie lezy pod ko�ci�
        if boneContourOrg(floor(objX)) ~= 0 && boneContourOrg(floor(objX)) < objY
            for p = 1: objSize
                removed(y(p), x(p)) = 128; 
            end               
            continue;
        end
        
        % dla ka�dego punktu obiektu obliczamy prawdopodobie�stwo
        for p = 1: objSize
            xx = x(p);
            yy = y(p);
            
            % odleg�o�� punktu od stawu
            jointDist = ((xx - jointX)^2 + 4*(yy - jointY)^2);
            
            % odleg�o�� od ko�ci
            boneDist = width * height;
            for b = 1: width
                if boneContourOrg(b) ~= 0
                    dist = ((xx - b)^2 + 4*(yy - boneContourOrg(b))^2); 
                    if dist < boneDist
                        boneDist = dist;
                    end
                end
            end
            boneDist = (boneDist);

            probability = 1;

            if jointDist > distMeasure
                probability = probability - jointDist * divider;
                if boneDist > distMeasure2
                    probability = probability - boneDist * divider2; 
                end
            end
            
            if probability > 0        
                output(yy, xx) = probability; 
            end
            
        end
        
    end

    output = uint8(output * 255);
    
 
end

function output = mMinMax(image, side)

    [height, width] = size(image);
    halfSide = floor((side - 1)/2);
    
    image = double(image);
    
    output = zeros(size(image));
    for x = 1: width - side
        for y = 1: height - side
            sub = image(y:y + side,x:x + side);
            diff = max(sub(:)) - min(sub(:));
            
            output(y + halfSide, x + halfSide) = (image(y + halfSide, x + halfSide)/255)*diff* 100;
        end
    end
    
    minV = min(output(:));
    maxV = max(output(:));
    
    output = double(output);
    output = (output - minV)/ (maxV - minV);
    output = 1 - output;
end
