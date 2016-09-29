function  [xCoeffs, yCoeffs] = mGetCoefficients(indices, height)
    objSize = length(indices);
    xCoeffs = zeros(objSize, 1);
    yCoeffs = zeros(objSize, 1);
    for p = 1: objSize
        x = ceil(indices(p) / height);
        y = indices(p) - ((x - 1) * height);
        xCoeffs(p) = x;
        yCoeffs(p) = y;
    end    
end