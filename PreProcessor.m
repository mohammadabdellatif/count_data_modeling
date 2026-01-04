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

        function [preProcesedData, issues] = preprocess(obj, datasetUrl, holidays_ds)
            issuesDataSet = obj.openDataset(datasetUrl);
            fprintf("dataset downloaded: %d %n", size(issuesDataSet))
            
            holidaysDataSet = readtable(holidays_ds);
            holidaysDataSet.Date = datetime(holidaysDataSet.Date, "InputFormat", "yyyy-MM-dd");

            issues = issuesDataSet(:, ["id", "issue_proj", "issue_created"]);

            issues = obj.preProcessCreationDate(issues);
            issues = obj.preProcessProjectCode(issues);
            issues = obj.preProcessDate(issues);
            
            issues = sortrows(issues, "issue_created", "ascend");
            issues.is_working_day = ~ismember(issues.day_of_week, ["FRI", "SAT"]);
            issueDates = datetime(issues.year, issues.month, issues.day_of_month);
            holidays = holidaysDataSet.Date;
            issues.is_working_day(ismember(issueDates, holidays)) = false;
            % issues = issues(issues.year < 2023, :);

            preProcesedData = obj.savePreprocessed(issues);
        end

        function dailySummaryOutput = preprocessDailySummary(obj, issues, holidays_ds)
            dailySummary = groupsummary(issues, ...
                {'year', 'month','day_of_month','day_of_week'});
            dailySummary = sortrows(dailySummary, ...
                {'year', 'month','day_of_month'});
            years = unique(dailySummary.year);
            holidaysDataSet = readtable(holidays_ds);
            holidaysDataSet.Date = datetime(holidaysDataSet.Date, "InputFormat", "yyyy-MM-dd");

            for i=1:length(years)
                year = years(i);
                for month = 1:12
                    for date = 1:eomday(year, month)
                        if ~any(dailySummary.year == year & ...
                                dailySummary.month == month & ...
                                dailySummary.day_of_month == date)
                            % Calculate the weekday for the given year, month, and day
                            dt = datetime(year, month, date);
                            weekDay = upper(day(dt, 'shortname'));
                            newRecord = table(year, month, date, weekDay, 0, ...
                                'VariableNames', {'year', 'month', 'day_of_month', 'day_of_week', 'GroupCount'});
                            dailySummary = [dailySummary; newRecord]; % Append the new record
                        end
                    end
                end
            end
            dailySummary = sortrows(dailySummary, {'year', 'month', 'day_of_month'});
            dailySummary.dayOfYear = ones(size(dailySummary));
            dailySummary.is_working_day = ~ismember(dailySummary.day_of_week, {'FRI','SAT'});
            issueDates = datetime(dailySummary.year, dailySummary.month, dailySummary.day_of_month);
            dailySummary.dayOfYear = day(issueDates,"dayofyear");
            dailySummary.is_working_day(ismember(issueDates, holidaysDataSet.Date)) = false;
            dailySummaryOutput = obj.saveDailySummary(dailySummary);
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
            % Extract without the timezone
            issues.issue_created = extractBetween(issues.issue_created, 1, 19);
            issues.issue_created = datetime(issues.issue_created, ...
                "InputFormat", "yyyy-MM-dd HH:mm:ss");
        end

        function issues = preProcessDate(~, issues)
            issues.year = year(issues.issue_created);
            issues.month = month(issues.issue_created);
            issues.day_of_month = day(issues.issue_created);
            issues.day_of_week = upper(day(issues.issue_created, 'shortname'));
            issues.week_of_month = ceil(day(issues.issue_created) / 7);
            issues.week_of_year = week(issues.issue_created);
            issues.quarter = quarter(issues.issue_created);
            issues.quarter = strcat("Q", string(issues.quarter));
        end

        function outputFilename = savePreprocessed(obj, issues)
            outputFilename = obj.saveDataset(issues, "processed_issues.csv");
        end

        function outputFilename = saveDailySummary(obj, dailySummary)
            outputFilename = obj.saveDataset(dailySummary, "daily_summary.csv");
        end

        function outputFilename = saveDataset(obj, issues, fileName)
            outputFilename = fullfile(obj.tempDir, fileName);
            writetable(issues, outputFilename);
            fprintf("Processed %n records and saved to: %s\n", ...
                size(issues), ...
                outputFilename);
        end
    end
end