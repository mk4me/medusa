function [map] = find_synovitis_region(file,bone_line,joint,thr)

%thr = 30; %regulowa? by zwi?kszy?/zmniejszy? czu?o?? wykrywania synovitis
%map - mapa p-pstwa synovitisu
%joint, bone_line - z odpowiednich funkcji


gray_image = rgb2gray(imread(file));
[X,Y] = size(gray_image);

%creating PROHIBITED regions
prohibited = zeros(X,Y);
for y = 1:Y
    %below bone line
    for x = 1 : X
        if (bone_line(x,y) == 1)
            prohibited(x:X,y) = 1;
            break;
        end
    end
    %below joint  
    for x = X : -1 : 1
        if (joint(x,y) == 1)
            prohibited(x:X,y) = 1;
            break;
        end
    end
    %above skin leyer
%     for x = X : -1 : 1
%         if (skin_line(x,y) == 1)
%             prohibited(x:-1:1,y) = 1;
%             break;
%         end
%     end
end
%left/right no-bone region
for y = 1:Y    
    if (sum(bone_line(:,y)) == 0)
       prohibited(:,y) = 1; 
    else
        break;
    end
end
for y = Y:-1:1    
    if (sum(bone_line(:,y)) == 0)
       prohibited(:,y) = 1; 
    else
        break;
    end
end

starting_points = (1-prohibited).*joint;

map = distance_calc2(starting_points,prohibited,double(gray_image),4,2);
map(map==0) = inf;
map = (thr-map).*(map<thr);

end

