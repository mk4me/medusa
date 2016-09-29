classdef csvCreator
    methods(Static)
        function writeHeader(fileID, name, count)
            fprintf(fileID,'%s, %d', name, count);
        end

        function writeData(fileID, name, data)
            csvCreator.writeHeader(fileID, name ,length(data) / 2);
            fprintf(fileID,', %d', data);
            fprintf(fileID,'\n');
        end

        function writeFileHeader(fileID, filename, annotationsCount)
            csvCreator.writeHeader(fileID, filename, annotationsCount);
            fprintf(fileID,'\n');
        end

        function writeSynovitis( fileID, synovitisData )
            csvCreator.writeData(fileID,'region inflammatory synovitis degree of inflammation / hyperplasia',synovitisData);
        end

        function [count] = getNumberOfBones(boneData)
            indices = split(boneData);
            count = size(indices,1);
        end
        function writeBone(fileID, boneData)
            indices = split(boneData);
            for x = 1 : size(indices,1);
                startI = indices(x, 1);
                endI = indices(x, 2);
                csvCreator.writeData(fileID,'bone',indexizePart(boneData, startI, endI));
            end
        end

        function writeSkin(fileID, skinData)
            si = drop_zeros_than_indexize(skinData);
            csvCreator.writeData(fileID,'skin',si);
        end

        function writeJoint(fileID, jointData)
            csvCreator.writeData(fileID,'joint',jointData);
        end
    end
end

function [newArray] = drop_zeros_than_indexize(oldArray)
    start = 1;
    finish = length(oldArray);
    for i=1:finish
        if oldArray(i) > 0
            start = i;
            break
        end
    end
    newArray = indexizePart(oldArray, start, finish);
end

function [indicesMat] = split(oldArray)
    edgeArray = diff([0; (oldArray(:) ~= 0); 0]);
    indicesMat = [find(edgeArray > 0) find(edgeArray < 0)-1];
end

function [newArray] = indexize(oldArray)
    newArray = indexizePart(oldArray, 1, length(oldArray));
end

function [newArray] = indexizePart(oldArray, startI, endI)
    newArray = zeros(2*(endI-startI):1);
    for x = startI: endI
        newArray(2*(x-startI) + 1) = x - 1;
        newArray(2*(x-startI) + 2) = oldArray(x);
    end
end