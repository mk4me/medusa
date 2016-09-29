function [contour, bw] = mImproveSkin(image, contour, threshold)
    
    threshold = mDefineThreshold(image, threshold);
    
    % tworzymy obraz binarny
    bw = zeros(size(image));
    bw(image < threshold) = 1;
    bw = imfill(bw);
    
    [height, width] = size(bw);
    
    for i = 1: length(contour)
        bw(1:contour(i), i) = 0; 
        bw(contour(i) + 100: height, i) = 0; 
    end    
    
    CC = bwconncomp(bw);
    
    for o = 1: CC.NumObjects
        % pobieramy wspó³rzêdne obiektu
        [x, y] = mGetCoefficients(CC.PixelIdxList{o}, height);
        
        mask = zeros(size(bw));
        
        for i = 1: length(x)
            mask(y(i), x(i)) = 1;
        end
        
        % znajdujemy otoczkê obiektu
        border = bwmorph(mask,'remove');
        [r, c] = find(border == 1);
        
        % znajdujemy najbli¿sz¹ odleg³oœæ miêdzy otoczk¹ a skór¹
        minDistance = width * height;
        for xx = 1: width
            for p = 1: length(r)
                distance = sqrt((c(p) - xx)^2 + (r(p) - contour(xx))^2); 
                if distance < minDistance
                    minDistance = distance;
                end
            end                
        end
        
        if minDistance < 2
            for xx = min(x): max(x)
                for yy = height: -1: 1
                    if mask(yy,xx) == 1
                        if yy > contour(xx)
                            contour(xx) = yy;
                            break; 
                        end
                    end
                end
                
            end
        end        
    end    
end
