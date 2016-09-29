function mExample

    % obraz na wejœcie
    inputImage = '2013-10-15-S0012-T0022.png';
    
    % wsó³rzêdne pozwalaj¹ce wyci¹æ dane USG, bez ramki z oprogramowania
    XMove = 80;
    YMove = 70;
    WidthMove = 736;
    HeightMove = 561;
    
    % odczytaj obraz
    img = imread(inputImage);
    
    % wytnij obraz
    img = img(YMove:HeightMove,XMove:WidthMove); 

    % znajdz skórê
    skinContour = mFindSkin(img, 0.5, 0.65);
    
    if isempty(skinContour)
        return; 
    end
            
    boneBasicTheshold=0.98;
    boneImprThreshold=0.9;%0.9
    distanceThreshold=20;
    overlapThreshold=0.5;

    type = 0; 
    
    % znajdŸ kontury koœci
    [map, boneContours] = mFindBonesCenters(img, skinContour, boneBasicTheshold, ...
                                          boneImprThreshold, distanceThreshold, ...
                                          overlapThreshold, type);
    if isempty(boneContours)
        return;
    end
    
    boneContourType = 0;    
    % oblicz dolny kontur koœci
    boneContour = mDefineBoneContour(img, boneContours, boneContourType);
        
    % zgadywanie wspó³rzêdnych stawu
    boneBasicTheshold=0.97;
    boneImprThreshold=0.87;            
    [~, ~, jointX, jointY] = mTestBone(img, skinContour, boneBasicTheshold, boneImprThreshold);            

    % okreœlenie regionu zapalenia
    otherBasicThreshold=0.65;    
    output = mEstimateSynovitis(img, skinContour, boneContour, jointX, jointY, otherBasicThreshold);           

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PREZENTACJA
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for i = 1: 3
        image(:,:,i) = img;
    end
    
    for x = 1: size(image, 2)
        sk = skinContour(x);
        image(sk - 2: sk + 2, x, 1) = 255; 
        if boneContour(x) > 0
            bk = boneContour(x);
            image(bk-2:bk+2, x, 2) = 255; 
        end
    end
    image(:,:,3) = output;
    imshow(output);
    %imshow(image);
end