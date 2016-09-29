% image - obraz wejœciowy
% skinContour - kontur skóry uzyskany metod¹ mFindSkin
% boneContour - kontur koœci uzyskany metoa mDefineBoneContour
% jointX,jointY - wspó³rzêdne stawu z metody mTestBone
% threshold - próg wyznaczania synovitis

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
    
    % zmiana uwzglêdniaj¹ca to, ¿e kontury nie pokrywaj¹ ca³ej d³ugoœci
    boneContourOrg = boneContour;
    maxV = max(boneContour);
    boneContour(boneContour == 0) = maxV;
    
    % zmiana pozwalaj¹ca na poszukiwania trochê ni¿ej, bo inaczej tracê tak
    % na prawdê staw
    boneContour = boneContour + 20;
    boneContour(boneContour > height) = height;

    % usuwam elementy, które s¹ nad skór¹ oraz pod konturem koœci
    for i = 1: length(skinContour)
        bw(1:skinContour(i), i) = 0; 
        val = floor(boneContour(i));
        bw(val:height, i) = 0;
        % KN 25.12.2015 obkiczamy œredni¹ odleg³oœc miêdzy skor¹ a konturem
        dist = floor((boneContour(i) - skinContour(i)) / 2);
        bw(skinContour(i):skinContour(i) + dist, i) = 0;
    end
    
    
    
    % KN 25.12.2015 obliczamy otoczkê wypuk³¹ dla ka¿dego obiektu
    bw = bwconvhull(bw,'objects');    
    % wyg³adzamy j¹ 2016,01,09
    bw = imgaussfilt(double(bw),4); 
    bw(bw > 0.5) = 1;
    bw(bw <= 0.5) = 0;



    % KN 2016.01.10 jeszcze raz usuwamy eleenty, które s¹ pod skor¹, a
    % wysz³y po zaokr¹glaniu obiektów powy¿ej
    % usuwam elementy, które s¹ nad skór¹ oraz pod konturem koœci
    for i = 1: length(skinContour)
        bw(1:skinContour(i), i) = 0; 
        val = floor(boneContour(i));
        bw(val:height, i) = 0;
        % KN 25.12.2015 obkiczamy œredni¹ odleg³oœc miêdzy skor¹ a konturem
        dist = floor((boneContour(i) - skinContour(i)) / 2);
        bw(skinContour(i):skinContour(i) + dist, i) = 0;
    end
        
    % dzielê na obiekty
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
        % pobieramy wspó³rzêdne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);        
        
        % rozmiar
        objSize = length(x);
        if objSize < minSize
            continue;            
        end
        
        % œrodek cie¿koœci
        objX = mean(x);
        objY = mean(y);
        
        % sprawdzamy czy obiekt nie lezy pod koœci¹
        if boneContourOrg(floor(objX)) ~= 0 && boneContourOrg(floor(objX)) < objY
            for p = 1: objSize
                removed(y(p), x(p)) = 128; 
            end               
            continue;
        end
        
        % dla ka¿dego punktu obiektu obliczamy prawdopodobieñstwo
        for p = 1: objSize
            xx = x(p);
            yy = y(p);
            
            % odleg³oœæ punktu od stawu
            jointDist = ((xx - jointX)^2 + 4*(yy - jointY)^2);
            
            % odleg³oœæ od koœci
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
