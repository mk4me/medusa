
function [map, contours, jointX, jointY] = mTestBone(image, skinContour, threshold1, threshold2)

    contours = [];

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

    map = bwBig + bw;
    map(map > 1) = 1;
    map = imgaussfilt(map,4);
    map(map > 0.5) = 1;
    map(map <= 0.5) = 0;
       
    map1 = map;
    
    % dzielimy na poszczeg�lne obiekty
    CC = bwconncomp(map); 
    [height, width] = size(map);
    
    map2 = zeros(size(map1));
    
    for x = 1: width
        map2(skinContour(x), x) = 1; 
    end
    
    % znajdujemy punkt najni�ej
    maxY = 0;
    for y = height: -1: 1
        if sum(map(y,:))>0
            maxY = y;
            break;
        end
    end
    
    distance = 20;
    for o = 1: CC.NumObjects
        % pobieramy wsp�rz�dne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);

        remove = 0;
        for p = 1: length(x)
            % usuwamy obiekty znajduj�ce si� nad i dotykaj�ce powierzchni
            % sk�ry
            currentDistance = y(p) - skinContour(x(p));
            if currentDistance < distance
                remove = 1;
                break;
            end
        end
        
        if remove == 1
            % sprwdzamy maksymaln� wsp�rz�dn� Y obiektu
            objMaxY = max(y);
            objMinY = min(y);
            
            if objMaxY - objMinY < abs(objMaxY - maxY)
                for p = 1: length(x)
                    map(y(p),x(p)) = 0; 
                end
            else
                for p = 1: length(x)
                    if y(p) < objMinY + (objMaxY - objMinY)/2
                        map(y(p),x(p)) = 0; 
                    end
                end
            end
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % tutaj znajdujemy obiekty wzgl�dem wielko�ci
    CC = bwconncomp(map); 
    objSize = zeros(CC.NumObjects, 1);
    objCoeffs = zeros(CC.NumObjects, 4);
    objType = zeros(CC.NumObjects, 1);
    objRL = zeros(CC.NumObjects, 1);
    
    middle = width / 2;
    
    for o = 1: CC.NumObjects
        % pobieramy wsp�rz�dne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);

        objSize(o) = length(x);
        objCoeffs(o,1) = min(x);
        objCoeffs(o,2) = max(x);
        objCoeffs(o,3) = min(y);
        objCoeffs(o,4) = max(y);
    
        objWidth = objCoeffs(o,2) - objCoeffs(o, 1);
        
        if objCoeffs(o, 1) == 1 
            objRL(o) = 1; % lewa strona od brzegu
        end
        
        if objCoeffs(o, 1) < middle && middle - objCoeffs(o,1) > objWidth / 2
            objRL(o) = 2;  % lewa strona
        end
        
        if objCoeffs(o, 2) == width
            objRL(o) = 3; %% prawa strona od brzegu
        end
        
        if objCoeffs(o, 2) > middle && middle - objCoeffs(o,1) < objWidth / 2
            objRL(o) = 4;  % lewa strona
        end
        
        if objCoeffs(o, 1) > width / 2
            objRL(o) = 4; % prawa strona
        end
        
        for p = 1: length(x)
            if bw(y(p), x(p)) == 1
                objType(o) = 1;
                break;
            end
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    map4 = zeros(size(map));
    objSizeOrg = objSize;
    for i = 1: CC.NumObjects
        % znajdx najwi�kszy obiekt
        [maxV, idx] = max(objSize);
        % usu� go z listy do przegl�dania
        objSize(idx) = 0;

        if objRL(idx) == 0
            objSize(idx) = -maxV;
            continue;
        end
        % je�eli ten obiekt nadaje si� do wy�wietlania jako ko��
        if objType(idx) == 1
            
            doNotDraw = 0;
            % sprawd� czy nie znajduje si� pod nim jaki� obiekt
            for o = 1: CC.NumObjects
                if idx ~= o
                    % czy jest jakis obiekt pod
                    if objCoeffs(o, 3) > objCoeffs(idx, 4)
                        switch objRL(idx)
                            case 0                            
                            case 1 % lewa strona od brzegu
                                if objRL(o)== 1 || objRL(o) == 2
                                    if objCoeffs(idx,2) - objCoeffs(idx, 1) < 3 * (objCoeffs(o, 2) - objCoeffs(o, 1))
                                        doNotDraw = 1; 
                                        break
                                    end
                                end
                            case 2 % lewa strona
                                if objRL(o)== 1 || objRL(o) == 2 || objRL(o) == 0
                                    if objCoeffs(idx,2) - objCoeffs(idx, 1) < 3 * (objCoeffs(o, 2) - objCoeffs(o, 1))
                                        doNotDraw = 1; 
                                        break
                                    end
                                end                                
                            case 3 %% prawa strona od brzegu
                                if objRL(o)== 3 || objRL(o) == 4
                                    if objCoeffs(idx,2) - objCoeffs(idx, 1) < 3 * (objCoeffs(o, 2) - objCoeffs(o, 1))
                                        doNotDraw = 1; 
                                        break
                                    end
                                end                                                                
                            case 4 % prawa strona
                               if objRL(o)== 3 || objRL(o) == 4 || objRL(o) == 0
                                    if objCoeffs(idx,2) - objCoeffs(idx, 1) < 3 * (objCoeffs(o, 2) - objCoeffs(o, 1))
                                        doNotDraw = 1; 
                                        break
                                    end
                                end                                
                        end
                    end
                end
            end
            
            if doNotDraw == 1
                objType(idx) = 0;
            else
                % pobierz jego wsp�rz�dne
                [x, y] = mGetCoefficients(CC.PixelIdxList{idx}, height);

                minX = min(x);
                maxX = max(x);
                contour = zeros(maxX - minX + 1,2);
                for p = 1: length(x)
                    map4(y(p), x(p)) = 1; 
                    
                    if y(p) > contour(x(p) - minX + 1)
                        contour(x(p) - minX + 1, 1) = y(p);
                        contour(x(p) - minX + 1, 2) = x(p);
                    end
                end
                contours = [contours; {contour}];
                break;
            end
            
        end
        
    end
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    boneFirstWidth = objCoeffs(idx, 2) - objCoeffs(idx, 1);
    map5 = zeros(size(map));
    bones = [];
    if boneFirstWidth < 0.9 * width

        objSize = abs(objSize);
        bones = [];
        for o = 1: CC.NumObjects
            % znajdz najwi�kszy obiekt
            [maxV, idx2] = max(objSize);
            % usu� go z listy do przegl�dania
            objSize(idx2) = 0;        

            switch objRL(idx)
                case 0                            
                case 1 % lewa strona od brzegu
                    if objRL(idx2) == 1 || objRL(idx2) == 2
                        continue;
                    end
                case 2 % lewa strona
                    if objRL(idx2) == 1 || objRL(idx2) == 2
                        continue;
                    end
                case 3 %% prawa strona od brzegu
                    if objRL(idx2) == 3 || objRL(idx2) == 4
                        continue;
                    end

                case 4 % prawa strona
                    if objRL(idx2) == 3 || objRL(idx2) == 4
                        continue;
                    end    
            end

            % sprawd� czy nie jest nad pierwsz� ko�ci� (w ca�o�ci)
            if objCoeffs(idx2, 2) < objCoeffs(idx, 2) && ...
               objCoeffs(idx2, 1) > objCoeffs(idx, 1)
                continue;
            end
            
            % lub pokrywa si� 50%
            boneWidth = objCoeffs(idx2, 2) - objCoeffs(idx2, 1);
            maxX = min(objCoeffs(idx2, 2), objCoeffs(idx, 2));
            minX = max(objCoeffs(idx2, 1), objCoeffs(idx, 1));
            partWidth = maxX - minX;
            if partWidth >= boneWidth/2
                continue; 
            end
            
            % sprwadzamy czy bie��cy obiekt nie jest nad inn� ko�ci� w tej
            % grupie
            remove = 0;
            for b = 1: length(bones)
                currentBone = bones(b);
                
                if objCoeffs(idx2, 4) < objCoeffs(currentBone, 4)                
                    % sprawd� czy nie jest nad obiektem w ca�o�ci
                    if objCoeffs(idx2, 2) <= objCoeffs(currentBone, 2) && ...
                       objCoeffs(idx2, 1) >= objCoeffs(currentBone, 1)
                        remove = 1;
                        break;
                    end
                    % sprawd� czy nie jest nad obiektem w ca�o�ci
                    if objCoeffs(idx2, 2) >= objCoeffs(currentBone, 2) && ...
                       objCoeffs(idx2, 1) <= objCoeffs(currentBone, 1)
                        remove = 1;
                        break;
                    end
                    
                    % sprawd� czy cz�ciowo nie nachodz�
                    if (objCoeffs(idx2, 1) <= objCoeffs(currentBone, 1) && ...
                       objCoeffs(idx2, 2) >= objCoeffs(currentBone, 1)) || ...
                       (objCoeffs(idx2, 1) <= objCoeffs(currentBone, 2) && ...
                       objCoeffs(idx2, 2) >= objCoeffs(currentBone, 2))
                        remove = 1;
                        break;
                    end
                end
            end
            
            if remove == 1
                continue
            end

            skip = 0;
            for b = 1: length(bones)
                currentBone = bones(b);
                % bie��cy obiekt znajduje si� pod poprezdnim
                if objCoeffs(idx2, 4) > objCoeffs(currentBone, 4)                
                    % sprawd� czy nie jest pod obiektem w ca�o�ci
                    if objCoeffs(idx2, 2) <= objCoeffs(currentBone, 2) && ...
                       objCoeffs(idx2, 1) >= objCoeffs(currentBone, 1)
                        skip = 1;
                        break;
                    end
                end        
            end
            
            if skip == 1
                continue;                
            end
            % pobierz jego wsp�rz�dne
            [x, y] = mGetCoefficients(CC.PixelIdxList{idx2}, height);            
                        
            bones = [bones idx2];

            minX = objCoeffs(idx2, 1);
            maxX = objCoeffs(idx2, 2);
            contour = zeros(maxX - minX + 1,2);
            for p = 1: length(x)
                map5(y(p), x(p)) = 1; 

                if y(p) > contour(x(p) - minX + 1)
                    contour(x(p) - minX + 1, 1) = y(p);
                    contour(x(p) - minX + 1, 2) = x(p);
                end
            end
            contours = [contours; {contour}];            
            
            if length(bones) == 3
                break;
            end

        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    sndBoneCount = length(bones);
    jE = -1;
    if sndBoneCount == 0
        [x, y] = mGetCoefficients(CC.PixelIdxList{idx}, height);
        % przelicz wsp�rz�dne jointa dla pierwszej ko�ci
        [jS, valS] = FindJointCentral(x, y, width);                        
    else
        [x, y] = mGetCoefficients(CC.PixelIdxList{idx}, height);
        side = 1; 
        switch objRL(idx) 
            case 1 % lewa strona od brzegu
            case 2 % lewa strona
            case 3 %% prawa strona od brzegu
                side = 0;
            case 4 % prawa strona
                side = 0;
        end
        [jS, valS] = FindJoint(x, y, width, side);               
        
        idx2 = -1;
        adds = [];
        if sndBoneCount == 1
            idx2 = bones(1);
        else            
            totalDist = width;
            % nale�y wytypowac,kt�r� ko�� uwzgl�dniamy
            for b = 1: length(bones)
                currentBone = bones(b);
                
                % ko�� musi znajdowa� si� w okolicy mojej dobrej ko�ci                
                if (objCoeffs(idx, 3) < objCoeffs(currentBone, 3) &&...
                   objCoeffs(idx, 4) > objCoeffs(currentBone, 3)) ||...
                   (objCoeffs(idx, 3) < objCoeffs(currentBone, 4) &&...
                   objCoeffs(idx, 4) > objCoeffs(currentBone, 4))
                    dist = min(abs(objCoeffs(idx, 1) - objCoeffs(currentBone, 2)), ...
                               abs(objCoeffs(idx, 2) - objCoeffs(currentBone, 1)));
                    if dist < totalDist
                        totalDist = dist;
                        idx2 = currentBone;
                    end
                end                
            end
            
            if idx2 ~= -1
                % kosci mog� na siebie nachodzi�, wtedy interesuj� nas
                % wszystkie
                for b = 1: length(bones)
                    currentBone = bones(b);
                    if currentBone ~= idx2
                        if (objCoeffs(idx2, 1) < objCoeffs(currentBone, 1) && ...
                           objCoeffs(idx2, 2) > objCoeffs(currentBone, 1)) || ...
                           (objCoeffs(idx2, 1) < objCoeffs(currentBone, 2) && ...
                           objCoeffs(idx2, 2) > objCoeffs(currentBone, 2))
                            adds = [adds currentBone];
                        end
                    end
                end
            end
            
        end
        
        if idx2 ~= -1
            [x, y] = mGetCoefficients(CC.PixelIdxList{idx2}, height);
            for i = 1: length(adds)
                 [xx, yy] = mGetCoefficients(CC.PixelIdxList{adds(i)}, height);
                 x = [x; xx];
                 y = [y; yy];
            end
            side = 1; 
            switch objRL(idx2) 
                case 1 % lewa strona od brzegu
                case 2 % lewa strona
                case 3 %% prawa strona od brzegu
                    side = 0;
                case 4 % prawa strona
                    side = 0;
            end
            [jE, valE] = FindJoint(x, y, width, side);                           
        end
    end
    

