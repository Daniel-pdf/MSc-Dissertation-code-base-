% analyzeBurstsBetweenFiles.m
% Usage: set folderPath and tWindow, then run.
folderPath = '/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/RK50_Dir/17June_RK50_Dir_RM/N_RM001_1MPa';
tWindow = [0.050, 0.097];    % time window (same units as t in files)
Ntop = 10;                   % top N peaks per burst

files = dir(fullfile(folderPath, '*.csv'));
nFiles = numel(files);
if nFiles == 0
    error('No CSV files found in %s', folderPath);
end

% Preallocate
meanTop10 = nan(nFiles,1);
maxPeak   = nan(nFiles,1);
tCells = cell(nFiles,1);
vCells = cell(nFiles,1);
fileNames = strings(nFiles,1);

figure('Name','Bursts Overlay');
hold on
colors = lines(nFiles);

for f = 1:nFiles
    fname = fullfile(files(f).folder, files(f).name);
    fileNames(f) = files(f).name;
    % Read file, skip 27 header lines
    fid = fopen(fname,'r');
    if fid < 0
        warning('Could not open %s', fname); continue;
    end
    for k = 1:27, fgetl(fid); end
    data = textscan(fid, '%f%f', 'Delimiter', ',', 'CollectOutput', true);
    fclose(fid);
    M = data{1};
    t = M(:,1);
    v = M(:,2);

    % restrict to tWindow
    idx = (t >= tWindow(1)) & (t <= tWindow(2));
    if ~any(idx)
        warning('File %s has no data in tWindow.', files(f).name);
        continue;
    end
    tW = t(idx);
    vW = v(idx);

    % store for plotting
    tCells{f} = tW;
    vCells{f} = vW;

    % find positive peaks in the window
    try
        [pks, locs] = findpeaks(vW, tW); % returns peak values and times
    catch
        % fallback: simple local maxima (values only)
        pks = [];
        locs = [];
        for ii = 2:numel(vW)-1
            if vW(ii) > vW(ii-1) && vW(ii) >= vW(ii+1)
                pks(end+1,1) = vW(ii); %#ok<SAGROW>
                locs(end+1,1) = tW(ii); %#ok<SAGROW>
            end
        end
    end

    % keep only positive peaks
    posIdx = pks > 0;
    pks = pks(posIdx);
    locs = locs(posIdx);

    if isempty(pks)
        % if no peaks, use maximum value in window (if positive) as single entry
        maxVal = max(vW);
        meanTop10(f) = maxVal;
        maxPeak(f) = maxVal;
    else
        % sort peaks by amplitude descending and take top N
        [pksSorted, order] = sort(pks, 'descend');
        topN = pksSorted(1:min(Ntop, numel(pksSorted)));
        meanTop10(f) = mean(topN);
        maxPeak(f) = max(pks); % largest positive peak
    end

    % plot each burst waveform (aligned by absolute time axis)
    plot(tW, vW, 'Color', colors(mod(f-1,size(colors,1))+1,:), 'LineWidth', 1.2);
end

% finalize plot
xlabel('Time')
ylabel('Voltage')
title(sprintf('Overlay of %d burst waveforms in %s', nFiles, files(1).folder))
legend(cellstr(fileNames), 'Interpreter','none', 'Location','bestoutside')
grid on
hold off

% Print per-burst values
fprintf('\nPer-burst results (within window [%g %g]):\n', tWindow(1), tWindow(2));
T = table(fileNames, meanTop10, maxPeak, 'VariableNames', {'File','MeanTop10','MaxPeak'});
disp(T)

% Compute BETWEEN-burst standard deviations (across files)
std_meanTop10_acrossBursts = std(meanTop10, 'omitnan');
std_maxPeak_acrossBursts  = std(maxPeak, 'omitnan');

fprintf('Between-burst STD of MeanTop10 across %d files: %.6g\n', nFiles, std_meanTop10_acrossBursts);
fprintf('Between-burst STD of MaxPeak  across %d files: %.6g\n', nFiles, std_maxPeak_acrossBursts);

% Percent (CoV) of the BETWEEN-burst standard deviations
mean_meanTop10 = mean(meanTop10, 'omitnan');
mean_maxPeak   = mean(maxPeak, 'omitnan');

pctStd_meanTop10 = (std_meanTop10_acrossBursts / mean_meanTop10) * 100;
pctStd_maxPeak   = (std_maxPeak_acrossBursts / mean_maxPeak) * 100;

fprintf('Between-burst STD of MeanTop10 as %% of mean: %.3f%%\n', pctStd_meanTop10);
fprintf('Between-burst STD of MaxPeak  as %% of mean: %.3f%%\n', pctStd_maxPeak);
