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
            issues = issuesDataSet(:, ["id", "issue_proj", "issue_created"]);

            issues = obj.preProcessCreationDate(issues);
            issues = obj.preProcessProjectCode(issues);
            issues = obj.preProcessDate(issues);
            
            issues = sortrows(issues, "issue_created", "ascend");

            obj.savePreprocessed(issues)
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

        function issues = preProcessProjectCode(~, issues)
            issues.issue_proj = string(issues.issue_proj);
            issues = issues(strlength(issues.issue_proj) > 6, :);
            issues.country = extractBetween(issues.issue_proj, 1, 3);
            issues.product = extractBetween(issues.issue_proj, 4, 5);
            issues.client_id = extractAfter(issues.issue_proj, 5);
        end

        function issues = preProcessCreationDate(~, issues)
            issues.issue_created = extractBetween(issues.issue_created, 1, 19);
            issues.issue_created = datetime(issues.issue_created, ...
                "InputFormat", "yyyy-MM-dd HH:mm:ss");
        end

        function issues = preProcessDate(~, issues)
            issues.year = year(issues.issue_created);
            issues.month = month(issues.issue_created);
            issues.week_of_month = ceil(day(issues.issue_created) / 7);
            issues.week_of_year = week(issues.issue_created);
            issues.quarter = quarter(issues.issue_created);
        end

        function savePreprocessed(obj, issues)
            outputFilename = fullfile(obj.tempDir, "processed_issues.csv");
            writetable(issues, outputFilename);
            fprintf("Processed %n issues and saved to: %s\n", ...
                size(issues), ...
                outputFilename);
        end
    end
end