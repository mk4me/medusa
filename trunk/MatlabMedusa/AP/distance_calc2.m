function [dist] = distance_calc2(starting_points,prohibited,image,repeat_max,version)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

[X,Y] = size(image);
dist = inf*(ones(X,Y));
dist(starting_points==1) = 0;


min_intensity = min(min(image(starting_points==1)));
patch_normalized = (image-min_intensity(1));  
    patch_normalized(patch_normalized<0) = 0;
    
    
if (version == 1)
for repeat = 1:repeat_max    
    %1st scan
    for xp = 2:X
        for yp = 2:Y
            if (prohibited(xp,yp)==0)
                dist(xp,yp) = min([dist(xp,yp),...
                    dist(xp-1,yp-1)+patch_normalized(xp-1,yp-1),...
                    dist(xp-1,yp)+patch_normalized(xp-1,yp),...
                    dist(xp,yp-1)+patch_normalized(xp,yp-1)]);                       
            end
        end
    end
    %2nd scan
    for xp = X-1:-1:1
        for yp = Y-1:-1:1
            if (prohibited(xp,yp)==0)
                     dist(xp,yp) = min([dist(xp,yp),...
                    dist(xp+1,yp+1)+patch_normalized(xp+1,yp+1),...
                    dist(xp+1,yp)+patch_normalized(xp+1,yp),...
                    dist(xp,yp+1)+patch_normalized(xp,yp+1)]);  
            end
        end
    end
end
end

if (version == 2)
    for repeat = 1:repeat_max    
    %1st scan
    for xp = 2:X
        for yp = 2:Y
            if (prohibited(xp,yp)==0)
                dist(xp,yp) = min(dist(xp,yp),max(patch_normalized(xp,yp),...
                    min([dist(xp-1,yp-1),dist(xp-1,yp),dist(xp,yp-1)])));                       
            end
        end
    end
    %2nd scan
    for xp = X-1:-1:1
        for yp = Y-1:-1:1
            if (prohibited(xp,yp)==0)
                    dist(xp,yp) = min(dist(xp,yp),max(patch_normalized(xp,yp),...
                    min([dist(xp+1,yp+1),dist(xp+1,yp),dist(xp,yp+1)]))); 
            end
        end
    end
end
end


end

