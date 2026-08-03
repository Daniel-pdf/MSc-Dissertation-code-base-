%==========================================================================
% CONFIGURATION — edit this block to point at a new dataset
%==========================================================================

% Base directory containing all experiment subfolders
baseDir = '/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/RK50_Dir';

% Subfolder names for each species group (Needle only)
N_dirs = struct( ...
    'RM', '17June_RK50_Dir_RM', ...
    'RF', '19June_RK50_Dir_RF', ...
    'MM', '22June_RK50_Dir_MM'  ...
);

% Subfolder names for each species group (Needle + Skull)
NS_dirs = struct( ...
    'RM', '03July_RK50_Dir_DGRM', ...
    'RF', '06July_RK50_Dir_DGRF', ...
    'MM', '08July_RK50_Dir_DGMM'  ...
);

% Toggle behavior:
% false = original (each specimen uses its own N); true = use one reference N for all comparisons
useSingleNReference = true;

% If useSingleNReference == true choose which group and specimen to use as the reference:
% group index (1..nGroups) and specimen index (1..nSpecimens)
refGroup = 1;
refSpecimen = 5;

% Manual override for the N reference (used when useSingleNReference == true)
manualOverrideN = true;                       % set true to override refGroup/refSpecimen
manualNFolder =  '/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/RK50_Dir/17June_RK50_Dir_RM/N_RM005_1MPa/'; % full folder path to the desired N folder


% Folder name templates for each specimen within a group
% {species_tag}{run_number}_1MPa  e.g. N_RM001_1MPa, NS_RF004_1MPa
N_prefix  = 'N';   % prefix for needle-only folders
NS_prefix = 'NS';  % prefix for needle+skull folders

% Species tags as they appear in folder names
species_tags = {'RM','RF','MM'};

% Number of header lines to skip in each CSV file
nHeaderLines = 27;

% Number of specimens per group
nSpecimens = 6;

% Time window for peak analysis (ms)
tWindow = [0.043, 0.097];

% Zoomed x-axis limits for individual waveform comparison plots (ms)
zoomLim = [0.043, 0.097];

%==========================================================================
% END CONFIGURATION — do not need to edit below this line
%==========================================================================

%--------------------------------------------------------------------------
% LOAD ALL WAVEFORMS
% Needle only:    tN_data{group}{specimen},  vN_data{group}{specimen}
% Needle + Skull: tNS_data{group}{specimen}, vNS_data{group}{specimen}
%--------------------------------------------------------------------------

nGroups = numel(species_tags);

tN_data  = cell(nGroups, nSpecimens);
vN_data  = cell(nGroups, nSpecimens);
tNS_data = cell(nGroups, nSpecimens);
vNS_data = cell(nGroups, nSpecimens);

for g = 1:nGroups
    tag = species_tags{g};

    for s = 1:nSpecimens

        % --- Needle only ---
        folderName = sprintf('%s_%s%03d_1MPa', N_prefix, tag, s);
        folderPath = fullfile(baseDir, N_dirs.(tag), folderName);
        [tN_data{g,s}, vN_data{g,s}] = loadAveragedWaveform(folderPath, nHeaderLines);

        % --- Needle + Skull ---
        folderName = sprintf('%s_%s%03d_1MPa', NS_prefix, tag, s);
        folderPath = fullfile(baseDir, NS_dirs.(tag), folderName);
        [tNS_data{g,s}, vNS_data{g,s}] = loadAveragedWaveform(folderPath, nHeaderLines);

    end
    fprintf('Loaded group %s (%d N + %d NS waveforms)\n', tag, nSpecimens, nSpecimens);
end

%--------------------------------------------------------------------------
% INDIVIDUAL WAVEFORM COMPARISON FIGURES (N vs NS per specimen)
% Each specimen gets two figures: full waveform + zoomed window
%--------------------------------------------------------------------------

