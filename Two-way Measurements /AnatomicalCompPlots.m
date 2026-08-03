% %==========================================================================
% % CONFIGURATION
% %==========================================================================
% excelFile = 'CT_ImageData_Reorganised.xlsx';
% sheetName = '4matlab';
% 
% %==========================================================================
% % READ DATA
% %==========================================================================
% opts = detectImportOptions(excelFile, 'Sheet', sheetName);
% T = readtable(excelFile, opts);
% T.Properties.VariableNames = matlab.lang.makeValidName(T.Properties.VariableNames);
% varNames = T.Properties.VariableNames;
% T = renamevars(T, varNames, {'SampleID','Sex','Weight','SkullThickness','SDR','PctTransLoss','MEAN','STDDEV','CV%TransLoss'});
% T = T(~isnan(T.PctTransLoss), :);
% 
% isRat   = startsWith(T.SampleID, 'R_');
% isMouse = ~isRat;
% 
% % Explicit 3-way group label: Male Rat / Female Rat / Male Mouse
% Group = strings(height(T),1);
% Group(isRat   & strcmpi(T.Sex,'Male'))   = "Male Rat";
% Group(isRat   & strcmpi(T.Sex,'Female')) = "Female Rat";
% Group(isMouse & strcmpi(T.Sex,'Male'))   = "Male Mouse";
% Group(isMouse & strcmpi(T.Sex,'Female')) = "Female Mouse";  % in case any exist
% T.Group = Group;
% 
% %==========================================================================
% % HELPER: stddev of %TransLoss per group
% %==========================================================================
% function sd = groupStd(tbl, groupName)
%     sd = std(tbl.PctTransLoss(tbl.Group == groupName), 'omitnan');
% end
% 
% %==========================================================================
% % PLOT 1: %TransLoss vs Weight — 3 explicit groups
% %==========================================================================
% % NOW SEE END
% 
% % groupNames  = ["Male Rat", "Female Rat", "Male Mouse"];
% % markerStyle = {'o', 's', '^'};
% % colours     = {[0.20 0.45 0.85], [0.85 0.30 0.30], [0.10 0.65 0.35]};
% % 
% % figure('Color','w','Position',[100 100 750 550]);
% % hold on
% % for k = 1:numel(groupNames)
% %     gName = groupNames(k);
% %     mask  = T.Group == gName;
% %     if ~any(mask), continue; end
% %     sd = groupStd(T, gName);
% %     errorbar(T.Weight(mask), T.PctTransLoss(mask), sd*ones(sum(mask),1), ...
% %         markerStyle{k}, 'MarkerSize', 8, 'MarkerFaceColor', colours{k}, ...
% %         'MarkerEdgeColor', 'k', 'Color', colours{k}, ...
% %         'LineWidth', 1.3, 'CapSize', 6, 'DisplayName', gName);
% % end
% % hold off
% % xlabel('Animal Weight (g)', 'FontSize', 12, 'FontWeight', 'bold')
% % ylabel('% Transmission Loss', 'FontSize', 12, 'FontWeight', 'bold')
% % title('%Transmission Loss vs Animal Weight (All Specimens)', 'FontSize', 13, 'FontWeight', 'bold')
% % legend('Location', 'best', 'FontSize', 11)
% % grid on; box on
% % set(gca, 'FontSize', 11, 'LineWidth', 1)
% 
% %==========================================================================
% % PLOT HELPER: scatter + error bars + linear trendline with R^2, per sex
% %==========================================================================
% function plotWithTrendline(tbl, xVar, xlabelStr, titleStr)
%     isMale   = strcmpi(tbl.Sex, 'Male');
%     isFemale = strcmpi(tbl.Sex, 'Female');
%     sdMale   = std(tbl.PctTransLoss(isMale),   'omitnan');
%     sdFemale = std(tbl.PctTransLoss(isFemale), 'omitnan');
%     hold on
% 
%     % --- Male: points + error bars ---
%     xM = tbl.(xVar)(isMale); yM = tbl.PctTransLoss(isMale);
%     errorbar(xM, yM, sdMale*ones(numel(xM),1), 'o', 'MarkerSize', 8, ...
%         'MarkerFaceColor', [0.20 0.45 0.85], 'MarkerEdgeColor', 'k', ...
%         'Color', [0.20 0.45 0.85], 'LineWidth', 1.3, 'CapSize', 6, ...
%         'DisplayName', 'Male Rat')
% 
%     % --- Female: points + error bars ---
%     xF = tbl.(xVar)(isFemale); yF = tbl.PctTransLoss(isFemale);
%     errorbar(xF, yF, sdFemale*ones(numel(xF),1), 's', 'MarkerSize', 8, ...
%         'MarkerFaceColor', [0.85 0.30 0.30], 'MarkerEdgeColor', 'k', ...
%         'Color', [0.85 0.30 0.30], 'LineWidth', 1.3, 'CapSize', 6, ...
%         'DisplayName', 'Female Rat')
% 
%     % --- Male trendline + R^2 ---
%         % --- Male trendline + p-value ---
%     if numel(xM) >= 2
%         mdlM = fitlm(xM, yM);
%         pM_coef = mdlM.Coefficients.Estimate;
%         xFitM = linspace(min(xM), max(xM), 100);
%         yFitM = pM_coef(1) + pM_coef(2)*xFitM;
%         plot(xFitM, yFitM, '--', 'Color', [0.20 0.45 0.85], 'LineWidth', 1.8, ...
%             'HandleVisibility', 'off')
%         pValM = mdlM.Coefficients.pValue(2);   % p-value for slope
%         text(xFitM(end), yFitM(end), sprintf('  p = %.3f', pValM), ...
%             'Color', [0.20 0.45 0.85], 'FontWeight', 'bold', 'FontSize', 10)
%     end
% 
%     % --- Female trendline + R^2 ---
%         % --- Female trendline + p-value ---
%     if numel(xF) >= 2
%         mdlF = fitlm(xF, yF);
%         pF_coef = mdlF.Coefficients.Estimate;
%         xFitF = linspace(min(xF), max(xF), 100);
%         yFitF = pF_coef(1) + pF_coef(2)*xFitF;
%         plot(xFitF, yFitF, '--', 'Color', [0.85 0.30 0.30], 'LineWidth', 1.8, ...
%             'HandleVisibility', 'off')
%         pValF = mdlF.Coefficients.pValue(2);   % p-value for slope
%         text(xFitF(end), yFitF(end), sprintf('  p = %.3f', pValF), ...
%             'Color', [0.85 0.30 0.30], 'FontWeight', 'bold', 'FontSize', 10)
%     end
% 
%     hold off
%     xlabel(xlabelStr, 'FontSize', 12, 'FontWeight', 'bold')
%     ylabel('% Transmission Loss', 'FontSize', 12, 'FontWeight', 'bold')
%     title(titleStr, 'FontSize', 13, 'FontWeight', 'bold')
%     legend('Location', 'best', 'FontSize', 11)
%     grid on; box on
%     set(gca, 'FontSize', 11, 'LineWidth', 1)
% end
% 
% %==========================================================================
% % PLOT 2: %TransLoss vs Avg Skull Thickness — RATS ONLY, with trendlines
% %==========================================================================
% figure('Color','w','Position',[100 100 750 550]);
% Trat = T(isRat & ~isnan(T.SkullThickness), :);
% plotWithTrendline(Trat, 'SkullThickness', ...
%     'Avg Skull Thickness (mm)', '%Transmission Loss vs Skull Thickness (Rats)')
% 
% %==========================================================================
% % PLOT 3: %TransLoss vs SDR — RATS ONLY, with trendlines
% %==========================================================================
% figure('Color','w','Position',[100 100 750 550]);
% Tsdr = T(isRat & ~isnan(T.SDR), :);
% plotWithTrendline(Tsdr, 'SDR', ...
%     'Skull Density Ratio (SDR)', '%Transmission Loss vs SDR (Rats)')
% 
% 
% %==========================================================================
% % STATS !: variation in trans loss 
% %==========================================================================
% % ruskalwallis(y, group) ranks all values across groups and computes the H-statistic and p-value in one call — equivalent to the entire manual Excel process of ranking, summing, and comparing to the chi-square distribution.
% % multcompare(stats, 'CType', 'bonferroni') runs all pairwise post-hoc comparisons and applies the Bonferroni correction automatically, returning confidence intervals and adjusted p-values in a clean table.
% % ranksum(x1, x2) is MATLAB's direct implementation of the Mann-Whitney U test, giving you the p-value without manually computing U statistics or z-scores.
% %% Kruskal-Wallis test across Male Rat / Female Rat / Male Mouse
% [pKW, tblKW, statsKW] = kruskalwallis(T.PctTransLoss, T.Group, 'off');
% fprintf('Kruskal-Wallis p-value: %.4f\n', pKW);
% 
% %% Post-hoc pairwise comparisons with Bonferroni correction (only if pKW < 0.05)
% if pKW < 0.05
%     c = multcompare(statsKW, 'CType', 'bonferroni', 'Display', 'off');
%     pairwiseResults = array2table(c, 'VariableNames', ...
%         {'Group1','Group2','LowerCI','MeanDiff','UpperCI','pValue'});
%     disp(pairwiseResults)
% end
% 
% %% Alternative: manual pairwise Mann-Whitney U (ranksum) with Bonferroni
% groups = unique(T.Group);
% nComparisons = nchoosek(numel(groups), 2);
% alphaCorrected = 0.05 / nComparisons;
% 
% fprintf('\nBonferroni-corrected alpha threshold: %.4f\n', alphaCorrected);
% for i = 1:numel(groups)-1
%     for j = i+1:numel(groups)
%         g1 = groups(i); g2 = groups(j);
%         x1 = T.PctTransLoss(T.Group == g1);
%         x2 = T.PctTransLoss(T.Group == g2);
%         [p, h] = ranksum(x1, x2);
%         sig = "";
%         if p < alphaCorrected, sig = "*significant*"; end
%         fprintf('%s vs %s: p = %.4f %s\n', g1, g2, p, sig)
%     end
% end
% 
% 
% %==========================================================================
% % ONE-SAMPLE T-TEST: Is %Transmission Loss significantly different from 0?
% % H0: mean(%TransLoss) = 0  (i.e., no real effect, just noise)
% % H1: mean(%TransLoss) ≠ 0  (i.e., a genuine transmission loss effect exists)
% %==========================================================================
% % Null hypothesis: mean %TransLoss = 0 for each group (Male Rat, Female Rat, Male Mouse) — if you can't reject this, the observed "loss" is statistically indistinguishable from random noise around zero.
% % t-statistic and p-value: ttest() returns both directly; a p-value below 0.05 means the group's mean transmission loss is significantly different from zero, supporting a real physical effect rather than measurement noise.
% % 95% confidence interval: shows the plausible range for the true mean %TransLoss — if this interval doesn't cross zero, that's further confirmation the effect is real.
% % Cohen's d: added as an effect size measure (mean divided by SD) since p-values alone don't tell you how large or meaningful the effect is, especially important given your small n=5-6 per group
% groups = unique(T.Group);
% nGroups = numel(groups);
% 
% GroupName   = strings(nGroups,1);
% N           = zeros(nGroups,1);
% MeanTL      = zeros(nGroups,1);
% SD_TL       = zeros(nGroups,1);
% tStat       = zeros(nGroups,1);
% df          = zeros(nGroups,1);
% pValue      = zeros(nGroups,1);
% CI_Lower    = zeros(nGroups,1);
% CI_Upper    = zeros(nGroups,1);
% CohensD     = zeros(nGroups,1);
% Significant = strings(nGroups,1);
% 
% for i = 1:nGroups
%     g = groups(i);
%     vals = T.PctTransLoss(T.Group == g);
%     vals = vals(~isnan(vals));
% 
%     [h, p, ci, stats] = ttest(vals, 0);   % test against mu0 = 0
% 
%     GroupName(i)   = g;
%     N(i)           = numel(vals);
%     MeanTL(i)      = mean(vals);
%     SD_TL(i)       = std(vals);
%     tStat(i)       = stats.tstat;
%     df(i)          = stats.df;
%     pValue(i)      = p;
%     CI_Lower(i)    = ci(1);
%     CI_Upper(i)    = ci(2);
%     CohensD(i)     = mean(vals) / std(vals);   % effect size
% 
%     if p < 0.05
%         Significant(i) = "Yes (real effect)";
%     else
%         Significant(i) = "No (consistent w/ noise)";
%     end
% end
% 
% %==========================================================================
% % RESULTS TABLE
% %==========================================================================
% OneSampleTTestResults = table(GroupName, N, MeanTL, SD_TL, tStat, df, ...
%     pValue, CI_Lower, CI_Upper, CohensD, Significant, ...
%     'VariableNames', {'Group','N','Mean_PctTL','SD_PctTL','t_stat','df', ...
%     'p_value','CI_Lower','CI_Upper','CohensD','Interpretation'});
% 
% disp(OneSampleTTestResults)
% writetable(OneSampleTTestResults, 'OneSampleTTest_TransmissionLoss.csv');
% fprintf('\nTable saved to OneSampleTTest_TransmissionLoss.csv\n');
% %==========================================================================
% % UPDATED PLOTS 
% %==========================================================================
% 
% %FOREST PLOT FOR ONE-SAMPLE T-TEST
% % Each black dot is the group's mean %Transmission Loss (Male Rat ≈24%, Male Mouse ≈15%, Female Rat ≈18%).
% % Each horizontal blue line is the 95% confidence interval around that mean — the range where the true population mean plausibly sits.
% % The red dashed vertical line at zero represents "no effect" — if a group's confidence interval crossed this line, you couldn't conclude that group has a real transmission loss effect (it could just be noise).
% 
% 
% %BOX PLOT FOR GROUP COMPARISONS (WEIGHT)
% figure('Color','w');
% y = double(T.PctTransLoss);
% violinplot(categorical(T.Group), y);
% ylabel('% Transmission Loss')
% title('%Transmission Loss Distribution by Group')
% grid on
% 
% %COMBINED MULTIPLES PABEL FOR FIGURES
% figure('Color','w','Position',[100 100 1000 800]);
% tiledlayout(2,2)
% 
% nexttile; 
% hold on 
% groupNames  = ["Male Rat", "Female Rat", "Male Mouse"];
% markerStyle = {'o', 's', '^'};
% colours     = {[0.20 0.45 0.85], [0.85 0.30 0.30], [0.10 0.65 0.35]};
% 
% for k = 1:numel(groupNames)
%     gName = groupNames(k);
%     mask  = T.Group == gName;
%     if ~any(mask), continue; end
%     sd = groupStd(T, gName);
%     errorbar(T.Weight(mask), T.PctTransLoss(mask), sd*ones(sum(mask),1), ...
%         markerStyle{k}, 'MarkerSize', 8, 'MarkerFaceColor', colours{k}, ...
%         'MarkerEdgeColor', 'k', 'Color', colours{k}, ...
%         'LineWidth', 1.3, 'CapSize', 6, 'DisplayName', gName);
% end
% hold off
% xlabel('Animal Weight (g)', 'FontSize', 12, 'FontWeight', 'bold')
% ylabel('% Transmission Loss', 'FontSize', 12, 'FontWeight', 'bold')
% title('%Transmission Loss vs Animal Weight (All Specimens)', 'FontSize', 13, 'FontWeight', 'bold')
% legend('Location', 'best', 'FontSize', 11)
% grid on; box on
% set(gca, 'FontSize', 11, 'LineWidth', 1)
% 
% nexttile; 
% Tsdr = T(isRat & ~isnan(T.SDR), :);
% plotWithTrendline(Tsdr, 'SDR', ...
%     'Skull Density Ratio (SDR)', '%Transmission Loss vs SDR (Rats)')
% 
% nexttile;
% Trat = T(isRat & ~isnan(T.SkullThickness), :);
% plotWithTrendline(Trat, 'SkullThickness', ...
%     'Avg Skull Thickness (mm)', '%Transmission Loss vs Skull Thickness (Rats)')
% 
% nexttile; 
% %FOREST PLOT FOR ONE-SAMPLE T-TEST
% % Each black dot is the group's mean %Transmission Loss (Male Rat ≈24%, Male Mouse ≈15%, Female Rat ≈18%).
% % Each horizontal blue line is the 95% confidence interval around that mean — the range where the true population mean plausibly sits.
% % The red dashed vertical line at zero represents "no effect" — if a group's confidence interval crossed this line, you couldn't conclude that group has a real transmission loss effect (it could just be noise).
% 
% 
% y = 1:height(OneSampleTTestResults);
% errorbar(OneSampleTTestResults.Mean_PctTL, y, ...
%     OneSampleTTestResults.Mean_PctTL - OneSampleTTestResults.CI_Lower, ...
%     OneSampleTTestResults.CI_Upper - OneSampleTTestResults.Mean_PctTL, ...
%     'horizontal', 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'k', 'LineWidth', 1.5)
% hold on
% xline(0, '--r', 'LineWidth', 1.5)   % reference line at zero = "no effect"
% hold off
% yticks(y); yticklabels(OneSampleTTestResults.Group)
% xlabel('% Transmission Loss (95% CI)')
% title('One-Sample t-Test: Effect Size and Confidence Intervals by Group')
% grid on
% 
% % CORRELATION HEATMAP
% varsToCorr = T(:, {'Weight','SkullThickness','SDR','PctTransLoss'});
% corrMat = corr(varsToCorr{:,:}, 'rows', 'complete');
% figure('Color','w');
% heatmap(varsToCorr.Properties.VariableNames, varsToCorr.Properties.VariableNames, corrMat, ...
%     'Colormap', parula, 'ColorLimits', [-1 1])
% title('Correlation Matrix: Weight, Skull Thickness, SDR, %TransLoss')
% 
% 
% % BUBBLE CHART
% 
% figure('Color','w');
% scatter(Trat.SDR, Trat.SkullThickness, 100, Trat.PctTransLoss, 'filled', ...
%     'MarkerEdgeColor', 'k')
% xlabel('SDR', 'FontSize', 12, 'FontWeight', 'bold')
% ylabel('Skull Thickness (mm)', 'FontSize', 12, 'FontWeight', 'bold')
% title('SDR vs Skull Thickness, Coloured by %Transmission Loss', 'FontSize', 13, 'FontWeight', 'bold')
% c = colorbar;
% c.Label.String = '% Transmission Loss';
% c.Label.FontSize = 11;
% c.Label.FontWeight = 'bold';
% colormap(parula)
% grid on; box on


