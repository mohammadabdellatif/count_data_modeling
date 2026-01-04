classdef DailyEDA
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
        function obj = DailyEDA(preProcessedPath)
            arguments
                preProcessedPath {mustBeNonempty, mustBeFile}
            end
            obj.issues = readtable(preProcessedPath);
            % ignore the last year as its data is incomplete
            obj.issues = obj.issues(obj.issues.year < max(obj.issues.year),:);
            obj.issues.day_of_week = categorical( ...
                obj.issues.day_of_week, ...
                {'SUN','MON','TUE','WED','THU','FRI','SAT'}, ...
                'Ordinal', true);
        end

        function plotDailyIssuesBoxPlot(obj)
            G = obj.issues;
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

        function plotHistForYearsBack(obj, yearsBack, isWorkingDay)
            G = obj.issues( ...
                (obj.issues.year >= max(obj.issues.year) - yearsBack) ...
                & (obj.issues.is_working_day == isWorkingDay), :);
           
            figure
            % Update the figure to stretch to fit the two subplots
            set(gcf, 'Position', [100, 100, 1200, 1000]); % Adjust figure size
            
            x = ['Count per Days ', strjoin(string(unique(G.day_of_week)), ', ')];
            years = strjoin(string(unique(G.year)), ', ');
            
            subplot(2, 1, 1); % Create a subplot for histfit
            histfit(G.GroupCount);
            xlabel(x);
            ylabel('Frequencies');
            title(['Daily Issues Frequencies ', years ]);
            
            subplot(2, 1, 2); % Create a subplot for normplot
            normplot(G.GroupCount);
            xlabel(x);
            ylabel('Frequencies');
            title(['Normal Probability Plot', years]);
        end

        function plotBoxPlotForDaysForYearsBack(obj, yearsBack)
            G = obj.issues( ...
                (obj.issues.year >= max(obj.issues.year) - yearsBack), :);
           
            week_Days = {'SUN';'MON';'TUE';'WED';'THU';'FRI';'SAT'};
            
            allCounts = [];
            allGroups = [];
            
            for i = 1:length(week_Days)
                wd = week_Days(i);
                idx = ismember(G.day_of_week,wd);
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
            
            xticks(1:numel(groupLabels));
            xticklabels(week_Days);

            hold off;
            xlabel('Day of Week');
            ylabel('Records per Day of Weel');
            title('Daily Record Count Distribution By Day of Week');
        end

        function plotTrendOfIssuesOverTime(obj, days, workingDayFlag, yearsBack)
            % Count records by year, month, and day_of_month
            dailyCounts = obj.issues( ...
                (obj.issues.year >= max(obj.issues.year) - yearsBack) & ...
                (obj.issues.is_working_day == workingDayFlag) & ...
                (ismember(obj.issues.day_of_week, days)),:);
            
            dailyCounts = sortrows(dailyCounts, {'year', 'month','day_of_month'}); % Order the records
            
            % Create a line plot
            figure;
            hold on
            years = unique(dailyCounts.year);
            zeroRate = mean(dailyCounts.GroupCount == 0);
            
            % Add zeroRate as a text in the top right of the plot
            text('Units', 'normalized', 'Position', [0.95, 0.95], ...
                'String', ['Zero Rate: ', num2str(zeroRate*100, '%.2f'), '%'], ...
                'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
                'FontSize', 8, 'FontWeight', 'bold', 'Color', 'k');
            plot(dailyCounts.GroupCount,'o')
            xlabel('Daily issues trend');
            ylabel('Record Count');
            title(['Issues Trend For: ',  strjoin(days, ', '), ' in Years',strjoin(string(years))]);
            hold off
        end
    end
end