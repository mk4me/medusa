% obraz na wejœcie
function pjConverter(input, output)
    if not(isdir(output))
        mkdir(output)
    end
    % '../data/20160916-cleanIL_picture_set/all/','../data/out-AP/'
    files = dir(strcat(input, '/*.png'));
    fileID = fopen(strcat(output, '/data-popowicz.csv'),'w');
    %inputImage = '2013-10-15-S0012-T0022.png';
    for file = files'
        [~, name, ~] = fileparts(file.name);
        inputImage = strcat(input, '/', file.name);
        [boneData, skinData, jointData, synovatisImage, complete] = gatherData(inputImage);
  
        if (complete)
            outFile = strcat(output, './', name, '-bin-popowicz.png');
			grayImage = im2bw(synovatisImage, 0.2);
			rgbImage = uint8(cat(3, grayImage.*255, grayImage.*255, grayImage.*255));
            imwrite(rgbImage, outFile);
            annotationsCount = csvCreator.getNumberOfBones(boneData) + 2;
            csvCreator.writeFileHeader(fileID, name, annotationsCount);
            %csvCreator.writeSynovitis(fileID, tstData);
            csvCreator.writeBone(fileID, boneData);
            %csvCreator.writeSkin(fileID, skinData);
            csvCreator.writeJoint(fileID, jointData);
        end
    end
    
    fclose(fileID);
end

