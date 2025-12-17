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
            plot(issuesCount.year, issuesCount.GroupCount, '-o', 'LineWidth', 1, 'MarkerSize', 4);
            hold on; % Keep the current plot

            padded = ylim; % Get current y-axis limits
            if max(issuesCount.GroupCount) == padded(2)
                ylim([padded(1), padded(2) + range(padded) * 0.1]); % Add 10% extra space to the top
            end
            
            % Add linear fitting line
            p = polyfit(issuesCount.year, issuesCount.GroupCount, 1); % Linear fit
            yfit = polyval(p, issuesCount.year); % Evaluate the fit
            plot(issuesCount.year, yfit, '--r', 'LineWidth', 1); % Plot the fit line
            
            % Calculate R-squared value
            residuals = issuesCount.GroupCount - yfit; % Calculate residuals
            ssRes = sum(residuals.^2); % Residual sum of squares
            ssTot = sum((issuesCount.GroupCount - mean(issuesCount.GroupCount)).^2); % Total sum of squares
            rSquared = 1 - (ssRes / ssTot); % R-squared calculation
            % Add R-squared value to the plot
            
            text(issuesCount.year(2), max(issuesCount.GroupCount) * 0.9, ...
                sprintf('R^2 = %.2f', rSquared), ...
                'FontSize', 12, ...
                'Color', 'k', ...
                'HorizontalAlignment', 'center', ...
                'BackgroundColor', 'w');

            hold off; % Release the plot hold

            xticks(issuesCount.year);
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
            hold on;

             % Add linear fitting line
            p = polyfit(combinedCounts.GroupCount_field1ByYear, ...
                combinedCounts.GroupCount_field2ByYear, 1); % Linear fit
            yfit = polyval(p, combinedCounts.GroupCount_field1ByYear); % Evaluate the fit
            plot(combinedCounts.GroupCount_field1ByYear, yfit, '--r', 'LineWidth', 1); % Plot the fit line
            
            % Calculate R-squared value
            residuals = combinedCounts.GroupCount_field2ByYear - yfit; % Calculate residuals
            ssRes = sum(residuals.^2); % Residual sum of squares
            ssTot = sum((combinedCounts.GroupCount_field2ByYear - mean(combinedCounts.GroupCount_field2ByYear)).^2); % Total sum of squares
            rSquared = 1 - (ssRes / ssTot); % R-squared calculation
            % Add R-squared value to the plot
            
            text(combinedCounts.GroupCount_field1ByYear(2), max(combinedCounts.GroupCount_field2ByYear) * 0.9, ...
                sprintf('R^2 = %.2f', rSquared), ...
                'FontSize', 12, ...
                'Color', 'k', ...
                'HorizontalAlignment', 'center', ...
                'BackgroundColor', 'w');

            hold off; % Release the plot hold

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
            plot(1:numel(groupLabels), meanVals, 'rx', 'MarkerFaceColor','r', 'MarkerSize',6);
            
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
                (obj.issues.year ~= max(obj.issues.year)) &...
                (~ismember(obj.issues.day_of_week, {'FRI', 'SAT'})), :);
            G = groupsummary(lastTwoYears, ...
                {'year', 'month', 'day_of_month'});
            figure
            % Update the figure to stretch to fit the two subplots
            set(gcf, 'Position', [100, 100, 1200, 1000]); % Adjust figure size
            
            subplot(2, 1, 1); % Create a subplot for histfit
            histfit(G.GroupCount, 17);
            xlabel('Count per Day');
            ylabel('Frequencies');
            title('Daily Issues Frequencies');
            
            subplot(2, 1, 2); % Create a subplot for normplot
            normplot(G.GroupCount);
            xlabel('Count per Day');
            ylabel('Frequencies');
            title('Normal Probability Plot');
           
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
            plot(1:numel(groupLabels), meanVals, 'rx', 'MarkerFaceColor','r', 'MarkerSize',6);
            
            % set x ticks to be the actual year labels if needed
            xticks(1:numel(groupLabels));
            xticklabels(string(years));

            hold off;
            xlabel('Day of Week');
            ylabel('Records per Day of Weel');
            title('Daily Record Count Distribution By Day of Week')
        end

        function tests = anovaTestForIssuesCountPerDay(obj)
            tests = {};
            lastTwoYears = obj.issues(obj.issues.year >= max(obj.issues.year) - 2,:);
            [p, tbl, stats] = obj.performAnova(lastTwoYears,'day_of_week', ["SUN","MON","TUE","WED","THU","FRI","SAT"]);
            tests{end+1} = {'All Days',p, tbl, stats};

            withoutWeekEnds = lastTwoYears(~ismember(lastTwoYears.day_of_week,{'FRI','SAT'}) ,:);
            [p, tbl, stats] = obj.performAnova(withoutWeekEnds,'day_of_week', ["SUN","MON","TUE","WED","THU"]);
            tests{end+1} = {'Middle of the Week', p, tbl, stats};

            [p, tbl, stats] = obj.performAnova(lastTwoYears,'quarter', [1,2,3,4]);
            tests{end+1} = {'Quarter of the Year', p, tbl, stats};
        end

        function [p, tbl, stats] = performAnova(~, data, groupCol, colKeys)
            grpByYearAndCol = groupsummary(data, {'year', groupCol});
            grpByYearAndCol.(groupCol) = categorical(grpByYearAndCol.(groupCol), colKeys, 'Ordinal', true);
            grpByYearAndCol = sortrows(grpByYearAndCol, groupCol);
            [p, tbl, stats] =anova1(grpByYearAndCol.GroupCount, grpByYearAndCol.(groupCol), 'off');
        end
    end
end