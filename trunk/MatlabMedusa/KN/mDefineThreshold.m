function threshold = mDefineThreshold(image, threshold)
    
    [height, width] = size(image);
    % obliczamy histogram
    [histogram, ~] = imhist(image);
    % normalizujemy histogram
    histogram = histogram ./ (width * height);
    % obliczamy dystrybuante
    dystrybuanta = zeros(255, 1);
    dystrybuanta(1) = histogram(1);
    for h = 2: 256
        dystrybuanta(h) = dystrybuanta(h-1) + histogram(h);
    end
    % znajdujemy X% najciemniejszych pikseli
    for h = 1: 256
        if dystrybuanta(h) > threshold
            threshold = h;
            break; 
        end
    end
end
