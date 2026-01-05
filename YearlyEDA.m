classdef YearlyEDA
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
        function obj = YearlyEDA(preProcessedPath)
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

        function groupByField = groupByYearAndField(obj, fieldName) 
            groupByField = groupsummary(unique(obj.issues(:, ...
                 {'year', fieldName})), ...
                'year', ...
                'IncludeEmptyGroups', false);
        end

        function plotGroupedByYearAndField(obj, fieldName)            
            label = YearlyEDA.labels(fieldName);
            issuesCount = obj.groupByYearAndField(fieldName);
            figure('Name', label + " Count by Year", 'NumberTitle', 'off');
            plot(1:length(issuesCount.year), issuesCount.GroupCount, '-o', 'LineWidth', 1, 'MarkerSize', 4);
            hold on; % Keep the current plot

            padded = ylim; % Get current y-axis limits
            if max(issuesCount.GroupCount) == padded(2)
                ylim([padded(1), padded(2) + range(padded) * 0.1]); % Add 10% extra space to the top
            end
            
            hold off; % Release the plot hold

            xticks(issuesCount.year);
            xticks(1:height(issuesCount));
            xticklabels(issuesCount.year);
            xlabel('Year');
            ylabel(['Count of ', label]);
            % title(['Count of ', label, ' by Year']);
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

        function countryStatistics(obj)
            disp(['Total number of countries: ', int2str(height(unique(obj.issues.country)))])
        end

        function productsStatistics(obj)
            disp(['Total number of products: ', int2str(height(unique(obj.issues.product)))])
        end

        function clientStatistics(obj)
            disp(['Total number of clients: ', int2str(height(unique(obj.issues.client_id)))])
        end

        function ratios = scatterPlotTwoFieldsByYear(obj, field1, field2)
            field1ByYear = obj.groupByYearAndField(field1);
            field2ByYear = obj.groupByYearAndField(field2);
            ratios = field1ByYear.GroupCount ./ field2ByYear.GroupCount;
            label1 = YearlyEDA.labels(field1);
            label2 = YearlyEDA.labels(field2);
            combinedCounts = join(field1ByYear, field2ByYear, 'Keys', 'year');
            figure('Name', [label1, ' Count by ', label2, ' Count'], 'NumberTitle', 'off');
            scatter(combinedCounts, 'GroupCount_field1ByYear', 'GroupCount_field2ByYear')
            % hold on;

            %  % Add linear fitting line
            % p = polyfit(combinedCounts.GroupCount_field1ByYear, ...
            %     combinedCounts.GroupCount_field2ByYear, 1); % Linear fit
            % yfit = polyval(p, combinedCounts.GroupCount_field1ByYear); % Evaluate the fit
            % plot(combinedCounts.GroupCount_field1ByYear, yfit, '--r', 'LineWidth', 1); % Plot the fit line
            % 
            % % Calculate R-squared value
            % residuals = combinedCounts.GroupCount_field2ByYear - yfit; % Calculate residuals
            % ssRes = sum(residuals.^2); % Residual sum of squares
            % ssTot = sum((combinedCounts.GroupCount_field2ByYear - mean(combinedCounts.GroupCount_field2ByYear)).^2); % Total sum of squares
            % rSquared = 1 - (ssRes / ssTot); % R-squared calculation
            % % Add R-squared value to the plot
            % 
            % text(combinedCounts.GroupCount_field1ByYear(2), max(combinedCounts.GroupCount_field2ByYear) * 0.9, ...
            %     sprintf('R^2 = %.2f', rSquared), ...
            %     'FontSize', 12, ...
            %     'Color', 'k', ...
            %     'HorizontalAlignment', 'center', ...
            %     'BackgroundColor', 'w');
            % 
            % hold off; % Release the plot hold

            xlabel([label1,' Count']);
            ylabel([label2, ' Count']);
            % title([label1, ' count by ', label2, ' Count']);
            grid on;
        end

        function plotIssuesCountByProductsCount(obj)
            obj.scatterPlotTwoFieldsByYear('product', 'id');
        end

        function plotIssuesCountByCountriesCount(obj)
            obj.scatterPlotTwoFieldsByYear('country','id');
        end

        function plotIssuesCountByClientCount(obj)
            obj.scatterPlotTwoFieldsByYear('client_id','id');
        end

        
    end
end