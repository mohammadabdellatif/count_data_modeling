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
        end

       function tests = anovaTestForIssuesCountPerDay(obj, yearsBack)
            tests = {};
            lastXYears = obj.issues(obj.issues.year >= max(obj.issues.year) - yearsBack,:);
            [p, tbl, stats] = obj.performAnova(lastXYears,'day_of_week', ["SUN","MON","TUE","WED","THU","FRI","SAT"]);
            tests{end+1} = {'All Days',p, tbl, stats};

            withoutWeekEnds = lastXYears(~ismember(lastXYears.day_of_week,{'FRI','SAT'}) ,:);
            [p, tbl, stats] = obj.performAnova(withoutWeekEnds,'day_of_week', ["SUN","MON","TUE","WED","THU"]);
            tests{end+1} = {'Middle of the Week', p, tbl, stats};

            [p, tbl, stats] = obj.performAnova(lastXYears,'quarter', ["Q1","Q2","Q3","Q4"]);
            tests{end+1} = {'Quarter of the Year', p, tbl, stats};
       end

       function [G, p, tbl, stats] = anova2TestForIssuesCountPerQuarterAndDay(obj, yearsBack)
            lastXYears = obj.issues(obj.issues.year >= max(obj.issues.year) - yearsBack,:);
            G = groupsummary(lastXYears,{'year','quarter','day_of_week'});
            G = G(:,{'quarter','day_of_week','GroupCount'});
            G.quarter = categorical(string(G.quarter));
            G.day_of_week = categorical(G.day_of_week, ["SUN","MON","TUE","WED","THU","FRI","SAT"], 'Ordinal', true);
            [p, tbl, stats] = anovan( ...
                G.GroupCount, ...
                {G.quarter, G.day_of_week}, ...
                'model', 'interaction', ...
                'varnames', {'Quarter','Day Of Week'}, ...
                'display', 'on');  
       end

        function [p, tbl, stats] = performAnova(~, data, groupCol, colKeys)
            grpByYearAndCol = groupsummary(data, {'year', groupCol});
            grpByYearAndCol.(groupCol) = categorical(grpByYearAndCol.(groupCol), colKeys, 'Ordinal', true);
            grpByYearAndCol = sortrows(grpByYearAndCol, groupCol);
            [p, tbl, stats] =anova1(grpByYearAndCol.GroupCount, grpByYearAndCol.(groupCol), 'off');
        end
    end
end