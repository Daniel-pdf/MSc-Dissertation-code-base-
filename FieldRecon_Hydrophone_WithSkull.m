% Skull holography: back-project to skull plane, forward-project beyond
% Geometry: transducer @ z=0, skull @ z=z_skull, scan plane @ z=z_measurement

clearvars;
close all

addpath('k-Wave/')
addpath('bug-measurement-toolbox/toolbox/')

%==========================================================================
% CONFIGURATION
%==========================================================================

% scan and processing parameters
TRANSDUCER_FREQ = 165e4;        % Hz
FILTER_FREQ     = [0.1e6 2e6 5e4]; % Hz [start, end, taper width]
HYDROPHONE      = 'PA4166';

SENS_PATH = '/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/bug-measurement-toolbox/toolbox/';
dir_data  = '/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/FUS_data/OneWay_RF3and4/XYScan/';
FILENAME  = {'/XYScan_1p65MHz_70cyc_1500mV_RF4_PA4166_37mm.mat/'};

% transducer geometry
diameter  = 35e-3;   % [m]
curvature = 21e-3;   % radius of curvature / geometric focal distance [m]

% ring up time
t_ring   = 1.81e-5;  % 30 cycles @ 1.65 MHz
n_cycles = 5;

density  = 998;      % water density [kg/m^3]

%--------------------------------------------------------------------------
% KEY GEOMETRY — edit these for each experiment
%--------------------------------------------------------------------------
z_skull = 20e-3;     % axial position of skull (far face, exit surface) [m]
                     % i.e. the last plane that is still free-field water
                     % between skull and hydrophone

% Forward projection range: from just beyond skull to some distal plane.
dz           = 0.5e-3;               % axial step [m]
z_proj_start = z_skull + dz;         % start just past the skull [m]
z_proj_end   = 2 * curvature;        % end of forward projection range [m]
z_projection = z_proj_start : dz : z_proj_end;

% Upsampling factor for final field
us_factor = 2;

%==========================================================================
% PROCESSING LOOP
%==========================================================================

h1 = figure('Name', 'Axial pressure profiles'); hold on;

for n = 1:length(FILENAME)

    %----------------------------------------------------------------------
    % Load and extract scan metadata
    %----------------------------------------------------------------------
    load([dir_data, FILENAME{n}]);

    dt          = ScanData.samplePeriod(1);
    dx          = ScanData.PointSpacing(1) * 1e-3;   % [m]
    % for measurements taken on 31/07/26, broken thermocouple, temperature
    % from early scans was 20.1 degC
    temperature = mean(ScanData.Temperature); %20.1;
    Nx          = ScanData.NumberPoints(1);
    Ny          = ScanData.NumberPoints(2);
    t0          = ScanData.startTime(1);

    x = reshape(ScanData.posX, Nx, Ny) * 1e-3;  x = x(:,1);
    y = reshape(ScanData.posY, Nx, Ny) * 1e-3;  y = y(1,:);
    z = abs(reshape(ScanData.posZ, Nx, Ny)) * 1e-3;
    z_measurement = mean(z(:));                   % scan plane position [m]

    c0 = waterSoundSpeed(temperature);

    fprintf('Scan plane z_measurement = %.1f mm\n', z_measurement * 1e3);
    fprintf('Skull plane z_skull      = %.1f mm\n', z_skull * 1e3);
    fprintf('Back-propagation distance (scan -> skull) = %.1f mm\n', ...
        (z_measurement - z_skull) * 1e3);

    % Sanity check: skull must be between transducer and scan plane
    if z_skull >= z_measurement
        error('z_skull (%.1f mm) must be less than z_measurement (%.1f mm).', ...
            z_skull*1e3, z_measurement*1e3);
    end

    %----------------------------------------------------------------------
    % Acquisition window and waveform check
    %----------------------------------------------------------------------
    pts_cycle = round(1 / (TRANSDUCER_FREQ * dt));
    data_cut  = round(n_cycles * pts_cycle);

    [sensitivity, ~, ~, ~] = getHydrophoneSensitivity(HYDROPHONE, SENS_PATH);

    [tmin, tmax, ~] = acquisitionWindow(diameter/2, curvature, ...
        z_measurement, temperature, 'CW', 'Plane', 'RingUp', t_ring, ...
        'PlaneSize', single(Nx)*dx*1e3);

    ind_time_start = length(t0:dt:tmin);
    ind_time_max   = length(t0:dt:tmax);

    % --- Manual acquisition window override ---
    
    pts_cycle = round(1 / (TRANSDUCER_FREQ * dt));  % ~61 samples per cycle
    fprintf('Samples per cycle: %d\n', pts_cycle)

    %n_cycles_extract = 20;                            % more cycles = better FFT resolution
    %data_cut = round(n_cycles_extract * pts_cycle);   % ~1212 samples

    %ind_time_start = 5771;   % adjust this if needed based on waveform inspection
    % should be well into the flat-top, after ring-up

    % Sanity check: does the window fit within the burst?
    fprintf('Extracting from sample %d to %d\n', ind_time_start, ind_time_start + data_cut)
    fprintf('Burst appears to end around sample 10000 — window end = %d\n', ind_time_start + data_cut)
    if ind_time_start + data_cut > 5000
        warning('Window may extend into burst decay — reduce n_cycles_extract or adjust ind_time_start')
    end

    V = reshape(ScanData.Voltage, Nx, Ny, []);
    figure('Name', sprintf('Voltage waveform — %s', FILENAME{n}), 'NumberTitle','off');