% groupColours = {'r', 'b', 'k'};  % one colour per species group if needed
% 
% for g = 1:nGroups
%     tag = species_tags{g};
%     for s = 1:nSpecimens
%         label = sprintf('%s%03d', tag, s);
% 
%         % Full waveform
%         figure('Name', sprintf('N vs NS — %s', label), 'NumberTitle', 'off');
%         plot(tN_data{g,s},  vN_data{g,s},  'r-', 'LineWidth', 1.5); hold on
%         plot(tNS_data{g,s}, vNS_data{g,s}, 'b-', 'LineWidth', 1.5); hold off
%         xlabel('Time (ms)'); ylabel('Average Voltage (mV)')
%         title(sprintf('N vs NS for %s', label))
%         legend('N', 'NS'); grid on
% 
%         % Zoomed window
%         figure('Name', sprintf('N vs NS — %s (zoom)', label), 'NumberTitle', 'off');
%         plot(tN_data{g,s},  vN_data{g,s},  'r-', 'LineWidth', 1.5); hold on
%         plot(tNS_data{g,s}, vNS_data{g,s}, 'b-', 'LineWidth', 1.5); hold off
%         xlim(zoomLim)
%         xlabel('Time (ms)'); ylabel('Average Voltage (mV)')
%         title(sprintf('N vs NS for %s (zoomed)', label))
%         legend('N', 'NS'); grid on
%     end
% end
%--------------------------------------------------------------------------
% PEAK ANALYSIS: top-10 mean and abs max, N vs NS, per specimen
%--------------------------------------------------------------------------

% Flatten cell arrays into ordered lists matching specimen labels
specimenLabels = strings(nGroups * nSpecimens, 1);
speciesPrefix  = strings(nGroups * nSpecimens, 1);
tN_flat  = cell(1, nGroups * nSpecimens);
vN_flat  = cell(1, nGroups * nSpecimens);
tNS_flat = cell(1, nGroups * nSpecimens);
vNS_flat = cell(1, nGroups * nSpecimens);

% If manual override requested, load the specified N folder as the single reference
if exist('manualOverrideN','var') && manualOverrideN
    if ~isfolder(manualNFolder)
        error('manualNFolder does not exist: %s', manualNFolder);
    end
    fprintf('Manual override: using N reference from folder:\n  %s\n', manualNFolder);
    [trefN, vrefN] = loadAveragedWaveform(manualNFolder, nHeaderLines);
    if isempty(trefN) || isempty(vrefN)
        error('Failed to load waveform from manualNFolder: %s', manualNFolder);
    end
    % Force useSingleNReference so downstream code will use trefN
    useSingleNReference = true;
end


% If using a single N reference, capture the reference data now
if useSingleNReference
    % If manual override was used and load succeeded, don't overwrite trefN/vrefN
    if exist('manualOverrideN','var') && manualOverrideN && exist('trefN','var') && ~isempty(trefN)
        % manual trefN/vrefN already loaded above — keep it
        fprintf('Using manualNFolder as reference: %s\n', manualNFolder);
    else
        % Validate indices and use tN_data as reference
        if refGroup < 1 || refGroup > nGroups || refSpecimen < 1 || refSpecimen > nSpecimens
            error('refGroup/refSpecimen out of range');
        end
        trefN = tN_data{refGroup, refSpecimen};
        vrefN = vN_data{refGroup, refSpecimen};
    end
end


idx = 1;
for g = 1:nGroups
    tag = species_tags{g};
    for s = 1:nSpecimens
        specimenLabels(idx) = sprintf('%s%03d', tag, s);
        speciesPrefix(idx)  = tag;

        if useSingleNReference
            % Use chosen reference N for every comparison
            tN_flat{idx} = trefN;
            vN_flat{idx} = vrefN;
        else
            % Original behaviour: use the specimen's own N data
            tN_flat{idx} = tN_data{g,s};
            vN_flat{idx} = vN_data{g,s};
        end

        % Always use the actual NS data for each specimen
        tNS_flat{idx} = tNS_data{g,s};
        vNS_flat{idx} = vNS_data{g,s};

        idx = idx + 1;
    end
