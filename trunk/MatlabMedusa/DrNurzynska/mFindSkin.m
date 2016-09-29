% Metoda znajduj�ca kraw�d� sk�ry na obrazie (wyznaczany na podstawie
% najciemniejszego regionu na g�rze obrazu)

% image - obraz wej�ciowy
% threshold1 - podstawowe progowanie danych do znajdowania sk�ry
% threshold2 - dodatkowy (ja�niejszy pr�g), kt�ry dok�adniej znajduje sk�re

% contour - wsp�rz�dne Y kolejnych punkt�w sk�ry (wsp�rz�dne X to indeks
% tablicy)
function contour = mFindSkin(image, threshold1, threshold2)

    [height, width] = size(image);
    
    % znajdujemy warto�� dla jakiej podzielimy obraz
    threshold = mDefineThreshold(image, threshold1);
    
    % tworzymy obraz binarny
    bw = zeros(size(image));
    bw(image < threshold) = 1;
    bw = imfill(bw);
    
    map1 = bw;

    % dzielimy go na poszczeg�lne obiekty    
    CC = bwconncomp(bw);     

    % bliczamy parametry opisuj�ce obiekty
    objSize = zeros(CC.NumObjects, 1);
    minY = height * ones(CC.NumObjects, 1);
    maxY = zeros(CC.NumObjects, 1);
    minX = width * ones(CC.NumObjects, 1);
    maxX = zeros(CC.NumObjects, 1);
    coefficients = cell(CC.NumObjects, 1);
    % obliczamy parametry obiekt�w
    for o = 1: CC.NumObjects

        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);

        coefficients(o) = {[x y]};
        
        minX(o) = min(x);
        maxX(o) = max(x);
        minY(o) = min(y);
        maxY(o) = max(y);
        objSize(o) = length(x);
    end    
    
    % lista obiekt�w uwzgl�dnionych
    objTaken = zeros(CC.NumObjects, 1);
    
    % znajdujemy obiekt, kt�ry znajduje si� najwy�ej
    [~, minIdx] = min(minY);    
    objTaken(minIdx) = 1;
    minY(minIdx) = height;
    
    % wrysowujemy go w map� sk�ry
    coeffs = coefficients{minIdx};
    x = coeffs(:,1);
    y = coeffs(:, 2);
    map = zeros(size(image));    
    for p = 1: length(x)
        map(y(p),x(p)) = 1;
    end    
    
    % znjdujemy obiekty, kt�re znajduj� si� w s�siedztwie
    borderSize = 15;
    for i = 1: floor(CC.NumObjects/2);
        % kolejny s�siad, kt�ry znajduje si� blisko
        [minV, idx] = min(minY);
        minY(idx) = height;

        % obliczamy minimalny dystans mi�dzy obiektami
        distance = minV - maxY(minIdx);
        
        % je�eli obiekt jest bardzo d�ugi to zmniejszamy dopuszczaln�
        % minimaln� odleg�o�� dwukrotnie
        objWidth = maxX(idx) - minX(idx);
        if objWidth > 0.15 * width && (maxX(idx) > width - 10 || minX(idx) < 10)
            distance = distance / 2;
        end
        % je�eli obiekt jest odpowiednio blisko i jednocze�nie jest zwi�z�y
        if distance < borderSize 
            % uzupe�niamy map� sk�ry
            coeffs = coefficients{idx};
            x = coeffs(:,1);
            y = coeffs(:, 2);
            for p = 1: length(x)
                map(y(p),x(p)) = 1;
            end 
            objTaken(idx) = 1;
        end
    end
       
    % znajdujemy wsp�rz�dne prostej
    contour = mFindContour(map);
    contour1 = contour;

    % KN ICCE poprawiamy jego jako��
    [contour, map2] = mImproveSkin(image, contour, threshold2);
    
    % wyg�adzamy kontur
    contour = mSmoothContour(contour, 10);
    map = bw;
end

function objDensity = mCalculateDensity(object)
    [objHeight, objWidth] = size(object);
    contour = 0;
    for x = 2: objWidth - 1
        for y = 2: objHeight - 1
            if object(y,x) == 1
                sub = object(y-1:y+1, x-1:x+1);
                if sum(sub(:)) < 9
                    contour = contour + 1;
                end
            end
        end
    end

    objDensity = contour / (objWidth * objHeight);
end

function contour = mFindContour(map)
    [height, width] = size(map);
    contour = zeros(width, 1);
    for x = 1: width
        for y = height: -1: 1
            if map(y,x) == 1
                contour(x) = y;
                break;
            end
        end
    end
end

function contour = mSmoothContour(contourIn, neighbours)
    contour = contourIn;
    for x = 1: length(contourIn)
        beginX = x - neighbours;
        if beginX < 1
            beginX = 1;
        end
        endX = x + neighbours;
        if endX > length(contourIn)
            endX = length(contourIn);
        end
        distance = endX - beginX + 1;
        contour(x) = floor(sum(contourIn(beginX:endX))/distance);
    end
end