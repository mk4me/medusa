% image - obraz wejœciowy, potrzebny tylko dla rozmiaru
% boneContours - dane z mteody mFindBonesCenters
% type - sposób zapisu koœci: 0 - tylko uwzglêdniamy wspó³rzêdne znane z
% danych wejœciowych przeci¹gaj¹c punkty pocz¹tkowy i koñcowy do granic
% obrazu; !0 - aproksymacja krzyw¹

% boneContour - wspó³rzêdne Y dla kolejnych wartoœci X
function boneContour = mDefineBoneContour(image, boneContours, type)

    [~, width, ~] = size(image);
    
    boneContour = zeros(width, 1);
    
    for i = 1: length(boneContours)
        contour = boneContours{i};
        for p = 1: size(contour,1);
            x = contour(p, 2);
            y = contour(p, 1);
            boneContour(x) = max(boneContour(x), y);
        end
    end    

 % sprawd¿my czy na pocz¹tku jest koœæ
    if boneContour(1) == 0
        for index = 2: width
            if boneContour(index) ~= 0
                boneContour(1:index-1) = boneContour(index);
                break;
            end           
        end
    end

    % sprawdŸmy czy na koñcu jest koœæ
    if boneContour(width) == 0
        for index = width: - 1: 1
            if boneContour(index) ~= 0
                boneContour(index+1:width) = boneContour(index);
                break;
            end
        end        
    end    
    
    if type == 0
        return
    else
    
        % a mo¿e by tak dodac punkty na podstawie funkcji??
        contour = [];
        for x = 1: width
            if boneContour(x) ~= 0
                contour = [contour; boneContour(x) x];
            end
        end
        
        p = polyfit(contour(:,2), contour(:,1), 30);

        
        boneContour = polyval(p, [1:width]);               
        
    end
end

function contours = mPolyFit(contours)

    for c = 1: length(contours)
        contour = contours{c};
        
        p = polyfit(contour(:,2), contour(:,1), 10);

        contour(:,1) = polyval(p, contour(:,2));
        
        contours{c} = contour;
    end
end