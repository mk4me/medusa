% obraz na wejœcie
function pjConverter(input, output)
    if not(isdir(output))
        mkdir(output)
    end
    files = dir(strcat(input, '/*.png'));
    fileID = fopen(strcat(output, '/data-nurzynska.csv'),'w');
    for file = files'
        [~, name, ~] = fileparts(file.name);
        inputImage = strcat(input, '/', file.name);
        [boneData, skinData, jointData, synovatisImage, complete] = gatherData(inputImage);

        if (complete)
            outFile = strcat(output, './', name, '-bin-nurzynska.png');

            %imwrite(im2bw(synovatisImage, 0.2), outFile);
            imwrite(synovatisImage, outFile);
            annotationsCount = csvCreator.getNumberOfBones(boneData) + 2;
            csvCreator.writeFileHeader(fileID, name, annotationsCount);
            %csvCreator.writeSynovitis(fileID, tstData);
            csvCreator.writeBone(fileID, boneData);
            csvCreator.writeSkin(fileID, skinData);
            csvCreator.writeJoint(fileID, jointData);
        end
    end
    
    fclose(fileID);
end

