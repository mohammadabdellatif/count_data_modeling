classdef PreProcessor

    properties (Access = private)
        tempDir string = "temp";
    end

    methods
        function obj = PreProcessor(tempDir)
            if nargin > 0
                obj.tempDir = tempDir;
            end
            if ~exist(obj.tempDir, "dir")
                mkdir(obj.tempDir);
            end
        end

        function preprocess(obj, datasetUrl)
            issuesDataSet = obj.openDataset(datasetUrl);
            fprintf("dataset downloaded: %d %n", size(issuesDataSet))
            issues = issuesDataSet(:, ["issue_proj", "issue_created"]); % Assuming 'issue_created' is in the second column
            issues.issue_created = datetime(issues.issue_created, ...
                "InputFormat", "yyyy-MM-dd HH:mm:ssXXX", ...
                "TimeZone", "UTC");
            
            issues = issues(char(strlength(issues.issue_proj) > 6), :);
        end
    end

    methods (Access = private)
        function issuesDataset = openDataset(obj, datasetUrl)
            arguments
                obj 
                datasetUrl string {mustBeNonzeroLengthText}
            end
           
            % Download the dataset from the provided URL
            filename = fullfile(obj.tempDir , "issues.csv"); % Specify the filename to save the dataset
            if(~exist(filename, "file"))
                fprintf("download data from %s and save it to %s", datasetUrl, filename)
                websave(filename, datasetUrl); % Download the file
            end
           
            issuesDataset = readtable(filename);
        end
    end
end