%==========================================================================
% ONE-WAY TRANSMISSION LOSS
% READ RESULTS SHEET — this holds the correct %TransLoss values (%reduction)
%==========================================================================
excelFile = 'CT_ImageData_Reorganised.xlsx';
optsR = detectImportOptions(excelFile, 'Sheet', 'Results ');  % check exact sheet name
Tres = readtable(excelFile, optsR);
Tres.Properties.VariableNames = matlab.lang.makeValidName(Tres.Properties.VariableNames);
Tres = Tres(:, 1:9);
Tres.Properties.VariableNames = {'Specimen','PeakPressure','NormPeakPressure', ...
    'TransLoss_kPa','PctReduction','FocalX','FocalY','FocalZ','FWHM_X'};
Tres = Tres(~cellfun(@isempty, Tres.Specimen), :);

% Remove Free Field row — it's the reference, not a specimen with transmission loss
Tres = Tres(~strcmpi(strtrim(Tres.Specimen), 'Free Field'), :);

%==========================================================================
% READ 4MATLAB SHEET — for Weight, SkullThickness, SDR lookup
%==========================================================================
optsM = detectImportOptions(excelFile, 'Sheet', '4matlab');
Tphys = readtable(excelFile, optsM);
Tphys.Properties.VariableNames = matlab.lang.makeValidName(Tphys.Properties.VariableNames);
Tphys = Tphys(:, 1:5);
Tphys.Properties.VariableNames = {'SampleID','Sex','Weight','SkullThickness','SDR'};

