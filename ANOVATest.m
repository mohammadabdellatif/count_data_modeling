classdef ANOVATest

     properties (Access = private)
        issues table
    end

    methods
        function obj = ANOVATest(preProcessedPath)
            arguments
                preProcessedPath {mustBeNonempty, mustBeFile}
            end
            obj.issues = readtable(preProcessedPath);
            obj.issues = obj.issues(obj.issues.year < max(obj.issues.year), : );
            disp(min(obj.issues.year))
            disp(max(obj.issues.year))
        end

       function tests = anovaTestForIssuesCountPerDay(obj, yearsBack)
            tests = {};
            startYear = max(obj.issues.year) - yearsBack;
            disp(startYear)
            lastXYears = obj.issues(obj.issues.year >= startYear,:);
            [p, tbl, stats] = obj.performAnova(lastXYears, 'day_of_week', ["SUN","MON","TUE","WED","THU","FRI","SAT"]);
            tests{end+1} = {strcat('All Days after ', int2str(startYear)),p, tbl, stats};

            withoutWeekEnds = lastXYears(~ismember(lastXYears.day_of_week,{'FRI','SAT'}) ,:);
            [p, tbl, stats] = obj.performAnova(withoutWeekEnds, 'day_of_week', ["SUN","MON","TUE","WED","THU"]);
            tests{end+1} = {'Middle of the Week', p, tbl, stats};

            [p, tbl, stats] = obj.performAnova(lastXYears,'quarter', ["Q1","Q2","Q3","Q4"]);
            tests{end+1} = {'Quarter of the Year', p, tbl, stats};
       end

       function [p, tbl, stats] = performAnova(~, data, groupCol, colKeys)
            grpByYearAndCol = groupsummary(data, {'year', 'month', 'day_of_month', groupCol});
            grpByYearAndCol = grpByYearAndCol(:,{groupCol,'GroupCount'});
            grpByYearAndCol.(groupCol) = categorical(grpByYearAndCol.(groupCol), colKeys, 'Ordinal', true);
            grpByYearAndCol = sortrows(grpByYearAndCol, groupCol);
            [p, tbl, stats] =anova1(grpByYearAndCol.GroupCount, grpByYearAndCol.(groupCol), 'off');
       end

       function [G, p, tbl, stats] = anova2TestForIssuesCountPerQuarterAndDay(obj, yearsBack)
            lastXYears = obj.issues(obj.issues.year >= max(obj.issues.year) - yearsBack,:);
            G = groupsummary(lastXYears,{'year','month','day_of_month','day_of_week','quarter'});
            G = G(:,{'quarter','day_of_week','GroupCount'});
            G.quarter = categorical(string(G.quarter));
            G.day_of_week = categorical(G.day_of_week, ...
                ["SUN","MON","TUE","WED","THU","FRI","SAT"], ...
                'Ordinal', true);
            [p, tbl, stats] = anovan( ...
                G.GroupCount, ...
                {G.quarter, G.day_of_week}, ...
                'model', 'interaction', ...
                'varnames', {'Quarter','Day Of Week'}, ...
                'display', 'on');  
       end
    end
end