To process input files you to execute following steps:
1. Copy input data (png files) to ./input directory
2. run bash command ./runmodule.sh [params]
3. Output files (after processing will be copied to _output directory)

NOTE:
Within step 2 you can define some additional parametrs like postfix of input and output file names, eg:
./runmodule.sh "inPostfix=-syn.png;outPostfix=-res.png"
above command will cause generate appropriate *-res.png for *-syn.png e.g.: 
2013-08-21-S0001-T0009-syn.png  ->  2013-08-21-S0001-T0009-res.png