%==========================================================================
% MATCH SPECIMEN NAMES BETWEEN SHEETS
% Results sheet uses "RM001", "RF001", "MM001" (no underscores)
% 4matlab sheet uses "R_M_001", "R_F_001", "M_M_001" (with underscores)
% Need to normalise names before matching
%==========================================================================
normaliseID = @(s) upper(erase(string(s), "_"));

Tres.NormID  = normaliseID(Tres.Specimen);
Tphys.NormID = normaliseID(Tphys.SampleID);

% Handle MMTest / Mtest naming mismatch explicitly
Tres.NormID(strcmpi(Tres.NormID,"MMTEST"))  = "MMTEST";
Tphys.NormID(strcmpi(Tphys.NormID,"MTEST")) = "MMTEST";

% Join on normalised ID
T = innerjoin(Tres, Tphys, 'Keys', 'NormID');

% Rename %reduction as the transmission loss variable used going forward
T.PctTransLoss = T.PctReduction;

%==========================================================================
% ASSIGN 3-WAY GROUP LABEL
%==========================================================================
isRat   = startsWith(T.NormID, 'R');
isMouse = startsWith(T.NormID, 'M');

Group = strings(height(T),1);
Group(isRat   & strcmpi(T.Sex,'Male'))   = "Male Rat";
Group(isRat   & strcmpi(T.Sex,'Female')) = "Female Rat";
Group(isMouse) = "Male Mouse";   % all mouse specimens here are male
T.Group = Group;

disp(T(:, {'Specimen','SampleID','Sex','Group','Weight','SDR','SkullThickness','PctTransLoss'}))

%==========================================================================
% READ FOCAL POSITION DATA
%==========================================================================
excelFile = 'CT_ImageData_Reorganised.xlsx';
optsR = detectImportOptions(excelFile, 'Sheet', 'Results ');  % note trailing space in sheet name
Tfocal = readtable(excelFile, optsR);
Tfocal.Properties.VariableNames = matlab.lang.makeValidName(Tfocal.Properties.VariableNames);

% Keep only the relevant columns (first 10), drop the duplicate block on the right
Tfocal = Tfocal(:, 1:10);
Tfocal.Properties.VariableNames = {'Specimen','PeakPressure','NormPeakPressure', ...
    'TransLoss_kPa','PctReduction','FocalX','FocalY','FocalZ','FWHM_X','FWHM_Y'};

% Remove empty rows
Tfocal = Tfocal(~cellfun(@isempty, Tfocal.Specimen), :);

%==========================================================================
% EXTRACT FREE FIELD ORIGIN
%==========================================================================
ffMask = strcmpi(strtrim(Tfocal.Specimen), 'Free Field');
originX = Tfocal.FocalX(ffMask);
originY = Tfocal.FocalY(ffMask);
originZ = Tfocal.FocalZ(ffMask);

% Compute displacement relative to Free Field origin
Tfocal.dX = Tfocal.FocalX - originX;
Tfocal.dY = Tfocal.FocalY - originY;
Tfocal.dZ = Tfocal.FocalZ - originZ;

%==========================================================================
% EXTRACT FREE FIELD FWHM REFERENCE VALUES (before removing the row)
%==========================================================================
freeField_FWHM_X = Tfocal.FWHM_X(ffMask);
freeField_FWHM_Y = Tfocal.FWHM_Y(ffMask);
fprintf('Free Field FWHM_X = %.3f mm, FWHM_Y = %.3f mm\n', freeField_FWHM_X, freeField_FWHM_Y)

