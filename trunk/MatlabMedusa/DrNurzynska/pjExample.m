
%% Example Title
% Summary of example objective

%% Section 1 Title
% Description of first code block
%'2013-08-21-S0001-T0008'
%region inflammatory synovitis degree of inflammation / hyperplasia, 711, 438, 237, 439, 237, 440, 237
tstData = [10, 10, 20, 20, 30, 30];


fileID = fopen('test.csv','w');
csvCreator.writeFileHeader(fileID, '2013-08-21-S0001-T0008', 5);
csvCreator.writeSynovitis(fileID, tstData);

bone1 = [0 0 0 1 2 4 5 6 6 0 0 0 0 0 22 4 5 6 6 0 0 0 4 4 0];  %# Sample array
csvCreator.writeBone(fileID, bone1);
csvCreator.writeSkin(fileID, tstData);
csvCreator.writeJoint(fileID, tstData);

array = [0 0 0 1 2 4 5 6 6 0 0 0 0 0 22 4 5 6 6 0 0 0 4 4 0];  %# Sample array
edgeArray = diff([0; (array(:) ~= 0); 0]);
indices = [find(edgeArray > 0) find(edgeArray < 0)-1];
tst1 = {};
for i = 1 : size(indices,2)
    tst1 = array(indices(i,1):indices(i,2));
end;
%fprintf(fileID,'2013-08-21-S0001-T0008, %d\n',5);
%fprintf(fileID,'region inflammatory synovitis degree of inflammation / hyperplasia, %d',length(tstData));
%fprintf(fileID,', %d', tstData);
fclose(fileID);

%% Section 2 Title
% Description of second code block
a=2;
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
    imwrite(im2bw(output, 0.2), 'bwSynovitis2.png');
    imshow(image);