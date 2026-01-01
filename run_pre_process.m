currentSWD = fileparts(mfilename('fullpath'));
dataUrl = "https://data.mendeley.com/public-files/datasets/btm76zndnt/files/2018b884-181a-482b-8a06-a86bbf41f4e7/file_downloaded";
preProcessor = PreProcessor(currentSWD + "/temp");
[preProcesedData, issues] = preProcessor.preprocess(dataUrl,'holidays_2021_2023.csv');

preProcessor.preprocessDailySummary(issues,'holidays_2021_2023.csv');




