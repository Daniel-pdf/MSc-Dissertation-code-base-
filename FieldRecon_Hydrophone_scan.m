% Edited: 13/01/2026
% Harriet Lea-Banks

clearvars;
close all

% add paths to the Bug-measurement toolbox and k-Wave - change to location
% of these toolboxes in your computer

addpath('k-Wave/')
addpath ('bug-measurement-toolbox/toolbox/')

%
f_fig = 'FUSIntrs_1.65MHz_19Dec25';

% scan and processing parameters
TRANSDUCER_FREQ = 165e4;  % Hz
%TRANSDUCER_FREQ = 550e3;  % Hz
% set the filter parameters to include frequency of interest
FILTER_FREQ = [0.1e6 2e6 5e4]; % Hz, [start, end, taper width]
% set the hydrophone name
HYDROPHONE = 'PA4166';

% set this to the folder containing the sensitivity data in the bug measurement toolbox  
SENS_PATH = '/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/bug-measurement-toolbox/toolbox/'; %'~\bug-measurement-toolbox\toolbox\'; 
dir_data = '/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/FUS_data/OneWay_FFValid/XYscans/'; %'Y:/Transducer/Date_details/';
% set filename of planar scan
FILENAME = {'XYScan_1p65MHz_70cyc_500mV_PA4166_20mm.mat'};
   % 'XYScan_1p65MHz_70cyc_500mV_PA4166_25mm.mat', ...
   % 'XYScan_1p65MHz_70cyc_500mV_PA4166_30mm.mat'}; %'XYScan_xxxx.mat';  


%%
% specification of transducer
diameter = 35e-3; % transducer diameter, [m]
curvature = 21e-3; % radius of curvature, [m] (focal distance (21mm))

%note above

% ring up time - set as required
%t_ring = 16e-6; % 15 cyc
%t_ring = 2.73e-5; %15 cycles @ 550kHz
t_ring = 1.81e-5; % 30 cycles @ 1.65MHz
% number of cycles to analyse
n_cycles = 5;

density = 998; % water density [kg/m^3]
h1 = figure;

FWHM = {};

