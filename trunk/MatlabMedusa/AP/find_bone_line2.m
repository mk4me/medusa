function [bone_line] = find_bone_line2(file,M,R,thr,med_par)
%sugerowane parametry wej?ciwoe:
%file - plik png z szerym obrazem USG (nie doppler)
%M = 4, R = 20, thr = 8, med_par = 11;
% wyj?cie - bone_line - obraz binarny z lini? ko?ci

image = double(rgb2gray(imread(file)));
[X,Y] = size(image);

image = medfilt2(image,[med_par,med_par]);

local_max = 0*image;
for y = 1:Y
    column_max = 0;
    for x = X:-1:1
        column_max = max(column_max,image(x,y));
        local_max(x,y) = column_max;
    end
end


filtered = -inf*image;
M_2 = round(M/2-1);
for x = 1:X-R
    for y = M:Y-M
        filtered(x,y) = max(local_max(x+R,y-M_2:y+M_2));
    end
end


bone = (image-filtered)>thr;
bone_dilated = imdilate(bone,ones(7,7));
bone_dilated(end:-1:end-50,:) = 0;
bone_dilated(1:50,:) = 0;

[labeledImage, ~] = bwlabel(bone_dilated);
stats = regionprops(labeledImage,'Area');
areas = [stats.Area];
[max_area,b] = max(areas);
bone_largest = imfill(labeledImage==b,'holes');
for i = 1:size(bone_largest,2)
    if (sum(bone_largest(:,i)) > 0)
        bone_dilated(:,i) = 0;
    end
end
[labeledImage, ~] = bwlabel(bone_dilated);
stats = regionprops(labeledImage,'Area');
areas = [stats.Area];
[max_area2,b] = max(areas);
if (max_area2 > 0.1*max_area)
    bone_largest = bone_largest+imfill(labeledImage==b,'holes');
end
for i = 1:size(bone_largest,2)
    if (sum(bone_largest(:,i)) > 0)
        bone_dilated(:,i) = 0;
    end
end
[labeledImage, ~] = bwlabel(bone_dilated);
stats = regionprops(labeledImage,'Area');
areas = [stats.Area];
[max_area2,b] = max(areas);
if (max_area2 > 0.1*max_area)
    bone_largest = bone_largest+imfill(labeledImage==b,'holes');
end

bone = bone_largest.*bone;
bone_line = 0*bone;
for i = 1:size(bone,2)
    for j = 1:size(bone,1)
        if (bone(j,i)==1)
            bone_line(j,i) = 1;
            break;
        end
    end
end

[I,J] = ind2sub([X,Y],find(bone_line==1));
[~,b] = sort(J);
J = J(b);
I = I(b);
I_new = I;
for i = 1:Y    
    if (sum(J==i)==1)
        I_new(J==i) = floor(median(I(logical((J>i-10).*(J<i+10)))));
    end
end
I = I_new;
bone_line = zeros(X,Y);
for i = 1:size(J,1)
    if ((J(i) > 0)&&(I(i) > 0))
        bone_line(I(i),J(i)) = 1;
    end
end

end