function [boneData, skinData, jointData, synovatisImage, complete] = gatherData(inputImage)

    complete = false;
    boneData = [];
    skinData = [];
    jointData = [];
    synovatisImage = [];
    file = inputImage;

    %---------------
    %main procedures
    try
    M = 4; R = 20; thr = 8; med_par = 11;
    [bone_line] = find_bone_line2(file,M,R,thr,med_par);
    dist = 100; r = 20;
    [joint, jx, jy] = find_joint(bone_line,file,dist,r);
    
    thr = 35;
    [map] = find_synovitis_region(file,bone_line,joint,thr);
    
    boneData = binary2table(bone_line);
    %skinData = binaryskinContour;
    jointData = [jx, jy];
    map(isnan(map)) = 0;
    
    synovatisImage = im2bw(map, 0.2);
    complete = true;
    catch me
        complete = false;
    end
end


function [tab] = binary2table(image)
    [x, y] = size(image);
    tab = zeros(x,1);
    for xx = 1:x
        for yy = 1:y
            if image(xx,yy) == 1
                tab(xx)=yy;
            end
        end
    end
end