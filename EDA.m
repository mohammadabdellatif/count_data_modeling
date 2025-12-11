classdef EDA
    %EDA Summary of this class goes here
    %   Detailed explanation goes here

    
    properties (Access = private)
        issues table
    end
    properties (Access = private, Constant)
        labels containers.Map = containers.Map( ...
            {'id', 'country', 'product', 'client_id'}, ...
            {'Issues', 'Country', 'Product', 'Clients'});
    end

    methods
        function obj = EDA(preProcessedPath)
            arguments
                preProcessedPath {mustBeNonempty, mustBeFile}
            end
            obj.issues = readtable(preProcessedPath);
        end

        function groupByField = groupByYearAndField(obj, fieldName) 
            groupByField = groupsummary(unique(obj.issues(:, ...
                 {'year', fieldName})), ...
                'year', ...
                'IncludeEmptyGroups', true);
        end

        function plotGroupedByYearAndField(obj, fieldName)            
            label = EDA.labels(fieldName);
            issuesCount = obj.groupByYearAndField(fieldName);
            figure('Name', label + " Count by Year", 'NumberTitle', 'off');
            bar(issuesCount.GroupCount);
            xticks(1:length(issuesCount.year));
            xticklabels(issuesCount.year);
            xlabel('Year');
            ylabel(['Count of ', label]);
            title(['Count of ', label, ' by Year']);
            grid on;
        end

        function plotIssuesCountByYear(obj)
            obj.plotGroupedByYearAndField('id')
        end

        function plotCountWithCountryByYear(obj) 
            obj.plotGroupedByYearAndField('country')
        end

        function plotCountWithProductByYear(obj) 
            obj.plotGroupedByYearAndField('product');
        end

        function scatterPlotTwoFieldsByYear(obj, field1, field2)
            field1ByYear = obj.groupByYearAndField(field1);
            field2ByYear = obj.groupByYearAndField(field2);
            label1 = EDA.labels(field1);
            label2 = EDA.labels(field2);
            combinedCounts = join(field1ByYear, field2ByYear, 'Keys', 'year');
            figure('Name', [label1, ' Count by ', label2, ' Count'], 'NumberTitle', 'off');
            scatter(combinedCounts, 'GroupCount_field1ByYear', 'GroupCount_field2ByYear')
            
            xlabel([label1,' Count']);
            ylabel([label2, ' Count']);
            title([label1, ' count by ', label2, ' Count']);
            grid on;
        end

        function plotIssuesCountByProductsCount(obj)
            obj.scatterPlotTwoFieldsByYear('id','product');
        end

        function plotIssuesCountByCountriesCount(obj)
            obj.scatterPlotTwoFieldsByYear('id','country');
        end

        function plotIssuesCountByClientCount(obj)
            obj.scatterPlotTwoFieldsByYear('id','client_id');
        end

        function stats = dailyStatisticalSummary(obj)
            dailySummary = groupsummary(obj.issues, ...
                {'year', 'month', 'day_of_month'});
            
            stats = struct();
            stats.min = min(dailySummary.GroupCount);
            stats.max = max(dailySummary.GroupCount);
            stats.std = std(dailySummary.GroupCount);
            stats.variance = var(dailySummary.GroupCount);
            stats.mean = mean(dailySummary.GroupCount);
        end

        function plotDailyIssuesBoxPlot(obj)
            G = groupsummary(obj.issues, ...
                {'year', 'month', 'day_of_month'});
            years = unique(G.year);
            allCounts = [];
            allGroups = [];
            
            for i = 1:length(years)
                yr = years(i);
                idx = (G.year == yr);
                counts = G.GroupCount(idx);
                
                allCounts  = [allCounts; counts];
                allGroups  = [allGroups; repmat(i, length(counts), 1)];
            end
            figure;
            boxchart(allGroups, allCounts);   % plots one box per unique group
            hold on;
            % compute mean per unique group label
            [groupLabels, ~, subs] = unique(allGroups, 'stable'); % labels in plotted order
            meanVals = accumarray(subs, allCounts, [], @mean);
            
            % plot means as red circles
            plot(1:numel(groupLabels), meanVals, 'ro', 'MarkerFaceColor','r', 'MarkerSize',6);
            
            % set x ticks to be the actual year labels if needed
            xticks(1:numel(groupLabels));
            xticklabels(string(years));

            hold off;
            xlabel('Year');
            ylabel('Records per Day');
            title('Daily Record Count Distribution By Year')
        end

        function plotHistForLastTwoYears(obj)
            lastTwoYears = obj.issues( ...
                (obj.issues.year >= max(obj.issues.year) - 2) & ...
                (~ismember(obj.issues.day_of_week, {'FRI', 'SAT'})), :);
            G = groupsummary(lastTwoYears, ...
                {'year', 'month', 'day_of_month'});
            figure
            histcounts(G.GroupCount)
            hold on;
            histfit(G.GroupCount)
            hold off;
            xlabel('Count per Day')
            ylabel('Frequencies')
            title('Daily Issues Frequencies')
        end

        function plotBoxPlotForDaysForLastThreeYears(obj)
            G = obj.issues( ...
                (obj.issues.year >= max(obj.issues.year) - 2), :);
            G = groupsummary(obj.issues, ...
                {'year', 'week_of_year', 'day_of_week'});
            years = {'SUN';'MON';'TUE';'WED';'THU';'FRI';'SAT'};
            
            allCounts = [];
            allGroups = [];
            
            for i = 1:length(years)
                yr = years(i);
                idx = ismember(G.day_of_week,yr);
                counts = G.GroupCount(idx);
                
                allCounts  = [allCounts; counts];
                allGroups  = [allGroups; repmat(i, length(counts), 1)];
            end
            figure;
            boxchart(allGroups, allCounts);   % plots one box per unique group
            hold on;
            % compute mean per unique group label
            [groupLabels, ~, subs] = unique(allGroups, 'stable'); % labels in plotted order
            meanVals = accumarray(subs, allCounts, [], @mean);
            
            % plot means as red circles
            plot(1:numel(groupLabels), meanVals, 'ro', 'MarkerFaceColor','r', 'MarkerSize',6);
            
            % set x ticks to be the actual year labels if needed
            xticks(1:numel(groupLabels));
            xticklabels(string(years));

            hold off;
            xlabel('Day of Week');
            ylabel('Records per Day of Weel');
            title('Daily Record Count Distribution By Day of Week')
        end

    end
end