end

nPairs = nGroups * nSpecimens;

[meanTop10_N,  ~, absMax_N]  = analyzeWindow(tN_flat,  vN_flat,  tWindow);
[meanTop10_NS, ~, absMax_NS] = analyzeWindow(tNS_flat, vNS_flat, tWindow);

x = 1:nPairs;

%--------------------------------------------------------------------------
% FIGURE A: Mean of Top10 Positive Peaks — N vs NS, per specimen
%--------------------------------------------------------------------------
figure('Name', 'MeanTop10: N vs NS per specimen', 'NumberTitle', 'off');
hold on
for k = 1:nPairs
    plot([x(k) x(k)], [meanTop10_N(k) meanTop10_NS(k)], '-', ...
        'Color', [0.6 0.6 0.6], 'LineWidth', 1.2);
end
p1 = scatter(x, meanTop10_N,  60, 'r', 'filled', 'DisplayName', 'N');
p2 = scatter(x, meanTop10_NS, 60, 'b', 's', 'filled', 'DisplayName', 'NS');
hold off
xlabel('Specimen')
ylabel('Mean of Top10 Positive Peaks (mV)')
title(sprintf('Mean of Top10 Positive Peaks: N vs NS (window %.3f–%.3f ms)', tWindow(1), tWindow(2)))
legend([p1 p2], 'Location', 'best')
xticks(x); xticklabels(specimenLabels); xtickangle(45)
grid on

%--------------------------------------------------------------------------
% FIGURE B: Absolute Maximum Positive Peak — N vs NS, per specimen
%--------------------------------------------------------------------------
% figure('Name', 'AbsMaxPeak: N vs NS per specimen', 'NumberTitle', 'off');
% hold on
% for k = 1:nPairs
%     plot([x(k) x(k)], [absMax_N(k) absMax_NS(k)], '-', ...
%         'Color', [0.6 0.6 0.6], 'LineWidth', 1.2);
% end
% p3 = scatter(x, absMax_N,  60, 'r', 'filled', 'DisplayName', 'N');
% p4 = scatter(x, absMax_NS, 60, 'b', 's', 'filled', 'DisplayName', 'NS');
% hold off
% xlabel('Specimen')
% ylabel('Max Positive Peak (mV)')
% title(sprintf('Maximum Positive Peak: N vs NS (window %.3f–%.3f ms)', tWindow(1), tWindow(2)))
% legend([p3 p4], 'Location', 'best')
% xticks(x); xticklabels(specimenLabels); xtickangle(45)
% grid on

%--------------------------------------------------------------------------
% SUMMARY TABLE: N vs NS per specimen, both metrics
%--------------------------------------------------------------------------
NvsNSPeakComparisonTable = table( ...
    specimenLabels, speciesPrefix, ...
    meanTop10_N(:), meanTop10_NS(:), (meanTop10_NS(:) - meanTop10_N(:)), ...
    'VariableNames', {'Specimen', 'Group', ...
                      'N_MeanTop10_mV',  'NS_MeanTop10_mV',  'Delta_MeanTop10_mV'}); ...
                      %'N_AbsMax_mV',     'NS_AbsMax_mV',     'Delta_AbsMax_mV'});
%absMax_N(:),    absMax_NS(:),    (absMax_NS(:)    - absMax_N(:)), ...

% Add percent-change columns (relative to N)
Delta_MeanTop10 = NvsNSPeakComparisonTable.Delta_MeanTop10_mV;
%Delta_AbsMax    = NvsNSPeakComparisonTable.Delta_AbsMax_mV;
N_mean_vals     = NvsNSPeakComparisonTable.N_MeanTop10_mV;
%N_abs_vals      = NvsNSPeakComparisonTable.N_AbsMax_mV;

