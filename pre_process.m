currentSWD = fileparts(mfilename('fullpath'));
dataUrl = "https://data.mendeley.com/public-files/datasets/btm76zndnt/files/2018b884-181a-482b-8a06-a86bbf41f4e7/file_downloaded";
preProcessor = PreProcessor(currentSWD + "/temp");
proProcessedDataset = preProcessor.preprocess(dataUrl);

eda = EDA('temp\processed_issues.csv');


eda.anovaTestForIssuesCountPerDay();


