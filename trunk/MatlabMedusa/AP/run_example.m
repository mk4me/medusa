clear all;
clc;

file = 'example.png';

%---------------
%main procedures
tic;
M = 4; R = 20; thr = 8; med_par = 11;
[bone_line] = find_bone_line2(file,M,R,thr,med_par);
disp(['Bone line time: ' num2str(toc)]);

tic;
dist = 100; r = 20;
[joint] = find_joint(bone_line,file,dist,r);
disp(['Joint time: ' num2str(toc)]);

tic;
thr = 35;
[map] = find_synovitis_region(file,bone_line,joint,thr);
disp(['Synovitis time: ' num2str(toc)]);

%%
%------------
%presentation
image = double(rgb2gray(imread(file)));
[X,Y] = size(image);
RGB = zeros(X,Y,3);
RGB(:,:,1) = image;RGB(:,:,2) = image;RGB(:,:,3) = image;
R = RGB(:,:,1); G = RGB(:,:,2); B = RGB(:,:,3);
R(bone_line==1) = 255;
G(joint==1) = 255;
RGB(:,:,1) = R; RGB(:,:,2) = G; RGB(:,:,3) = B;
colors = jet;
for i = 1:X
    for j = 1:Y
        if (map(i,j) > 0)
            RGB(i,j,:) = 2*255*reshape(colors(round(64*map(i,j)/thr),:),1,1,3);
        end
    end
end


imshow(uint8(RGB));