% Remove Free Field row itself (it's now the origin, dX=dY=dZ=0)
Tspec = Tfocal(~ffMask, :);

% Assign group labels based on specimen prefix
Tspec.Group = strings(height(Tspec),1);
Tspec.Group(startsWith(Tspec.Specimen,'RM')) = "Male Rat";
Tspec.Group(startsWith(Tspec.Specimen,'RF')) = "Female Rat";
Tspec.Group(startsWith(Tspec.Specimen,'MM')) = "Male Mouse";

%==========================================================================
% 3D PLOT: FOCAL DISPLACEMENT RELATIVE TO FREE FIELD ORIGIN
%==========================================================================
groupNames = ["Male Rat","Female Rat","Male Mouse"];
markerStyle = {'o','s','^'};
coloursMap = containers.Map(groupNames, {[0.20 0.45 0.85],[0.85 0.30 0.30],[0.10 0.65 0.35]});

figure('Color','w','Position',[100 100 1100 500]);
tiledlayout(1,2)

nexttile
hold on
for k = 1:3
    mask = Tspec.Group == groupNames(k);
    x = Tspec.dX(mask); y = Tspec.dY(mask);
    if sum(mask) > 2
        cx = mean(x); cy = mean(y);
        sx = std(x); sy = std(y);
        if sx == 0, sx = 0.02; end
        if sy == 0, sy = 0.02; end
        theta = linspace(0, 2*pi, 100);
        ellX = cx + 2*sx*cos(theta);
        ellY = cy + 2*sy*sin(theta);
        fill(ellX, ellY, coloursMap(groupNames(k)), 'FaceAlpha', 0.15, ...
            'EdgeColor', coloursMap(groupNames(k)), 'LineWidth', 1.5, 'HandleVisibility', 'off')
    end
    scatter(x, y, 100, markerStyle{k}, 'MarkerFaceColor', coloursMap(groupNames(k)), ...
        'MarkerEdgeColor', 'k', 'DisplayName', groupNames(k))
end
plot(0, 0, 'k+', 'MarkerSize', 12, 'DisplayName', 'Free Field')
hold off
xlabel('\DeltaX (mm)'); ylabel('\DeltaY (mm)')
title('Lateral Focal Shift (X-Y plane)')
legend('Location','best'); grid on; axis equal

nexttile
hold on
for k = 1:3
    mask = Tspec.Group == groupNames(k);
    zVals = Tspec.dZ(mask);
    meanZ = mean(zVals); sdZ = std(zVals);
    fill([k-0.15 k+0.15 k+0.15 k-0.15], [meanZ-sdZ meanZ-sdZ meanZ+sdZ meanZ+sdZ], ...
        coloursMap(groupNames(k)), 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility','off')
    scatter(k*ones(sum(mask),1), zVals, 100, markerStyle{k}, ...
        'MarkerFaceColor', coloursMap(groupNames(k)), 'MarkerEdgeColor','k')
end
yline(0, '--k')
hold off
xticks(1:3); xticklabels(groupNames)
ylabel('\DeltaZ (mm)')
title('Axial Depth Focal Shift')
grid on


%--------------------------------------------------------------------------

figure('Color','w','Position',[100 100 1400 900]);
tiledlayout(2,2, 'TileSpacing','compact', 'Padding','compact')

groupNames  = ["Male Rat","Female Rat","Male Mouse"];
markerStyle = {'o','s','^'};
coloursCell     = {[0.20 0.45 0.85],[0.85 0.30 0.30],[0.10 0.65 0.35]};

%==========================================================================
% TILE 1: %TransLoss vs Weight (All groups, group SD error bars)
%==========================================================================
nexttile
hold on
for k = 1:3
    gName = groupNames(k);
    mask  = T.Group == gName;
    if ~any(mask), continue; end
    sd = std(T.PctTransLoss(mask), 'omitnan');
    errorbar(T.Weight(mask), T.PctTransLoss(mask), sd*ones(sum(mask),1), ...
        markerStyle{k}, 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{k}, ...
        'MarkerEdgeColor', 'k', 'Color', coloursCell{k}, 'LineWidth', 1.3, ...
        'CapSize', 6, 'DisplayName', gName);
end
hold off
xlabel('Animal Weight (g)', 'FontSize', 11, 'FontWeight', 'bold')
ylabel('% Transmission Loss', 'FontSize', 11, 'FontWeight', 'bold')
title('%TransLoss vs Weight', 'FontSize', 12, 'FontWeight', 'bold')
legend('Location', 'best', 'FontSize', 8)
grid on; box on

%==========================================================================
% TILE 2: %TransLoss Distribution — violin plot by group
%==========================================================================
nexttile
violinplot(categorical(T.Group), T.PctTransLoss);
ylabel('% Transmission Loss', 'FontSize', 11, 'FontWeight', 'bold')
title('%TransLoss Distribution by Group', 'FontSize', 12, 'FontWeight', 'bold')
grid on

%==========================================================================
% TILE 3: %TransLoss vs SDR (Rats only, with trendline + R^2 + p-value)
%==========================================================================
nexttile
hold on
Tsdr = T(startsWith(T.NormID,"R") & ~isnan(T.SDR), :);
maskM = Tsdr.Group == "Male Rat";
maskF = Tsdr.Group == "Female Rat";
sdMale   = std(Tsdr.PctTransLoss(maskM), 'omitnan');
sdFemale = std(Tsdr.PctTransLoss(maskF), 'omitnan');

errorbar(Tsdr.SDR(maskM), Tsdr.PctTransLoss(maskM), sdMale*ones(sum(maskM),1), ...
    'o', 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{1}, 'MarkerEdgeColor','k', ...
    'Color', coloursCell{1}, 'LineWidth', 1.3, 'CapSize', 6, 'DisplayName', 'Male Rat')
errorbar(Tsdr.SDR(maskF), Tsdr.PctTransLoss(maskF), sdFemale*ones(sum(maskF),1), ...
    's', 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{2}, 'MarkerEdgeColor','k', ...
    'Color', coloursCell{2}, 'LineWidth', 1.3, 'CapSize', 6, 'DisplayName', 'Female Rat')

xM = Tsdr.SDR(maskM); yM = Tsdr.PctTransLoss(maskM);
if numel(xM) >= 2
    mdlM = fitlm(xM, yM);
    xFitM = linspace(min(xM), max(xM), 50);
    yFitM = predict(mdlM, xFitM');
    plot(xFitM, yFitM, '--', 'Color', coloursCell{1}, 'LineWidth', 1.8, 'HandleVisibility','off')
    text(xFitM(end), yFitM(end), sprintf('  R^2=%.2f, p=%.2f', mdlM.Rsquared.Ordinary, mdlM.Coefficients.pValue(2)), ...
        'Color', coloursCell{1}, 'FontWeight','bold', 'FontSize', 8)
end
xF = Tsdr.SDR(maskF); yF = Tsdr.PctTransLoss(maskF);
if numel(xF) >= 2
    mdlF = fitlm(xF, yF);
    xFitF = linspace(min(xF), max(xF), 50);
    yFitF = predict(mdlF, xFitF');
    plot(xFitF, yFitF, '--', 'Color', coloursCell{2}, 'LineWidth', 1.8, 'HandleVisibility','off')
    text(xFitF(end), yFitF(end), sprintf('  R^2=%.2f, p=%.2f', mdlF.Rsquared.Ordinary, mdlF.Coefficients.pValue(2)), ...
        'Color', coloursCell{2}, 'FontWeight','bold', 'FontSize', 8)
end
hold off
xlabel('SDR', 'FontSize', 11, 'FontWeight', 'bold')
ylabel('% Transmission Loss', 'FontSize', 11, 'FontWeight', 'bold')
title('%TransLoss vs SDR (Rats)', 'FontSize', 12, 'FontWeight', 'bold')
legend('Location', 'best', 'FontSize', 8)
grid on; box on

%==========================================================================
% TILE 4: %TransLoss vs Skull Thickness (All groups, incl. mice)
%==========================================================================
nexttile
hold on
Tthick_all = T(~isnan(T.SkullThickness), :);
for k = 1:3
    gName = groupNames(k);
    mask = Tthick_all.Group == gName;
    if ~any(mask), continue; end
    sd = std(Tthick_all.PctTransLoss(mask), 'omitnan');
    errorbar(Tthick_all.SkullThickness(mask), Tthick_all.PctTransLoss(mask), sd*ones(sum(mask),1), ...
        markerStyle{k}, 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{k}, ...
        'MarkerEdgeColor','k', 'Color', coloursCell{k}, 'LineWidth', 1.3, ...
        'CapSize', 6, 'DisplayName', gName)
end
hold off
xlabel('Avg Target Skull Thickness (mm)', 'FontSize', 11, 'FontWeight', 'bold')
ylabel('% Transmission Loss', 'FontSize', 11, 'FontWeight', 'bold')
title('%TransLoss vs Skull Thickness (All Groups)', 'FontSize', 12, 'FontWeight', 'bold')
legend('Location', 'best', 'FontSize', 8)
grid on; box on


%--------------------------------------------------------------------------

% Assumes Tspec (from Results sheet, has dX/dY/dZ/Specimen) and T (from 4matlab, 
% has SDR/SkullThickness/Group) already exist from earlier steps.
% Merge them on normalised specimen ID.

normaliseID = @(s) upper(erase(string(s), "_"));
Tspec.NormID = normaliseID(Tspec.Specimen);
T.NormID     = normaliseID(T.SampleID);

Tmerged = innerjoin(Tspec, T, 'Keys', 'NormID', ...
    'LeftVariables', {'Specimen','dX','dY','dZ','NormID'}, ...
    'RightVariables', {'SampleID','Group','Sex','Weight','SkullThickness','SDR','PctTransLoss'});

disp(Tmerged.Properties.VariableNames)
disp(Tmerged(:, {'Specimen','SampleID','Group','dY','dZ','SDR','SkullThickness'}))
%==========================================================================
% PREP: ensure sorted, numeric-indexed tables (fixes line-tracking bug)
%==========================================================================
Trats = Tmerged(startsWith(Tmerged.NormID, "R") & ~isnan(Tmerged.SDR), :);
Trats = sortrows(Trats, 'SDR');
nR = height(Trats);
xPosR = 1:nR;

Tall = Tmerged(~isnan(Tmerged.SkullThickness), :);
Tall = sortrows(Tall, 'SkullThickness');
n = height(Tall);
xPos = 1:n;

%==========================================================================
% TILED FIGURE
%==========================================================================
groupNames = ["Male Rat","Female Rat","Male Mouse"];
coloursCell = {[0.20 0.45 0.85],[0.85 0.30 0.30],[0.10 0.65 0.35]};

figure('Color','w','Position',[100 100 1400 900]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact')

nexttile
yyaxis left
bar(xPosR, Trats.SDR, 'FaceColor', [0.30 0.55 0.80])
ylabel('SDR'); ylim([0 1])
yyaxis right
plot(xPosR, Trats.dY, '-o', 'Color', [0.75 0.35 0.35], 'LineWidth', 2, ...
    'MarkerFaceColor', [0.75 0.35 0.35], 'MarkerSize', 6)
ylabel('\DeltaY (mm)')
xticks(xPosR); xticklabels(Trats.Specimen); xtickangle(45)
title('SDR vs Focal Distortion (\DeltaY), Rats')
legend({'SDR','\DeltaY'}, 'Location','best', 'FontSize', 8)
grid on

nexttile
yyaxis left
bar(xPos, Tall.SkullThickness, 'FaceColor', [0.30 0.55 0.80])
ylabel('Avg Target Thickness (mm)')
yyaxis right
plot(xPos, Tall.dY, '-o', 'Color', [0.75 0.35 0.35], 'LineWidth', 2, ...
    'MarkerFaceColor', [0.75 0.35 0.35], 'MarkerSize', 6)
ylabel('\DeltaY (mm)')
xticks(xPos); xticklabels(Tall.Specimen); xtickangle(45)
title('Skull Thickness vs Focal Distortion (\DeltaY), All Groups')
legend({'Thickness','\DeltaY'}, 'Location','best', 'FontSize', 8)
grid on

nexttile
yyaxis left
bar(xPosR, Trats.SDR, 'FaceColor', [0.30 0.55 0.80])
ylabel('SDR'); ylim([0 1])
yyaxis right
plot(xPosR, Trats.dZ, '-o', 'Color', [0.65 0.20 0.20], 'LineWidth', 2, ...
    'MarkerFaceColor', [0.65 0.20 0.20], 'MarkerSize', 6)
ylabel('\DeltaZ (mm)')
xticks(xPosR); xticklabels(Trats.Specimen); xtickangle(45)
title('SDR vs Focal Distortion (\DeltaZ), Rats')
legend({'SDR','\DeltaZ'}, 'Location','best', 'FontSize', 8)
grid on

nexttile
yyaxis left
bar(xPos, Tall.SkullThickness, 'FaceColor', [0.30 0.55 0.80])
ylabel('Avg Target Thickness (mm)')
yyaxis right
plot(xPos, Tall.dZ, '-o', 'Color', [0.65 0.20 0.20], 'LineWidth', 2, ...
    'MarkerFaceColor', [0.65 0.20 0.20], 'MarkerSize', 6)
ylabel('\DeltaZ (mm)')
xticks(xPos); xticklabels(Tall.Specimen); xtickangle(45)
title('Skull Thickness vs Focal Distortion (\DeltaZ), All Groups')
legend({'Thickness','\DeltaZ'}, 'Location','best', 'FontSize', 8)
grid on

%==========================================================================
% REBUILD Tmerged2 WITH BOTH FWHM_X AND FWHM_Y
%==========================================================================

Tmerged2 = innerjoin(Tspec, T, 'Keys', 'NormID', ...
    'LeftVariables', {'Specimen','dX','dY','dZ','FWHM_X','FWHM_Y','NormID'}, ...
    'RightVariables', {'SampleID','Group','Sex','Weight','SkullThickness','SDR','PctTransLoss'});
Tmerged2 = sortrows(Tmerged2, 'Group');
n = height(Tmerged2);
xPos = 1:n;

groupNames  = ["Male Rat","Female Rat","Male Mouse"];
markerStyle = {'o','s','^'};
coloursCell = {[0.20 0.45 0.85],[0.85 0.30 0.30],[0.10 0.65 0.35]};
coloursMap  = containers.Map(groupNames, coloursCell);
barColours  = cell2mat(arrayfun(@(g) coloursMap(g), Tmerged2.Group, 'UniformOutput', false));

%--- Figure A: FWHM_X and FWHM_Y by specimen (grouped bar) ---
figure('Color','w','Position',[900 100 800 550]);
barData = [Tmerged2.FWHM_X, Tmerged2.FWHM_Y];
bh = bar(xPos, barData, 'grouped');
bh(1).FaceColor = [0.30 0.55 0.80];
bh(2).FaceColor = [0.90 0.55 0.20];
xticks(xPos); xticklabels(Tmerged2.Specimen); xtickangle(45)
ylabel('Focal Spot FWHM (mm)', 'FontSize', 12, 'FontWeight', 'bold')
title('Focal Spot Width by Specimen (X vs Y axis)', 'FontSize', 13, 'FontWeight', 'bold')

hold on
yline(freeField_FWHM_X, '--', 'Color', [0.30 0.55 0.80], 'LineWidth', 1.8, ...
     'LabelHorizontalAlignment', 'left', 'FontSize', 8)
yline(freeField_FWHM_Y, '--', 'Color', [0.90 0.55 0.20], 'LineWidth', 1.8, ...
     'LabelHorizontalAlignment', 'left', 'FontSize', 8)
hold off

legend({'FWHM — X axis','FWHM — Y axis'}, 'Location', 'best')
grid on; box on

%--- Figure B: FWHM_X and FWHM_Y vs Weight ---
figure('Color','w','Position',[100 100 1400 550]);
tiledlayout(3,2,'TileSpacing','compact','Padding','compact')

nexttile
hold on
for k = 1:3
    mask = Tmerged2.Group == groupNames(k);
    if ~any(mask), continue; end
    plotGroupBlob(Tmerged2.Weight(mask), Tmerged2.FWHM_X(mask), coloursCell{k}, coloursCell{k})
    sd = std(Tmerged2.FWHM_X(mask), 'omitnan');
    errorbar(Tmerged2.Weight(mask), Tmerged2.FWHM_X(mask), sd*ones(sum(mask),1), ...
        markerStyle{k}, 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{k}, ...
        'MarkerEdgeColor','k', 'Color', coloursCell{k}, 'LineWidth', 1.3, ...
        'CapSize', 6, 'DisplayName', groupNames(k))
end
yline(freeField_FWHM_X, '--k', 'Free Field', 'LineWidth', 1.5, ...
    'LabelHorizontalAlignment', 'left', 'FontSize', 8, 'HandleVisibility', 'off')
hold off
xlabel('Animal Weight (g)'); ylabel('FWHM — X axis (mm)')
title('Focal FWHM (X axis) vs Weight'); legend('Location','best','FontSize',8); grid on; box on

nexttile
hold on
for k = 1:3
    mask = Tmerged2.Group == groupNames(k);
    if ~any(mask), continue; end
    plotGroupBlob(Tmerged2.Weight(mask), Tmerged2.FWHM_Y(mask), coloursCell{k}, coloursCell{k})
    sd = std(Tmerged2.FWHM_Y(mask), 'omitnan');
    errorbar(Tmerged2.Weight(mask), Tmerged2.FWHM_Y(mask), sd*ones(sum(mask),1), ...
        markerStyle{k}, 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{k}, ...
        'MarkerEdgeColor','k', 'Color', coloursCell{k}, 'LineWidth', 1.3, ...
        'CapSize', 6, 'DisplayName', groupNames(k))
end
yline(freeField_FWHM_Y, '--k', 'Free Field', 'LineWidth', 1.5, ...
    'LabelHorizontalAlignment', 'left', 'FontSize', 8, 'HandleVisibility', 'off')
hold off
xlabel('Animal Weight (g)'); ylabel('FWHM — Y axis (mm)')
title('Focal FWHM (Y axis) vs Weight'); legend('Location','best','FontSize',8); grid on; box on

%--- Figure C: FWHM_X and FWHM_Y vs SDR (Rats), with trendlines ---
Trats2 = Tmerged2(startsWith(Tmerged2.NormID,"R") & ~isnan(Tmerged2.SDR), :);
maskM = Trats2.Group == "Male Rat";
maskF = Trats2.Group == "Female Rat";


nexttile
hold on
plotGroupBlob(Trats2.SDR(maskM), Trats2.FWHM_X(maskM), coloursCell{1}, coloursCell{1})
plotGroupBlob(Trats2.SDR(maskF), Trats2.FWHM_X(maskF), coloursCell{2}, coloursCell{2})
sdM = std(Trats2.FWHM_X(maskM), 'omitnan');
sdF = std(Trats2.FWHM_X(maskF), 'omitnan');
errorbar(Trats2.SDR(maskM), Trats2.FWHM_X(maskM), sdM*ones(sum(maskM),1), ...
    'o', 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{1}, 'MarkerEdgeColor','k', ...
    'Color', coloursCell{1}, 'LineWidth', 1.3, 'CapSize', 6, 'DisplayName', 'Male Rat')
errorbar(Trats2.SDR(maskF), Trats2.FWHM_X(maskF), sdF*ones(sum(maskF),1), ...
    's', 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{2}, 'MarkerEdgeColor','k', ...
    'Color', coloursCell{2}, 'LineWidth', 1.3, 'CapSize', 6, 'DisplayName', 'Female Rat')
xM = Trats2.SDR(maskM); yM = Trats2.FWHM_X(maskM);
if numel(xM) >= 2
    mdlM = fitlm(xM, yM);
    % xFitM = linspace(min(xM), max(xM), 50); yFitM = predict(mdlM, xFitM');
    % plot(xFitM, yFitM, '--', 'Color', coloursCell{1}, 'LineWidth', 1.5, 'HandleVisibility','off')
    % text(xFitM(end), yFitM(end), sprintf('  R^2=%.2f, p=%.2f', mdlM.Rsquared.Ordinary, mdlM.Coefficients.pValue(2)), ...
        % 'Color', coloursCell{1}, 'FontWeight','bold', 'FontSize', 8)
end
xF = Trats2.SDR(maskF); yF = Trats2.FWHM_X(maskF);
if numel(xF) >= 2
    mdlF = fitlm(xF, yF);
    % xFitF = linspace(min(xF), max(xF), 50); yFitF = predict(mdlF, xFitF');
    % plot(xFitF, yFitF, '--', 'Color', coloursCell{2}, 'LineWidth', 1.5, 'HandleVisibility','off')
    % text(xFitF(end), yFitF(end), sprintf('  R^2=%.2f, p=%.2f', mdlF.Rsquared.Ordinary, mdlF.Coefficients.pValue(2)), ...
        % 'Color', coloursCell{2}, 'FontWeight','bold', 'FontSize', 8)
end
yline(freeField_FWHM_X, '--k', 'Free Field', 'LineWidth', 1.5, ...
    'LabelHorizontalAlignment', 'left', 'FontSize', 8, 'HandleVisibility', 'off')
hold off
xlabel('SDR'); ylabel('FWHM — X axis (mm)')
title('Focal FWHM (X axis) vs SDR (Rats)'); legend('Location','best','FontSize',8); grid on; box on

nexttile
hold on
plotGroupBlob(Trats2.SDR(maskM), Trats2.FWHM_Y(maskM), coloursCell{1}, coloursCell{1})
plotGroupBlob(Trats2.SDR(maskF), Trats2.FWHM_Y(maskF), coloursCell{2}, coloursCell{2})
sdMy = std(Trats2.FWHM_Y(maskM), 'omitnan');
sdFy = std(Trats2.FWHM_Y(maskF), 'omitnan');
errorbar(Trats2.SDR(maskM), Trats2.FWHM_Y(maskM), sdMy*ones(sum(maskM),1), ...
    'o', 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{1}, 'MarkerEdgeColor','k', ...
    'Color', coloursCell{1}, 'LineWidth', 1.3, 'CapSize', 6, 'DisplayName', 'Male Rat')
errorbar(Trats2.SDR(maskF), Trats2.FWHM_Y(maskF), sdFy*ones(sum(maskF),1), ...
    's', 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{2}, 'MarkerEdgeColor','k', ...
    'Color', coloursCell{2}, 'LineWidth', 1.3, 'CapSize', 6, 'DisplayName', 'Female Rat')
xMy = Trats2.SDR(maskM); yMy = Trats2.FWHM_Y(maskM);
if numel(xMy) >= 2
    % mdlMy = fitlm(xMy, yMy);
    % xFitMy = linspace(min(xMy), max(xMy), 50); yFitMy = predict(mdlMy, xFitMy');
    % plot(xFitMy, yFitMy, '--', 'Color', coloursCell{1}, 'LineWidth', 1.5, 'HandleVisibility','off')
    % text(xFitMy(end), yFitMy(end), sprintf('  R^2=%.2f, p=%.2f', mdlMy.Rsquared.Ordinary, mdlMy.Coefficients.pValue(2)), ...
        % 'Color', coloursCell{1}, 'FontWeight','bold', 'FontSize', 8)
end
xFy = Trats2.SDR(maskF); yFy = Trats2.FWHM_Y(maskF);
if numel(xFy) >= 2
    % mdlFy = fitlm(xFy, yFy);
    % xFitFy = linspace(min(xFy), max(xFy), 50); yFitFy = predict(mdlFy, xFitFy');
    % plot(xFitFy, yFitFy, '--', 'Color', coloursCell{2}, 'LineWidth', 1.5, 'HandleVisibility','off')
    % text(xFitFy(end), yFitFy(end), sprintf('  R^2=%.2f, p=%.2f', mdlFy.Rsquared.Ordinary, mdlFy.Coefficients.pValue(2)), ...
        % 'Color', coloursCell{2}, 'FontWeight','bold', 'FontSize', 8)
end
yline(freeField_FWHM_Y, '--k', 'Free Field', 'LineWidth', 1.5, ...
    'LabelHorizontalAlignment', 'left', 'FontSize', 8, 'HandleVisibility', 'off')
hold off
xlabel('SDR'); ylabel('FWHM — Y axis (mm)')
title('Focal FWHM (Y axis) vs SDR (Rats)'); legend('Location','best','FontSize',8); grid on; box on

%--- Figure D: FWHM_X and FWHM_Y vs Skull Thickness (All groups) ---
Tthick2 = Tmerged2(~isnan(Tmerged2.SkullThickness), :);

nexttile
hold on
for k = 1:3
    mask = Tthick2.Group == groupNames(k);
    if ~any(mask), continue; end
    plotGroupBlob(Tthick2.SkullThickness(mask), Tthick2.FWHM_X(mask),coloursCell{k}, coloursCell{k})
    sd = std(Tthick2.FWHM_X(mask), 'omitnan');
    errorbar(Tthick2.SkullThickness(mask), Tthick2.FWHM_X(mask), sd*ones(sum(mask),1), ...
        markerStyle{k}, 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{k}, ...
        'MarkerEdgeColor','k', 'Color', coloursCell{k}, 'LineWidth', 1.3, ...
        'CapSize', 6, 'DisplayName', groupNames(k))
end
yline(freeField_FWHM_X, '--k', 'Free Field', 'LineWidth', 1.5, ...
    'LabelHorizontalAlignment', 'left', 'FontSize', 8, 'HandleVisibility', 'off')
hold off
xlabel('Avg Target Skull Thickness (mm)'); ylabel('FWHM — X axis (mm)')
title('Focal FWHM (X axis) vs Skull Thickness'); legend('Location','best','FontSize',8); grid on; box on

nexttile
hold on
for k = 1:3
    mask = Tthick2.Group == groupNames(k);
    if ~any(mask), continue; end
    plotGroupBlob(Tthick2.SkullThickness(mask), Tthick2.FWHM_Y(mask),coloursCell{k}, coloursCell{k})
    sd = std(Tthick2.FWHM_Y(mask), 'omitnan');
    errorbar(Tthick2.SkullThickness(mask), Tthick2.FWHM_Y(mask), sd*ones(sum(mask),1), ...
        markerStyle{k}, 'MarkerSize', 8, 'MarkerFaceColor', coloursCell{k}, ...
        'MarkerEdgeColor','k', 'Color', coloursCell{k}, 'LineWidth', 1.3, ...
        'CapSize', 6, 'DisplayName', groupNames(k))
end
yline(freeField_FWHM_Y, '--k', 'Free Field', 'LineWidth', 1.5, ...
    'LabelHorizontalAlignment', 'left', 'FontSize', 8, 'HandleVisibility', 'off')
hold off
xlabel('Avg Target Skull Thickness (mm)'); ylabel('FWHM — Y axis (mm)')
title('Focal FWHM (Y axis) vs Skull Thickness'); legend('Location','best','FontSize',8); grid on; box on
%==========================================================================
% KRUSKAL-WALLIS TEST: Is %TransLoss significantly different across
% Male Rat / Female Rat / Male Mouse groups?
% Non-parametric alternative to one-way ANOVA — does not assume normality,
% appropriate given n=3 per group.
%==========================================================================
[pKW, tblKW, statsKW] = kruskalwallis(T.PctTransLoss, T.Group, 'off');
fprintf('Kruskal-Wallis omnibus test: p = %.4f\n', pKW);
fprintf('(Note: with n=3/group, minimum achievable p-value is ~0.10 — ')
fprintf('a non-significant result here reflects low power, not necessarily no true difference)\n\n')

%==========================================================================
% GROUP COMPARISON: Is %TransLoss significantly different across
% Male Rat / Female Rat / Male Mouse? (ONE-WAY data, 'Results' sheet)
%==========================================================================

% --- Kruskal-Wallis omnibus test (non-parametric, appropriate for small n) ---
[pKW, tblKW, statsKW] = kruskalwallis(T.PctTransLoss, T.Group, 'off');
fprintf('Kruskal-Wallis omnibus test p-value: %.4f\n', pKW)
fprintf('H(%d) = %.3f\n', tblKW{2,3}, tblKW{2,5})

if pKW < 0.05
    fprintf('--> Significant difference detected across groups.\n')
else
    fprintf('--> No significant omnibus difference detected (note: low power likely given small n).\n')
end



%==========================================================================
% EFFECT SIZE SUMMARY: Cohen's d for each pairwise comparison
% (reported alongside p-values since p-value alone is unreliable at n=3)
%==========================================================================
fprintf('\n--- Cohen''s d effect sizes (pairwise) ---\n')
for i = 1:numel(groups)-1
    for j = i+1:numel(groups)
        g1 = groups(i); g2 = groups(j);
        x1 = T.PctTransLoss(T.Group == g1);
        x2 = T.PctTransLoss(T.Group == g2);
        pooledSD = sqrt(((numel(x1)-1)*var(x1) + (numel(x2)-1)*var(x2)) / (numel(x1)+numel(x2)-2));
        d = (mean(x1) - mean(x2)) / pooledSD;
        fprintf('%s vs %s: Cohen''s d = %.2f\n', g1, g2, d)
    end
end

%==========================================================================
% SUMMARY TABLE FOR REPORTING
%==========================================================================
GroupResults = table();
for i = 1:numel(groups)
    vals = T.PctTransLoss(T.Group == groups(i));
    GroupResults.Group(i)   = groups(i);
    GroupResults.N(i)       = numel(vals);
    GroupResults.Mean(i)    = mean(vals);
    GroupResults.SD(i)      = std(vals);
    GroupResults.Median(i)  = median(vals);
end
disp(GroupResults)
writetable(GroupResults, 'GroupSummary_PctTransLoss.csv');

fprintf('\nKruskal-Wallis result to report: H(%d) = %.2f, p = %.4f\n', ...
    numel(groups)-1, tblKW{2,5}, pKW)

%==========================================================================
% HELPER BLOCK 
%==========================================================================
function plotGroupBlob(x, y, faceColour, edgeColour)
% Draws a shaded convex hull around 3+ points; falls back to a simple
% line/patch for 2 points, and skips entirely for 1 point.
x = x(:); y = y(:);
valid = ~isnan(x) & ~isnan(y);
x = x(valid); y = y(valid);
n = numel(x);
if n < 2
    return
elseif n == 2
    % Draw a thick line as a stand-in "blob" for 2 points
    plot(x, y, '-', 'Color', edgeColour, 'LineWidth', 6, ...
        'Color', [edgeColour 0.25], 'HandleVisibility', 'off')
else
    try
        k = convhull(x, y);
        patch(x(k), y(k), faceColour, 'FaceAlpha', 0.15, ...
            'EdgeColor', edgeColour, 'LineWidth', 1.5, 'HandleVisibility', 'off')
    catch
        % Points are collinear — convhull fails; skip silently
    end
end
end


%==========================================================================
% POWER ANALYSIS: DEFINE TARGET EFFECT SIZES BASED ON LITERATURE/ANATOMY THRESHOLDS
%==========================================================================

% --- Transmission Loss threshold (percentage-based, literature-derived) ---
% Derived from Lea-Banks et al. 2026 (Brain Stimulation) parametric FUS
% hypotension study: optimal in situ pressure 1.65 MPa, with significant
% decline in hypotensive efficacy at 1.1 MPa (-33%) and 2.1 MPa (+27%).
% Applied here as a proportional (not absolute) transmission loss threshold,
% since experimental free-field pressures (max 0.8 MPa) fall well outside
% the Lea-Banks tested range, making an absolute kPa margin non-transferable.

targetPressure_kPa = 807;       % max free-field normalised in situ pressure tested in this study
allowablePctError = 0.33;       % 33% pressure deviation associated with reduced efficacy (Lea-Banks 2026)
pressureMargin_kPa = targetPressure_kPa * allowablePctError;  % for reporting only, not used in effect size calc

fprintf('Reference pressure: %.0f kPa; equivalent %.0f%% margin = %.1f kPa (context only)\n', ...
    targetPressure_kPa, allowablePctError*100, pressureMargin_kPa)

% Effect size defined directly in %TransLoss units (consistent with outcome variable)
pooledSD_TL = std(T.PctTransLoss, 'omitnan');
pctThreshold = allowablePctError * 100;   % 33 percentage points
d_TransLoss_target = pctThreshold / pooledSD_TL;
fprintf('Target Cohen''s d for %%TransLoss (based on %.0f%% margin): %.2f\n', ...
    pctThreshold, d_TransLoss_target)

nReq_TL = sampsizepwr('t2', [0 pooledSD_TL], pctThreshold, 0.80, [], 'Ratio', 1);
fprintf('Required n/group to detect this margin at 80%% power: %d\n', nReq_TL)

% --- Focal Distortion threshold ---
targetRegion_mm = 1.0;         % smallest dimension of your target brain region, e.g. mm
allowableDistortion_mm = 0.55 
fprintf('\nAllowable focal distortion before missing target: %.2f mm\n', allowableDistortion_mm)

pooledSD_dY = std(Tmerged.dY, 'omitnan');
d_dY_target = allowableDistortion_mm / pooledSD_dY;
fprintf('Target Cohen''s d for ΔY (based on %.2f mm threshold): %.2f\n', ...
    allowableDistortion_mm, d_dY_target)

nReq_dY = sampsizepwr('t2', [0 pooledSD_dY], allowableDistortion_mm, 0.80, [], 'Ratio', 1);
fprintf('Required n/group to detect this distortion at 80%% power: %d\n', nReq_dY)

% --- Focal Distortion threshold (Axial / Z-axis) ---
targetRegion_mm_Z = 0.75;        % smallest AXIAL dimension of target brain region (VLPAG), mm
allowableDistortion_mm_Z = 0.375
fprintf('\nAllowable axial focal distortion before missing target: %.2f mm\n', allowableDistortion_mm_Z)

pooledSD_dZ = std(Tmerged.dZ, 'omitnan');
d_dZ_target = allowableDistortion_mm_Z / pooledSD_dZ;
fprintf('Target Cohen''s d for ΔZ (based on %.2f mm threshold): %.2f\n', ...
    allowableDistortion_mm_Z, d_dZ_target)

nReq_dZ = sampsizepwr('t2', [0 pooledSD_dZ], allowableDistortion_mm_Z, 0.80, [], 'Ratio', 1);
fprintf('Required n/group to detect this axial distortion at 80%% power: %d\n', nReq_dZ)

% --- Non-inferiority / equivalence framing for Focal Distortion ---
% Question: can we be confident the TRUE mean focal distortion is below
% the 1.25 mm danger threshold (not "is there a 1.25 mm shift")?
% This is a one-sample, one-sided non-inferiority test.

dangerThreshold_mm = 1.0;      % upper margin - beam edge exits VLPAG
observedMean_dY = mean(Tmerged.dY, 'omitnan');   % your actual observed mean shift
pooledSD_dY = std(Tmerged.dY, 'omitnan');

alpha = 0.05;      % one-sided
power = 0.80;      % desired confidence of correctly concluding non-inferiority

% Margin: distance between true/expected mean and the danger threshold
delta = dangerThreshold_mm - observedMean_dY;

fprintf('Observed mean dY: %.3f mm, SD: %.3f mm\n', observedMean_dY, pooledSD_dY)
fprintf('Non-inferiority margin (delta): %.3f mm\n', delta)

if delta <= 0
    fprintf('Observed mean already exceeds the danger threshold - non-inferiority cannot be claimed.\n')
else
    zAlpha = norminv(1 - alpha);
    zBeta  = norminv(power);

    % One-sample one-sided non-inferiority sample size formula
    nReq_NI = ceil(((zAlpha + zBeta)^2 * pooledSD_dY^2) / delta^2);

    fprintf('Required n to claim non-inferiority (mean dY < %.2f mm) at %.0f%% power: %d\n', ...
        dangerThreshold_mm, power*100, nReq_NI)
end

% --- Sanity check: what CI width does your CURRENT sample size give you? ---
nCurrent = sum(~isnan(Tmerged.dY));
SEM_current = pooledSD_dY / sqrt(nCurrent);
tCrit = tinv(1 - alpha, nCurrent - 1);      % one-sided t critical value
upperCI_current = observedMean_dY + tCrit * SEM_current;

fprintf('\nWith current n = %d:\n', nCurrent)
fprintf('One-sided 95%% upper CI on mean dY: %.3f mm\n', upperCI_current)
if upperCI_current < dangerThreshold_mm
    fprintf('--> Current sample IS sufficient to rule out exceeding %.2f mm threshold.\n', dangerThreshold_mm)
else
    fprintf('--> Current sample is NOT sufficient to confidently rule out the threshold.\n')
end

% --- One-sided one-sample t-test: is axial distortion SIGNIFICANTLY ABOVE danger threshold? ---
dangerThreshold_mm_Z = 0.4;
vals_dZ = Tmerged.dZ(~isnan(Tmerged.dZ));   % or Tmerged_rats.dZ if filtering to rats
n_dZ = numel(vals_dZ);
mean_dZ = mean(vals_dZ);
sd_dZ = std(vals_dZ);

[h, p, ci, stats] = ttest(vals_dZ, dangerThreshold_mm_Z, 'Tail', 'right');
fprintf('One-sided t-test (H1: mean dZ > %.2f mm)\n', dangerThreshold_mm_Z)
fprintf('t(%d) = %.3f, p = %.4f\n', stats.df, stats.tstat, p)
fprintf('Mean dZ = %.3f mm, 95%% CI lower bound = %.3f mm\n', mean_dZ, ci(1))
if p < 0.05
    fprintf('--> Axial distortion IS significantly greater than the danger threshold.\n')
else
    fprintf('--> Trend exceeds threshold, but not yet statistically significant at current n.\n')
end

% --- Sample size needed to confirm axial distortion EXCEEDS threshold ---
effectSize_d = (mean_dZ - dangerThreshold_mm_Z) / sd_dZ;
fprintf('Observed Cohen''s d relative to danger threshold: %.3f\n', effectSize_d)

nReq_exceed_80 = sampsizepwr('t', [dangerThreshold_mm_Z sd_dZ], mean_dZ, 0.80, [], 'Tail', 'right');
nReq_exceed_90 = sampsizepwr('t', [dangerThreshold_mm_Z sd_dZ], mean_dZ, 0.90, [], 'Tail', 'right');

fprintf('Required n to confirm mean dZ > %.2f mm at 80%% power: %d\n', dangerThreshold_mm_Z, nReq_exceed_80)
fprintf('Required n to confirm mean dZ > %.2f mm at 90%% power: %d\n', dangerThreshold_mm_Z, nReq_exceed_90)

% ==========================================================================
% PROOF: Lateral (Y-axis) focal distortion is SIGNIFICANTLY BELOW the danger threshold
% One-sample, one-sided t-test
% H0: true mean dY >= 1.0 mm (unsafe)
% H1: true mean dY <  1.0 mm (safe)
% ==========================================================================

dangerThreshold_mm_Y = 0.55;
vals_dY = Tmerged.dY(~isnan(Tmerged.dY));   % use Tmerged_rats.dY if filtering to rats only
n_dY = numel(vals_dY);
mean_dY = mean(vals_dY);
sd_dY = std(vals_dY);
sem_dY = sd_dY / sqrt(n_dY);

% One-sided (left-tailed) one-sample t-test against the fixed threshold
[h, p, ci, stats] = ttest(vals_dY, dangerThreshold_mm_Y, 'Tail', 'left', 'Alpha', 0.05);

fprintf('========================================================\n')
fprintf('One-sample one-sided t-test: mean dY < %.2f mm?\n', dangerThreshold_mm_Y)
fprintf('========================================================\n')
fprintf('n = %d\n', n_dY)
fprintf('Mean dY = %.4f mm\n', mean_dY)
fprintf('SD dY   = %.4f mm\n', sd_dY)
fprintf('SEM     = %.4f mm\n', sem_dY)
fprintf('t(%d)   = %.3f\n', stats.df, stats.tstat)
fprintf('p-value = %.3e\n', p)
fprintf('95%% CI upper bound = %.4f mm\n', ci(2))

if h == 1
    fprintf('\n--> REJECT H0: Mean lateral distortion is SIGNIFICANTLY BELOW the %.2f mm danger threshold (p = %.3e).\n', ...
        dangerThreshold_mm_Y, p)
else
    fprintf('\n--> FAIL TO REJECT H0: Not enough evidence that mean lateral distortion is below the threshold.\n')
end

% Effect size (Cohen's d relative to the fixed threshold)
d_vs_threshold = (mean_dY - dangerThreshold_mm_Y) / sd_dY;
fprintf('Cohen''s d (relative to threshold) = %.3f\n', d_vs_threshold)

observedMean_dY = 0.25;
pooledSD_dY = std(Tmerged.dY, 'omitnan');
d_dY_observed = observedMean_dY / pooledSD_dY;
nReq_dY_observed = sampsizepwr('t2', [0 pooledSD_dY], observedMean_dY, 0.80, [], 'Ratio', 1);
fprintf('Required n/group to detect observed mean shift (%.2f mm) at 80%% power: %d\n', ...
    observedMean_dY, nReq_dY_observed)



%==========================================================================
% GROUP COMPARISON: Is %TransLoss significantly different across
% Male Rat / Female Rat / Male Mouse? (TWO-WAY data, '4matlab' sheet)
%==========================================================================

excelFile = 'CT_ImageData_Reorganised.xlsx';
optsTW = detectImportOptions(excelFile, 'Sheet', '4matlab');
Ttw = readtable(excelFile, optsTW);
Ttw.Properties.VariableNames = matlab.lang.makeValidName(Ttw.Properties.VariableNames);
Ttw = Ttw(:,1:6);   % adjust to match your actual sheet layout
Ttw.Properties.VariableNames = {'SampleID','Sex','Weight','SkullThickness','SDR','PctTransLoss'};
Ttw = Ttw(~isnan(Ttw.PctTransLoss), :);

% --- Assign 3-way group label ---
isRat = startsWith(Ttw.SampleID, 'R');
isMouse = startsWith(Ttw.SampleID, 'M');

Group = strings(height(Ttw),1);
Group(isRat & strcmpi(Ttw.Sex,'Male'))   = 'Male Rat';
Group(isRat & strcmpi(Ttw.Sex,'Female')) = 'Female Rat';
Group(isMouse & strcmpi(Ttw.Sex,'Male')) = 'Male Mouse';
Ttw.Group = Group;

% --- Kruskal-Wallis omnibus test (non-parametric, appropriate for small n) ---
[pKW, tblKW, statsKW] = kruskalwallis(Ttw.PctTransLoss, Ttw.Group, 'off');
fprintf('Kruskal-Wallis omnibus test p-value: %.4f\n', pKW)
fprintf('H(%d) = %.3f\n', tblKW{2,3}, tblKW{2,5})

if pKW < 0.05
    fprintf('--> Significant difference detected across groups.\n')
else
    fprintf('--> No significant omnibus difference detected (note: low power likely given small n).\n')
end

% --- Post-hoc pairwise comparisons (Mann-Whitney U with Bonferroni correction) ---
groups = unique(Ttw.Group);
nComparisons = nchoosek(numel(groups), 2);
alphaCorrected = 0.05 / nComparisons;
fprintf('\nBonferroni-corrected alpha threshold (%d comparisons): %.4f\n', nComparisons, alphaCorrected)

fprintf('%-20s %-20s %-10s %-10s %-15s\n', 'Group1','Group2','p-value','Sig?','EffectSize r')
for i = 1:numel(groups)-1
    for j = i+1:numel(groups)
        g1 = groups(i); g2 = groups(j);
        x1 = Ttw.PctTransLoss(Ttw.Group == g1);
        x2 = Ttw.PctTransLoss(Ttw.Group == g2);
        [p, ~, statsRS] = ranksum(x1, x2);
        n1 = numel(x1); n2 = numel(x2);
        z = statsRS.zval;
        if isempty(z), z = NaN; end
        reffect = abs(z) / sqrt(n1+n2);
        sig = "";
        if p < alphaCorrected, sig = "significant"; end
        fprintf('%-20s %-20s %-10.4f %-10s %-15.3f\n', g1, g2, p, sig, reffect)
    end
end

% --- Cohen's d for each pairwise comparison ---
fprintf('\n--- Cohen''s d effect sizes (pairwise) ---\n')
for i = 1:numel(groups)-1
    for j = i+1:numel(groups)
        g1 = groups(i); g2 = groups(j);
        x1 = Ttw.PctTransLoss(Ttw.Group == g1);
        x2 = Ttw.PctTransLoss(Ttw.Group == g2);
        pooledSD = sqrt(((numel(x1)-1)*var(x1) + (numel(x2)-1)*var(x2)) / (numel(x1)+numel(x2)-2));
        d = (mean(x1) - mean(x2)) / pooledSD;
        fprintf('%s vs %s: Cohen''s d = %.2f\n', g1, g2, d)
    end
end

% --- Summary table ---
GroupResults = table();
for i = 1:numel(groups)
    vals = Ttw.PctTransLoss(Ttw.Group == groups(i));
    GroupResults.Group(i) = groups(i);
    GroupResults.N(i) = numel(vals);
    GroupResults.Mean(i) = mean(vals);
    GroupResults.SD(i) = std(vals);
    GroupResults.Median(i) = median(vals);
end
disp(GroupResults)