for n = 1: length(FILENAME)

    % load the ScanData file
    load([dir_data, FILENAME{n}]);
    
    % extract some details from the file
    dt  = ScanData.samplePeriod(1);
    dx = ScanData.PointSpacing(1) * 1e-3;
    temperature = mean(ScanData.Temperature);
    Nx = ScanData.NumberPoints(1);
    Ny = ScanData.NumberPoints(2);
    t0 = ScanData.startTime(1);
     % get the scan position coordinates and use these as a position reference
    x = reshape(ScanData.posX, Nx, Ny)*1e-3;
    x = x(:,1);
    y = reshape(ScanData.posY, Nx, Ny)*1e-3;
    y = y(1,:);
    z = abs(reshape(ScanData.posZ, Nx, Ny))*1e-3;
    z_measurement = mean(z(:));
    c0 = waterSoundSpeed(temperature);
    
    % cut the CW data to a whole number of cycles - set the parameters as required: 
    pts_cycle = round(1/(TRANSDUCER_FREQ*dt));
    data_cut = round(n_cycles*pts_cycle);

    % get the hydrophone sensitivity
    [sensitivity, ~, ~, ~] = getHydrophoneSensitivity(HYDROPHONE, SENS_PATH);
    
    % calculate acquisition window 
    
    % --> Fix this
    [tmin, tmax, ~] = acquisitionWindow(diameter/2, curvature, ...
        z_measurement, temperature, 'CW', 'Plane', 'RingUp', t_ring, 'PlaneSize', single(Nx(1))*dx(1)*1e3); %Nx(1)*dx*1e3);
    
    % plane (max arrival time)
    ind_time_start = length(t0:dt:tmin);
    % time for reflection occurs
    ind_time_max = length(t0:dt:tmax);
    
    
    % ---------------------------------------------------------------
    % FIGURE 2: Voltage waveform at scan centre with time window markers
    % (matches skull script figure 2 exactly)
    % ---------------------------------------------------------------
    V = reshape(ScanData.Voltage, ScanData.NumberPoints(1), ScanData.NumberPoints(2), []);
 
    figure('Name', sprintf('Voltage waveform — %s', FILENAME{n}), 'NumberTitle', 'off');
    plot(squeeze(V(round(Nx/2), round(Ny/2), :)), 'k-', 'LineWidth', 1);
    hold on
    plot([ind_time_start ind_time_start], [-2e-3 2e-3], 'r--', 'LineWidth', 1.5)
    plot([ind_time_max   ind_time_max],   [-2e-3 2e-3], 'k--', 'LineWidth', 1.5)
    hold off
    xlabel('Sample index')
    ylabel('Voltage (V)')
    title(sprintf('Voltage waveform at scan centre — free field (z = %.0f mm)', z_measurement*1e3))
    legend('Waveform', 't_{min} (ring-up end)', 't_{max} (reflection onset)', ...
        'Location', 'best')
    grid on
    
    % --> Check this
    plot(squeeze(V(round(Nx/2), round(Ny/2),:)));
    hold all
    plot([ind_time_start, ind_time_start], [-2e-3, 2e-3], 'r--')
    plot([ind_time_max, ind_time_max], [-2e-3, 2e-3], 'k--')
    title('Voltage Waveform');
    
    % Extract the pressure data and band pass filter according to input limits
    Measured_p = applyCalibration(ScanData.Voltage(:,ind_time_start :ind_time_start + data_cut),...
        1/dt, sensitivity, 'Dim', 2, 'FilterParam', FILTER_FREQ);
    
    % extract the amplitude and phase of the pressure at the driving frequency
    % of the transducer 
    [mag, phase] = extractAmpPhase(Measured_p, 1/dt, TRANSDUCER_FREQ, ...
        'Dim', 2, 'FFTPadding', 3);
    
    % make the input pressure into a complex 2D plane: 
    input_pressure = mag .* exp(1i.* phase);
    % reshape to make 2D
    input_pressure = reshape(input_pressure, Nx, Ny);
    % add some zero padding to expand the grid 
    %========how big the matrix is: bigger means longer processing=========
    pad_sz = 50;
    input_pressure = expandMatrix(input_pressure, pad_sz, 0);

    sz_input = size(input_pressure) * dx;
    x_ex = ((1:size(input_pressure,1)) * dx) - sz_input(1)/2;
    y_ex = ((1:size(input_pressure,2)) * dx) - sz_input(2)/2;

    mag = reshape(mag, Nx, Ny);
    
    %%
    %---------------------------------------------------------------
    % FIGURE 3: Measured pressure magnitude at the scan plane
    % (matches skull script figure 3 exactly)
    % ---------------------------------------------------------------
    figure('Name', sprintf('Measured pressure at scan plane — %s', FILENAME{n}), 'NumberTitle', 'off');
    imagesc(x*1e3, y*1e3, mag')
    axis image
    colorbar
    xlabel('X [mm]')
    ylabel('Y [mm]')
    title(sprintf('Measured pressure magnitude at scan plane — free field (z = %.0f mm)', ...
        z_measurement*1e3))
    colormap(gca, 'cool')
 
    
    
    
    %% project the pressure back to the source
    % this can be done in a number of ways - e.g. using the angular spectrum
    % back to the source and forward again, or using the acoustic field
    % propagator with a mass source
    
    
    % 1. ASA method
    % calculate the plane coincident with the source
    pressure_backward = angularSpectrumCW(input_pressure, dx, ...
            z_measurement, TRANSDUCER_FREQ, c0, 'Reverse', true);
    
    %  calculate forward pressure 
    % e.g. project forward from 1 mm to twice the focal distance in 0.5 mm
    % steps over the same lateral extent as the original scan
    dz = 0.5e-3;
    % --> Check this (dimension mismatch)
    z_projection = 1e-3 : dz : 3 * curvature;
    pressure_forward = angularSpectrumCW(pressure_backward, dx,...
            z_projection, TRANSDUCER_FREQ, c0, 'Reverse', false);
    
    
    
    
  
    
    
    %% the field can be upsampled after projection to increase resolution
    % upsample the pressure - using us factor: 
    us_factor = 2;
    sz_p = size(pressure_forward);
    pressure_us = interpftn(pressure_forward, [sz_p(1) .* us_factor, sz_p(2) * us_factor, sz_p(3)]);
    dx_us = dx/us_factor;
    % redefine the spatial vectors

    x_vec_us = x_ex(1) : dx_us : x_ex(end) + dx_us;
    y_vec_us = y_ex(1) : dx_us : y_ex(end) + dx_us;
    
    [p_max_us(n), indf] = maxND(abs(pressure_us));
    % find the position in space: 
    focal_pos(:,n) = [x_vec_us(indf(1)), y_vec_us(indf(2)), z_projection(indf(3))]; % all in mm
    % find the fwhm in each direction
    field_fwhm(:,n) = [fwhm(squeeze(abs(pressure_us(:, indf(2), indf(3)))), 1000*x_vec_us), ...
        fwhm(squeeze(abs(pressure_us(indf(1), :, indf(3)))), 1000*y_vec_us), ...
        fwhm(squeeze(abs(pressure_us(indf(1), indf(2), :))), 1000*z_projection)];

    
    p_ax(:,n) = squeeze(abs(pressure_us(indf(1), indf(2), :)));

    % find the position of the focus and the peak value: 
    % [p_max, indf] = maxND(abs(pressure_us));
    % plot slices through the focus.
%     figure
%     imagesc(x_vec_us, y_vec_us, squeeze(abs(pressure_us(:,:,indf(3)))))
%     ...
%         imagesc(z_projection, x_vec_us, squeeze(abs(pressure_us(:,indf(2),:))))
%     ...
%         imagesc(z_projection, y_vec_us, squeeze(abs(pressure_us(indf(1),:,:))))
%     subplot(1,3,1)
%     imagesc(x_vec_us*1e3, y_vec_us*1e3, squeeze(abs(pressure_us(:,:,indf(3)))))
% axis image
% xlabel('X [mm]')
% ylabel('Y [mm]')
%     title('projected pressure, focus')
%     subplot(1,3,2)
%     imagesc(z_projection*1e3, x_vec_us*1e3, squeeze(abs(pressure_us(:,indf(2),:))))
% axis image
% xlabel('Z [mm]')
% ylabel('X [mm]')
%     subplot(1,3,3)
%     imagesc(z_projection*1e3, y_vec_us*1e3, squeeze(abs(pressure_us(indf(1),:,:))))
% axis image
% xlabel('Z [mm]')
% ylabel('Y [mm]')
% 
% % --- common color limits and colormap
% maxVal = max(abs(pressure_us(:)));
% if isempty(maxVal) || ~isfinite(maxVal) || maxVal == 0
%     maxVal = 1;
% end
%clim = [0, maxVal];
%cmap = parula;


% define colormap and color limits (handle empty or invalid pressure_us)
cmap = parula;
maxVal = max(abs(pressure_us(:)));
if isempty(maxVal) || ~isfinite(maxVal) || maxVal == 0
    maxVal = 1;
end
clim = [0, maxVal];

% 3-panel figure with labeled colorbars
figure('Name', sprintf('Projected field (XY, XZ, YZ) — %s', FILENAME{n}), 'NumberTitle','off');

% Panel 1: XY plane at Z = indf(3)
subplot(1,3,1)
imagesc(x_vec_us*1e3, y_vec_us*1e3, squeeze(abs(pressure_us(:,:,indf(3))))')
axis image; set(gca,'YDir','normal')
xlabel('X [mm]'); ylabel('Y [mm]')
title('XY at focal Z')
colormap(cmap); caxis(clim)
cb1 = colorbar('eastoutside');
cb1.Label.String = 'Pressure amplitude [Pa]';

% Panel 2: XZ plane at Y = indf(2)
subplot(1,3,2)
imagesc(z_projection*1e3, x_vec_us*1e3, squeeze(abs(pressure_us(:,indf(2),:))))
axis image; set(gca,'YDir','normal')
xlabel('Z [mm]'); ylabel('X [mm]')
title('XZ at focal Y')
colormap(cmap); caxis(clim)
cb2 = colorbar('eastoutside');
cb2.Label.String = 'Pressure amplitude [Pa]';

% Panel 3: YZ plane at X = indf(1)  (Z horizontal, Y vertical)
subplot(1,3,3)
imagesc(z_projection*1e3, y_vec_us*1e3, squeeze(abs(pressure_us(indf(1),:,:))))  % no transpose
axis image
set(gca,'YDir','normal')
xlabel('Z [mm]'); ylabel('Y [mm]')
title('YZ at focal X')
colormap(cmap); caxis(clim)
cb3 = colorbar('eastoutside');
cb3.Label.String = 'Pressure amplitude [Pa]';


 figure(h1)
    plot(z_projection, p_ax(:,n))
    hold on

end

%%
% --- Build table and show in a figure ---
nFiles = numel(p_max_us);
FileIdx = (1:nFiles).';
Peak_Pa   = p_max_us(:);

% focal_pos is in metres — convert to mm
FocalX_mm = (focal_pos(1,:).*1e3).';
FocalY_mm = (focal_pos(2,:).*1e3).';
FocalZ_mm = (focal_pos(3,:).*1e3).';

% field_fwhm is already in mm (computed using 1000*x_vec_us)
FWHM_X_mm = field_fwhm(1,:).';
FWHM_Y_mm = field_fwhm(2,:).';
FWHM_Z_mm = field_fwhm(3,:).';

T_focus = table(FileIdx, Peak_Pa, FocalX_mm, FocalY_mm, FocalZ_mm, ...
    FWHM_X_mm, FWHM_Y_mm, FWHM_Z_mm, ...
    'VariableNames', {'File','Peak_Pa','FocalX_mm','FocalY_mm','FocalZ_mm','FWHM_X_mm','FWHM_Y_mm','FWHM_Z_mm'});


% show in command window (optional)
disp(T_focus)

% show as a GUI table
fTable = figure('Name','Focus Summary','NumberTitle','off','Color','w',...
    'Units','normalized','Position',[0.2 0.2 0.6 0.4]);
uitable(fTable, 'Data', table2cell(T_focus), ...
    'ColumnName', T_focus.Properties.VariableNames, ...
    'RowName', [], 'Units','normalized', 'Position',[0 0 1 1]);

% loading the z scan measured data for plotting

filePath = fullfile('/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT', [f_fig, '.mat']);
if ~exist(filePath, 'file')
    error('File not found: %s', filePath);
end
load(filePath, 'all_data');


for sc = 1: length(fieldnames(all_data.d_25mm.p_2V_Z))
    p = all_data.d_25mm.p_2V_Z.(['scan', num2str(sc)]).p_magZ;
z_scans(1:numel(p), sc) = p;

    
end
mean_magZ = mean(z_scans, 2);
figure(h1)
plot(all_data.d_25mm.p_2V_Z.scan1.Z, mean_magZ, '--')
axis tight
xlabel('Axial distance [m]')
ylabel('Pressure amplitude [Pa]')
legend('20 mm', '25 mm', '30 mm', 'mean measurement')

% In free field script — reconstruct at same z range as skull script
z_projection_comparison = 23.5e-3 : 0.5e-3 : 3*curvature;
pressure_forward_FF_comp = angularSpectrumCW(pressure_backward, dx, ...
    z_projection_comparison, TRANSDUCER_FREQ, c0, 'Reverse', false);
save('freefield_field.mat', 'pressure_forward_FF_comp', 'z_projection_comparison', ...
    'x_ex', 'y_ex', 'x_vec_us', 'y_vec_us', 'p_max_us', 'focal_pos', 'field_fwhm')