%     map = image;
%     map(:,:,2) = uint8(map4*255);
%     map(:,:,3) = uint8(map5*255);
    

    jM = jS;
    val = valS;
    if jE ~= -1   
        jM = floor((jM + jE)/2);
        val = max(valS, valE);
    end
%     map(:,jM,:) = 255;
%     map(val, :, :) = 255;
    
    jointY = val;
    jointX = jM;
    
    map = map4 + map5;
    map(map>1) = 1;
    map = uint8(map*255);
    
    img1(:,:,1) = bw;
    img1(:,:,2) = bwBig;
    img1(:,:,3) = map;
    img1(:,:,4) = map1;
    img1(:,:,5) = map4;
    img1(:,:,6) = map5;
    return;
    
 
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



function [jM, val] = FindJoint(x, y, width, side)
    contour = zeros(width, 1);
    for p = 1: length(x)
        if y(p) > contour(x(p))
            contour(x(p)) = y(p);
        end
    end
    
    for i = 1: width
        if contour(i) ~= 0
            contourStart = i;
            break;
        end
    end
    
    for i = width : -1: 1
        if contour(i) ~= 0
            contourEnd = i;
            break;
        end
    end
    
    contour = contour(contourStart:contourEnd);
    
    diff = zeros(size(contour));
    for i = 2: contourEnd - contourStart
        diff(i-1) = abs(contour(i) - contour(i-1));
    end
    odch = std(diff);
    
    if side == 1 % lewa
        jM = contourEnd;
    else
        jM = contourStart;
    end
    
    contourWidth = contourEnd - contourStart;
    
    if odch > 1.2
        for i = 1: 3
            [maxV, index] = max(diff);
            diff(index) = 0;
            if maxV < 15
                break;
            end
            
            if index < 0.7 * contourWidth && side == 1
                    continue;
            end
            if index > contourWidth / 2 && side ~= 1
                continue;
            end
            
%             [index contourWidth index/contourWidth*100  maxV]
            jM = index + contourStart;
            break;
        end
    end
    
    val = 0;
    for p = 1: length(x)
        if jM == x(p)
            if y(p) > val
                val = y(p);
            end
        end
    end
end


function [jM, val] = FindJointCentral(x, y, width)

    contour = zeros(width, 1);
    for p = 1: length(x)
        if y(p) > contour(x(p))
            contour(x(p)) = y(p);
        end
    end
    
    for i = 1: width
        if contour(i) ~= 0
            contourStart = i;
            break;
        end
    end
    
    for i = width : -1: 1
        if contour(i) ~= 0
            contourEnd = i;
            break;
        end
    end
    
    contour = contour(contourStart:contourEnd);
    
    diff = zeros(size(contour));
    for i = 2: contourEnd - contourStart
        diff(i-1) = abs(contour(i) - contour(i-1));
    end
       
    [maxV, index] = max(diff);
    diff(index) = 0;

    jM = index + contourStart;
    
    val = 0;
    for p = 1: length(x)
        if jM == x(p)
            if y(p) > val
                val = y(p);
            end
        end
    end    
end