plot(squeeze(V(round(Nx/2), round(Ny/2), :)), 'k-', 'LineWidth', 1);
hold on
plot([ind_time_start ind_time_start], [-4e-3 4e-3], 'r--', 'LineWidth', 1.5)
plot([ind_time_start+data_cut ind_time_start+data_cut], [-4e-3 4e-3], 'b--', 'LineWidth', 1.5)
hold off
xlabel('Sample index'); ylabel('Voltage (V)')
title('Voltage waveform — red = window start, blue = window end')
legend('Waveform', 'Extraction start', 'Extraction end', 'Location','best')
grid on
xlim([0 2e4])  % zoom to the burst region

    %----------------------------------------------------------------------
    % Calibrate and extract amplitude/phase at transducer frequency
    %----------------------------------------------------------------------
    % time window now set to wirk backwards from the max arrival time which
    % corresponds to arrival of reflections in free field, so just an
    % estimate here. 
%     start_idx = max(1, round(ind_time_max - data_cut + 1));
% Measured_p = applyCalibration( ...
%     ScanData.Voltage(:, start_idx : round(ind_time_max)), ...
%     1/dt, sensitivity, 'Dim', 2, 'FilterParam', FILTER_FREQ);

Measured_p = applyCalibration(...
    ScanData.Voltage(:, ind_time_start : ind_time_start + data_cut), ...
    1/dt, sensitivity, 'Dim', 2, 'FilterParam', FILTER_FREQ);


    [mag, phase] = extractAmpPhase(Measured_p, 1/dt, TRANSDUCER_FREQ, ...
        'Dim', 2, 'FFTPadding', 3);

    % Complex pressure at the scan plane
    input_pressure = mag .* exp(1i .* phase);
    input_pressure = reshape(input_pressure, Nx, Ny);

    % Zero-pad to reduce edge artefacts
    pad_sz         = 50;
    input_pressure = expandMatrix(input_pressure, pad_sz, 0);

    sz_input = size(input_pressure) * dx;
    x_ex = ((1:size(input_pressure,1)) * dx) - sz_input(1)/2;
    y_ex = ((1:size(input_pressure,2)) * dx) - sz_input(2)/2;

    % Plot measured pressure magnitude at scan plane
    mag = reshape(mag, Nx, Ny);
    figure('Name', 'Measured pressure at scan plane');
    imagesc(x*1e3, y*1e3, mag'); axis image; colorbar
    xlabel('X [mm]'); ylabel('Y [mm]')
    title(sprintf('Measured pressure magnitude at scan plane (z = %.0f mm)', ...
        z_measurement*1e3))

    %----------------------------------------------------------------------
    % STAGE 1: Back-project from scan plane to skull exit surface
    %
    %   Distance = z_measurement - z_skull  (free-field water gap only)
    %   This is valid because the medium between skull and hydrophone
    %   is homogeneous water — the angular spectrum assumptions hold.
    %   We do NOT back-project through the skull.
    %----------------------------------------------------------------------
    %back_distance = z_measurement - z_skull;   % e.g. 32mm - 25mm = 7mm

    %fprintf('Back-projecting %.1f mm (scan plane to skull exit face)...\n', ...
     %   back_distance * 1e3);
    
     z_back_projection = (0 : dz : z_measurement - z_skull);

    pressure_back = angularSpectrumCW(input_pressure, dx, ...
        z_back_projection, TRANSDUCER_FREQ, c0, 'Reverse', true);

  
    %----------------------------------------------------------------------
    % STAGE 2: Forward-project from skull plane into the post-skull field
    %
    %   Starting from z_skull, project forward through free-field water.
    %   This gives you the field from just past the skull to z_proj_end.
    %   Distances beyond the focus (> curvature) show the diverging beam.
    %----------------------------------------------------------------------
    fprintf('Forward-projecting from skull plane (%.1f mm) to %.1f mm...\n', ...
        z_skull*1e3, z_proj_end*1e3);
    
    z_for_projection = (0 : dz : 30e-3);

    pressure_forward = angularSpectrumCW(input_pressure, dx, ...
        z_for_projection, TRANSDUCER_FREQ, c0, 'Reverse', false);

% concatenate the forward and backwards pressure volumes
p_all = cat(3, pressure_back(:,:,1:end-1), pressure_forward);
z_all = z_measurement + cat(2, flip(-z_back_projection(2:end),2), z_for_projection);
% find the max pressure
[p_max, ind_max_all] = maxND(abs(p_all));

% canonical axes in mm
x_mm = x_ex * 1e3;
y_mm = y_ex * 1e3;
z_mm = z_all * 1e3;

ix = ind_max_all(1); iy = ind_max_all(2); iz = ind_max_all(3);

slice_YZ = squeeze(abs(p_all(ix,:,:)));   % Ny x Nz
slice_XZ = squeeze(abs(p_all(:,iy,:)));   % Nx x Nz
slice_XY = squeeze(abs(p_all(:,:,iz)));   % Nx x Ny

  % ensure clim is a valid 2-element increasing numeric vector
  mx = max(slice_YZ(:));
  if isempty(mx) || ~isfinite(mx)
      mx = 1;        % fallback magnitude
  elseif mx <= 0
      mx = eps;      % ensure positive upper limit
  end
  clim = [0, mx];

% --- Use canonical slices/axes created earlier:
% x_mm, y_mm, z_mm, slice_YZ, slice_XZ, slice_XY, clim, cmap

% 3-panel figure using same conventions and same color scaling
figure('Name', sprintf('Projected field (XY, XZ, YZ) — %s', FILENAME{n}), 'NumberTitle','off');

% Panel 1: XY plane at Z = iz (X horizontal, Y vertical)
subplot(1,3,1)
imagesc(x_mm, y_mm, slice_XY')   % transpose so cols->X, rows->Y
axis image
set(gca,'YDir','normal')
xlabel('X [mm]'); ylabel('Y [mm]')
title(sprintf('XY at Z = %.2f mm', z_mm(iz)))
cmap = parula(256);
colormap(cmap); colorbar; caxis(clim)

% Panel 2: XZ plane at Y = iy (Z horizontal, X vertical)
subplot(1,3,2)
imagesc(z_mm, x_mm, slice_XZ)    % cols->Z, rows->X
axis image
set(gca,'YDir','normal')
xlabel('Z [mm]'); ylabel('X [mm]')
title(sprintf('XZ at Y = %.2f mm', y_mm(iy)))
colormap(cmap); colorbar; caxis(clim)
%xline(23, '--k', 'label', 'Skull'); 
hold off

% Panel 3: YZ plane at X = ix (identical to Projected field1)
subplot(1,3,3)
imagesc(z_mm, y_mm, slice_YZ)    % same call as Projected field1
axis image
set(gca,'YDir','normal')
xlabel('Z [mm]'); ylabel('Y [mm]')
title(sprintf('YZ at X = %.2f mm (canonical)', x_mm(ix)))
colormap(cmap); colorbar; caxis(clim)
%xline(23, '--k', 'label', 'Skull'); 
hold off

figure('Name', sprintf('Projected field1 — %s', FILENAME{n}))
imagesc(squeeze(abs(p_all(ind_max_all(1),:,:))))
axis image

% figure('Name', sprintf('Projected field1 — %s', FILENAME{n}))
% imagesc(z_mm, y_mm, squeeze(abs(p_all(ind_max_all(1),:,:))))
% set(gca,'YDir','normal')   % make Y increase upward
% axis image
% xlabel('Z [mm]'); ylabel('Y [mm]');


   % Plot pressure magnitude immediately after the skull (skull exit surface)
figure('Name', sprintf('Pressure at skull exit (z = %.1f mm)', z_skull*1e3));
imagesc(x_ex*1e3, y_ex*1e3, abs(p_all(:,:,1))'); axis image; colorbar
xlabel('X [mm]'); ylabel('Y [mm]')
title(sprintf('Pressure magnitude at skull exit surface (z = %.1f mm)', z_skull*1e3))

    %----------------------------------------------------------------------
    % Upsample the projected field for better spatial resolution
    %----------------------------------------------------------------------
    sz_p        = size(p_all);
    pressure_us = interpftn(p_all, ...
        [sz_p(1)*us_factor, sz_p(2)*us_factor, sz_p(3)]);
    dx_us = dx / us_factor;

    x_vec_us = x_ex(1) : dx_us : x_ex(end) + dx_us;
    y_vec_us = y_ex(1) : dx_us : y_ex(end) + dx_us;

    % Find peak pressure and its location
    [p_max_us(n), indf] = maxND(abs(pressure_us));

    %focal_pos(:,n) = [x_vec_us(indf(1)), y_vec_us(indf(2)), z_projection(indf(3))];
    % z_all is the axial vector for p_all; build upsampled z vector to match pressure_us
    z_us = interp1(1:numel(z_all), z_all, linspace(1,numel(z_all), size(pressure_us,3)));
    focal_pos(:,n) = [x_vec_us(indf(1)), y_vec_us(indf(2)), z_us(indf(3))];

    % Safe FWHM calculation — catches cases where the profile doesn't fall
    % to half-max within the projection range (common with skull aberration)
    fwhm_x = safeFWHM(squeeze(abs(pressure_us(:, indf(2), indf(3)))), 1000*x_vec_us, 'X');
    fwhm_y = safeFWHM(squeeze(abs(pressure_us(indf(1), :, indf(3)))), 1000*y_vec_us, 'Y');
    fwhm_z = safeFWHM(squeeze(abs(pressure_us(indf(1), indf(2), :))), 1000*z_projection, 'Z (axial)');
    field_fwhm(:,n) = [fwhm_x; fwhm_y; fwhm_z];

    p_ax(:,n) = squeeze(abs(pressure_us(indf(1), indf(2), :)));


    % Axial profile
    figure(h1)
    plot(z_all*1e3, p_ax(:,n), 'DisplayName', FILENAME{n})
    xline(z_skull*1e3, '--k', 'Skull', 'LabelVerticalAlignment','bottom')
    xline(curvature*1e3, '--r', 'Geometric focus', 'LabelVerticalAlignment','bottom')

end

%--------------------------------------------------------------------------
% Summary table
%--------------------------------------------------------------------------
nFiles    = numel(p_max_us);
FileIdx   = (1:nFiles).';
Peak_Pa   = p_max_us(:);

FocalX_mm = (focal_pos(1,:).*1e3).';
FocalY_mm = (focal_pos(2,:).*1e3).';
FocalZ_mm = (focal_pos(3,:).*1e3).';

FWHM_X_mm = field_fwhm(1,:).';
FWHM_Y_mm = field_fwhm(2,:).';
FWHM_Z_mm = field_fwhm(3,:).';

T_focus = table(FileIdx, Peak_Pa, FocalX_mm, FocalY_mm, FocalZ_mm, ...
    FWHM_X_mm, FWHM_Y_mm, FWHM_Z_mm, ...
    'VariableNames', {'File','Peak_Pa','FocalX_mm','FocalY_mm','FocalZ_mm', ...
                      'FWHM_X_mm','FWHM_Y_mm','FWHM_Z_mm'});

disp(T_focus)

fTable = figure('Name','Focus Summary','NumberTitle','off','Color','w', ...
    'Units','normalized','Position',[0.2 0.2 0.6 0.4]);
uitable(fTable, 'Data', table2cell(T_focus), ...
    'ColumnName', T_focus.Properties.VariableNames, ...
    'RowName', [], 'Units','normalized', 'Position',[0 0 1 1]);

% Finalise axial figure
figure(h1)
axis tight
xlabel('Axial distance from transducer [mm]')
ylabel('Pressure amplitude [Pa]')
title('Axial pressure profile (post-skull field)')
legend('show')

%==========================================================================
% LOCAL FUNCTIONS
%==========================================================================

function val = safeFWHM(profile, coords, label)
% SAFEFWHM  Wrapper around fwhm() that catches the 'half maximum not found'
% error and returns NaN with a warning instead of crashing.
% This happens when the projection range is too short for the profile to
% fall to half its peak — common in the axial (Z) direction with a skull.
    try
        val = fwhm(profile, coords);
    catch ME
        warning('FWHM not found for %s profile: %s — returning NaN. Consider extending z_proj_end.', ...
            label, ME.message);
        val = NaN;
    end
end

fprintf('dt = %.3e s\n', dt)
fprintf('tmin = %.3e s,  ind_time_start = %d\n', tmin, ind_time_start)
fprintf('tmax = %.3e s,  ind_time_max   = %d\n', tmax, ind_time_max)
fprintf('data_cut = %d samples (%.1f cycles)\n', data_cut, n_cycles)
fprintf('Window duration = %d samples = %.2e s\n', ...
    ind_time_max - ind_time_start, (ind_time_max - ind_time_start)*dt)

