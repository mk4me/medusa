function [joint, posx, posy] = find_joint(bone_line,file,dist,r)
%sugerowane parametry wej?ciwoe:
%bone_line - obraz binarny ko?ci - uzyskany za pomoc? funkcjifind_bone_lin2
%file - plik png z szerym obrazem USG (nie doppler)
% dist = 100, r = 20
% wyj?cie - joint_x, joint_y - po?o?enie stawu

image = double(rgb2gray(imread(file)));
[X,Y] = size(image);

line = bone_line;
line(:,1:round(Y/4)) = 0; line(:,end:-1:end-round(Y/8)) = 0;
[I,J] = ind2sub([X,Y],find(line==1));
[~,b] = sort(J);
J = J(b);
I = Y-I(b);


min_left=0;
min_right=0;
max_center=0;
filtered = zeros(1,Y);
%dist = 100;
for i = 1:Y
    if ((sum(J==i)==1)&&(sum((J<i).*(J>i-dist))>dist/10)&&(sum((J>i).*(J<i+dist))>dist/10))
        min_left = max(I(logical((J<i).*(J>i-dist))));
        mean_left = median(I(logical((J<i).*(J>i-dist))));
        min_right = max(I(logical((J>i).*(J<i+dist))));
        mean_right = median(I(logical((J>i).*(J<i+dist))));
        max_center = max(I(logical((J<i+10).*(J>i-10))));       
    else
        min_left=0;
        min_right = 0;
        max_center=0;
    end
    try
        filtered(i) = (min_right(1)+min_left(1)-2*max_center(1)).*(max_center(1)<mean_right(1)).*(max_center(1)<mean_left(1));
    catch
        filtered(i) = 0;
    end
end

[~,joint_y] = max(filtered);
joint_x = Y-I(J==joint_y);

if (isempty(joint_x))
    joint_x = 1;    
end
if (isempty(joint_y))
    joint_y = 1;
end

joint = zeros(X,Y);
joint(joint_x,joint_y) = 1;
posx = joint_x;
posy = joint_y;
joint = imdilate(joint,fspecial('disk',r)>0);
end