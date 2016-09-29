function [boneData, skinData, jointData, synovatisImage, complete] = gatherData(inputImage)

    complete = false;
    boneData = [];
    skinData = [];
    jointData = [];
    synovatisImage = [];
    % ws�rz�dne pozwalaj�ce wyci�� dane USG, bez ramki z oprogramowania
    XMove = 80;
    YMove = 70;
    WidthMove = 736;
    HeightMove = 561;

    % odczytaj obraz
    img = imread(inputImage);

    % wytnij obraz
    img = img(YMove:HeightMove,XMove:WidthMove);

    % znajdz sk�r�
    skinContour = mFindSkin(img, 0.5, 0.65);

    if isempty(skinContour)
        return;
    end

    boneBasicTheshold=0.98;
    boneImprThreshold=0.9;%0.9
    distanceThreshold=20;
    overlapThreshold=0.5;

    type = 0;

    % znajd� kontury ko�ci
    [map, boneContours] = mFindBonesCenters(img, skinContour, boneBasicTheshold, ...
        boneImprThreshold, distanceThreshold, ...
        overlapThreshold, type);
    if isempty(boneContours)
        return;
    end

    boneContourType = 0;
    % oblicz dolny kontur ko�ci
    boneContour = mDefineBoneContour(img, boneContours, boneContourType);

    % zgadywanie wsp�rz�dnych stawu
    boneBasicTheshold=0.97;
    boneImprThreshold=0.87;
    [~, ~, jointX, jointY] = mTestBone(img, skinContour, boneBasicTheshold, boneImprThreshold);

    % okre�lenie regionu zapalenia
    otherBasicThreshold=0.65;
    output = mEstimateSynovitis(img, skinContour, boneContour, jointX, jointY, otherBasicThreshold);
    
    % powr�t do wej�ciowych wsp�rz�dnych
    %boneData =  boneContour;
    shift_zeros = zeros(XMove, 1);
    boneData = vertcat(shift_zeros,  boneContour);
    for i=1:length(boneData)
        if boneData(i) > 0
            boneData(i) = boneData(i) + YMove;
        end
    end
    
    %skinData = skinContour;
    skinData = vertcat(shift_zeros, skinContour);
    for i=1:length(skinData)
        if skinData(i) > 0
            skinData(i) = skinData(i) + YMove;
        end
    end
    jointData = [jointX + XMove, jointY + YMove];
    
    synovatisImage = zeros(720, 960, 3); 
    %synovatisImage = im2bw(output, 0.2);
    tmp = im2bw(output, 0.2);
    synovatisImage(YMove:HeightMove,XMove:WidthMove, 1) = tmp;
    synovatisImage(YMove:HeightMove,XMove:WidthMove, 2) = tmp;
    synovatisImage(YMove:HeightMove,XMove:WidthMove, 3) = tmp;
    complete = true;
end