% avoid divide-by-zero
pctMean = 100 * Delta_MeanTop10 ./ N_mean_vals;
%pctMax  = 100 * Delta_AbsMax    ./ N_abs_vals;
pctMean(~isfinite(pctMean)) = NaN;
%pctMax(~isfinite(pctMax))   = NaN;

% append to table and printable summary
NvsNSPeakComparisonTable.Delta_MeanTop10_pct = pctMean;
%NvsNSPeakComparisonTable.Delta_AbsMax_pct    = pctMax;

fprintf('\nN vs NS Peak Comparison Table (window %.3f–%.3f ms):\n', tWindow(1), tWindow(2));
disp(NvsNSPeakComparisonTable)

writetable(NvsNSPeakComparisonTable, 'N_vs_NS_PeakComparison.csv');
fprintf('Table saved to N_vs_NS_PeakComparison.csv\n');


%==========================================================================
% LOCAL FUNCTIONS
%==========================================================================

function [tAvg, vAvg] = loadAveragedWaveform(folderPath, nHeaderLines)
% LOADAVERAGEDWAVEFORM  Read all CSVs in folderPath, skip nHeaderLines,
% and return the time vector and voltage average across all files.
    files = dir(fullfile(folderPath, '*.csv'));
    if isempty(files)
        warning('No CSV files found in: %s', folderPath);
        tAvg = []; vAvg = []; return
    end
    nFiles = numel(files);

    % Read first file to get time vector and initialise sum
    fid = fopen(fullfile(files(1).folder, files(1).name), 'r');
    for i = 1:nHeaderLines, fgetl(fid); end
    raw = textscan(fid, '%f%f', 'Delimiter', ',', 'CollectOutput', true);
    fclose(fid);
    M = raw{1};
    tAvg = M(:,1);
    vSum = M(:,2);

    % Accumulate remaining files
    for k = 2:nFiles
        fid = fopen(fullfile(files(k).folder, files(k).name), 'r');
        for i = 1:nHeaderLines, fgetl(fid); end
        raw = textscan(fid, '%f%f', 'Delimiter', ',', 'CollectOutput', true);
        fclose(fid);
        vSum = vSum + raw{1}(:,2);
    end
    vAvg = vSum / nFiles;
end

function [meansTop10, stdTop10, absMaxPeak] = analyzeWindow(tCells, vCells, tWindow)
% ANALYZEWINDOW  For each waveform, find the top 10 positive peaks within
% tWindow and return their mean, std, and the absolute maximum peak.
    nRuns = numel(tCells);
    meansTop10 = nan(nRuns,1);
    stdTop10   = nan(nRuns,1);
    absMaxPeak = nan(nRuns,1);

    for i = 1:nRuns
        t = tCells{i}; v = vCells{i};
        if isempty(t) || isempty(v) || numel(t) ~= numel(v), continue; end

        mask = (t >= tWindow(1)) & (t <= tWindow(2));
        if ~any(mask), continue; end
        vWin = v(mask);

        try
            [pks, ~] = findpeaks(vWin);
        catch
            pks = [];
            for k = 2:numel(vWin)-1
                if vWin(k) > vWin(k-1) && vWin(k) >= vWin(k+1)
                    pks(end+1) = vWin(k); %#ok<AGROW>
                end
            end
        end
        pks = pks(pks > 0);

        if isempty(pks)
            maxVal = max(vWin);
            if maxVal > 0
                absMaxPeak(i) = maxVal;
                meansTop10(i) = maxVal;
                stdTop10(i)   = 0;
            end
            continue
        end

        absMaxPeak(i) = max(pks);
        pksSorted = sort(pks, 'descend');
        topPks = pksSorted(1:min(10, numel(pksSorted)));
        meansTop10(i) = mean(topPks);
        stdTop10(i)   = std(topPks, 1);
    end
end
