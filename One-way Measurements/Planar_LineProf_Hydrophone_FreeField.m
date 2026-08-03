
% Script to extract and save measured data, apply hydrophone sensitivity,
% extract mag and phase of pressure at fundamental frequency and plot line
% scans
% required toolboxes: k-wave-matlab, bug-measurement-toolbox
% Date: 08/05/2025
% Author: Elly Martin

% Updated: 13/01/2025
% Harriet Lea-Banks

% Update: add path
%addpath FUS_data/
%addpath FUS_data/20251125_550kHz_50cyc_PA4166/
%addpath FUS_data/20251125_550kHz_50cyc_PA4166/Focalwfms/
%addpath bug-measurement-toolbox/toolbox/
%addpath k-Wave/
% Update end
addpath '/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/FUS_data/OneWay_MouseTest'

addpath '/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/bug-measurement-toolbox/toolbox/'
addpath '/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/k-Wave/'
%

clearvars
close all

% set this to the directory containing the scan data - can't remember
% exactly what the name is of current directory!
INPUT_DATA_DIR = {'/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/FUS_data/OneWay_MouseTest'}; %'Y:/ScanData/FUSIntrs/';

%FUS_data/20260113_1p65MHz_PA4166/

% scan and processing parameters
%TRANSDUCER_FREQ = 550e3;  % Hz
TRANSDUCER_FREQ = 165e4;

% tx label - useful to keep track of what you're looking at
f_fig = 'FUSIntrs_1.65MHz_19Dec25';

%FILTER_FREQ = [0.1e6 1e6 0.1e6]; % Hz, [start, end, taper width] % [0.1e6
%2e6 0.1e6] for 1.65MHz 
% ----- Change for 550 and 1,65 ------

FILTER_FREQ = [0.1e6 2e6 0.1e6];

% start sample for time window for whole waveform acquisition
HYDROPHONE = 'PA4166';  % 0.2 mm needle hydrophone 4166 
% set this to the bug-measurement-toolbox/toolbox directory
%SENS_PATH = '/Users/EllyMartin/SynologyDrive/MyDrive/bug-measurement-toolbox/toolbox/';
SENS_PATH = '/Users/danielhawkey/Documents/MATLAB /MATLAB_PROJECT/bug-measurement-toolbox/toolbox/';
% get the hydrophone sensitivity
sensitivity = getHydrophoneSensitivity(HYDROPHONE, SENS_PATH);

% number of cycles in acquisition window - choose a reasonable number, e.g.
% 5 - 10 or so
n_cycles = 5;
% number of ring up cycles - inspect the waveform to determine the ring up
% period

%n_ring = 15; % for 550 kHz

n_ring = 30; %for 1.65 MHz frequency

f_depth = '25mm';
f_power = '2V';

% this will pull the names of all files in that dir, you may want to
% separate them e.g. in x, y and z scans in separate folders - I think this 
% script example deals with X, Y, Z scans all in same folder by looking at
% scan name
% dir_files = dir(INPUT_DATA_DIR);
% ind = [dir_files(:).isdir];
% dir_files = dir_files(ind);
% dir_files = dir_files(3:end);

% volatage settings - something like this
voltage = 1000;
%results = [];
data3db = [];
data6db = [];
filenames = {};

for n = 1%: length(INPUT_DATA_DIR)
  [~, mess] = fileattrib([INPUT_DATA_DIR{1}, '/*.mat']);
   
    h1 = figure;
    h2 = figure;
    % loop through the x, y, z scans
    x_ind = 1; y_ind = 1; z_ind = 1;
    for m = 1:length(mess)
        
        
        % read the waveform
        load(mess(m).Name)
        filename = mess(m).Name;
        %extract the temperature and variation
        data.Temperature(m) = mean(ScanData.Temperature);
        stdvTemp= std(ScanData.Temperature);
        % extract the time step and start time of the acquisition window
        data.dt_meas = ScanData.samplePeriod(1);
        data.t0 = ScanData.startTime;

        % check scan axes for X or Z: 
        if strcmp(ScanData.ScanAxes, 'X')
            
            % get the measurement positions
            data.X = ScanData.posX*1e-3;
            data.Y = mean(ScanData.posY*1e-3);
            Z = abs(ScanData.posZ*1e-3);
            data.Z = mean(Z);
            pos_psp(n) = data.Z;
            % get the scan spatial step size
            data.dx = ScanData.PointSpacing;
            % get the sound speed in water during the scan
            c = waterSoundSpeed(data.Temperature(m));
            % calculate the arrival time of the pulse at the focus
            t_arrival = mean(Z)/c;

        elseif strcmp(ScanData.ScanAxes, 'Y')
            
            % get the measurement positions
            data.X = mean(ScanData.posX*1e-3);
            data.Y = ScanData.posY*1e-3;
            Z = abs(ScanData.posZ*1e-3);
            data.Z = mean(Z);
            data.dy = ScanData.PointSpacing;

        elseif strcmp(ScanData.ScanAxes, 'Z') 
            % get the measurement positions
            Xz = mean(ScanData.posX*1e-3);
            Yz = mean(ScanData.posY*1e-3);
            % deal with the flipped Z axis by flipping the data and taking
            % abs
            data.Z = flip(abs(ScanData.posZ*1e-3), 2); 
            data.dz = ScanData.PointSpacing;
        end
        
        % cut the CW data to a whole number of cycles: 
        % calculate the number of cycles contained in the data
        pts_cycle = 1/(TRANSDUCER_FREQ*data.dt_meas);
        % find the index to cut the data at to get integer cycles
        data_cut = round(n_cycles*pts_cycle);
      
        % calculate approx arrival time and start of window
        % use the position from the X scan Z position
        % find the index of the arrival time using the position of the max 
        % pressure: 
        [~, i_p] = maxND(ScanData.Voltage);
        ind_arrival = (t_arrival - data.t0(i_p(1))) / data.dt_meas;
        % calculate the arrival time of the reflections from the hydrophone
        ind_reflection = (3*t_arrival - data.t0(i_p(1))) / data.dt_meas;
        % calculate the start index of the acquisition window - after 
        % arrival of pulse and ring up time
        i_start = round(ind_arrival + (n_ring * pts_cycle));
        % plot the focal waveform to check we are extracting the signal
        % from a sensible window - add the arrival, start, end and time of
        % arrival of reflections to the plot
        figure(h2)
        plot(ScanData.Voltage(i_p(1), :))

        % perform the FFT, and calculate the plot and add to the frequency
        % array

   
        % 
        % freq = fft(ScanData.Voltage(i_p(1), :));
        % N = length(freq);
        % Fs = 1/ScanData.samplePeriod(1);
        % f = (0:N-1)*(Fs/N);
        % 
        % % single-sided
        % half = 1:floor(N/2)+1;
        % Yss = abs(freq(half)) / N;      % normalize by N
        % Yss(2:end-1) = 2*Yss(2:end-1);        
        % 
        % frequencyAmp(:,m) = Yss;
        % frequency(:,m) = f(half);
        % filenames{end+1} = filename;


        p1 = max(ScanData.Voltage(i_p(1), :));
        p2 = min(ScanData.Voltage(i_p(1), :));
        hold all
        plot([ind_arrival, ind_arrival], [p1, p2], 'b')
        plot([i_start, i_start], [p1, p2], 'k')
        plot([i_start+ data_cut, i_start+ data_cut], [p1, p2], 'k')
        plot([ind_reflection, ind_reflection], [p1, p2], 'r')

        % crop the voltage waveforms 
        data.voltage = ScanData.Voltage(:, i_start : i_start + data_cut);

      
        
        % apply the hydrophone sensitivity: 
        data.pressure = applyCalibration(data.voltage, 1/data.dt_meas, sensitivity, 'Dim', 2, 'FilterParam', FILTER_FREQ);
    
        % look at the focal spectrum

        [frequency(:,m), FFTamp(:,m)] = spect(repmat(data.pressure(i_p(1), :), 1, 10), 1/data.dt_meas);
        filenames{end+1} = filename;

        % extract the amplitude and phase of the pressure at the driving frequency
        % of the transducer - experiment with the padding - might be enough set as
        % default (3) depending on record length of data.
        [p_mag, p_phase] = extractAmpPhase(data.pressure, 1/data.dt_meas, TRANSDUCER_FREQ, 'Dim', 2, 'FFTPadding', 3);
        
        if strcmp(ScanData.ScanAxes, 'X')
            % plot the measured pressure amplitude profile
            figure(h1)
            subplot(1,2,1)
            data.p_magX = p_mag;
            hold all
            plot(data.X*1e3, data.p_magX/1e3)
            
            % calculate the -3dB and -6dB focal width 
            % (0.7 and 0.5 in pressure, 0.5 and 0.25 in intensity)
            data.w_3dB = width3dB(p_mag, data.dx, false);
            data3db(m) = data.w_3dB;
            %
            %
            data.w_6dB = fwhm(p_mag, data.dx, false);
            data6db(m) = data.w_6dB;
            %results(m) = struct('TYPE','X', 'p_magmax',max(data.p_magX),'dB3', data.w_3dB, 'dB6', data.w_6dB, 'filename', filename, 'dB6_start_pos', '', 'dB6_pos_2', '');
           
            % put the data in a struct for 500 kHz
            all_data.(['d_', f_depth]).(['p_',f_power, '_X']).(['scan', num2str(x_ind)]) = data;
            x_ind = x_ind + 1;;
            
           
        elseif strcmp(ScanData.ScanAxes, 'Y')
            figure(h1)
            subplot(1,2,1)
            data.p_magY = p_mag;
            hold all
            plot(data.Y*1e3, data.p_magY/1e3)
            % calculate the -3dB and -6dB focal width 
            % (0.7 and 0.5 in pressure, 0.5 and 0.25 in intensity)
            data.w_3dB = width3dB(p_mag, data.dy, false);

            data3db(m) = data.w_3dB;

            data.w_6dB = fwhm(p_mag, data.dy, false);

            data6db(m) = data.w_6dB;
            %results(m) = struct('TYPE','Y','p_magmax',max(data.p_magY),...
            % 'dB3', data.w_3dB, 'dB6', data.w_6dB, 'filename', filename, ...
            % 'dB6_start_pos', '', 'dB6_pos_2', '');


            % put the data in a struct for 500 kHz
            all_data.(['d_', f_depth]).(['p_',f_power, '_Y']).(['scan',num2str(y_ind)]) = data;
            y_ind = y_ind + 1;
        
        elseif strcmp(ScanData.ScanAxes, 'Z') %&& (m~=9)
            figure(h1);
            subplot(1,2,2)
            data.p_magZ = flip(p_mag, 1);
            hold all
            plot(data.Z*1e3, data.p_magZ/1e3)
            % calculate the -3dB and -6dB focal width 
            % (0.7 and 0.5 in pressure, 0.5 and 0.25 in intensity)
            %offset = data.Z(1)*1e3
            data.w_3dB = width3dB(data.p_magZ, data.Z, false);
            w_3dBz(m) = data.w_3dB;
            try
                [data.w_6dB, edge_pos] = fwhm(data.p_magZ, data.Z, false);
                w_6dBz(m) = data.w_6dB;
            catch
                w_6dBz(m) = 0;
                edge_pos(m) = 0;
            end
            
            % calculate centre of the -6dB focal region (used to define the
            % depth setting on TPO)
            data.centre_6dB = ((edge_pos(2) - edge_pos(1))/2) + edge_pos(1);
            centre_6dBz(m) = data.centre_6dB;
            %results(m) = struct('TYPE','Z','p_magmax',max(data.p_magZ),'dB3', data.w_3dB, 'dB6', data.w_6dB, 'filename', filename, 'dB6_start_pos', edge_pos(1) + offset, 'dB6_pos_2', edge_pos(2)+offset);
            
            % put the data in a struct for 500 kHz
            all_data.(['d_', f_depth]).(['p_',f_power, '_Z']).(['scan', num2str(z_ind)]) = data;
            z_ind = z_ind + 1;
           % store the spatial peak pressure
            p_max(m) = max(data.p_magZ)
            

        end
        
        % results(m) = data;
        clear data
       
    end
    figure(h1)
  subplot(1,2,1)
axis tight
xlabel('Lateral distance [mm]')
ylabel('Pressure amplitude [kPa]')
title([f_fig, ' Lateral Profiles at ', f_depth])
legend({'X scans (lateral)', 'Y scans (lateral)'}, 'Location', 'best')
grid on

    subplot(1,2,2)
axis tight
xlabel('Axial distance [mm]')
ylabel('Pressure amplitude [kPa]')
title([f_fig, ' Axial Profiles at ', f_depth])
legend({'Z scans (axial)'}, 'Location', 'best')
grid on

%    savefig([f_fig, '_profiles_', f_depth])
   
    
end
all_data.p_max = p_max;

% plot the spatial peak pressure amplitude at each voltage setting 
figure
plot(voltage, all_data.p_max/1e3, 'o-','LineWidth',1.2)
xlabel('Drive voltage [mV]')
ylabel('Spatial peak pressure amplitude [kPa]')
title([f_fig, ' Spatial Peak Pressure vs Drive Voltage'])
grid on


%savefig([f_fig, '_voltage_vs_psp'])
  
all_data.mean_psp = mean(all_data.p_max);
all_data.std_psp = std(all_data.p_max);
%all_data.depth_setting = depth_setting;

all_data.axial_w_3dB = w_3dBz;
all_data.axial_w_6dB = w_6dBz;
all_data.lateral_w_3dB = data3db;
all_data.lateral_w_6dB = data6db;
all_data.axial_centre_6dB = centre_6dBz;
all_data.location_psp = pos_psp;




% plot the axial focal length at each depth setting 
figure
plot(voltage, all_data.axial_w_3dB, 'o-')
hold all
plot(voltage, all_data.axial_w_6dB*1e3, 'sq-')
xlabel('Drive voltage [mV]')
ylabel('Axial focal length [mm]')
legend('-3dB', '-6dB')
%savefig([f_fig, '_focal_length_depth', f_depth])

% plot the frequence of the input waveform
vfigure
hold on;
for m = 1 : size(frequency,2)
    plot(frequency(:,m)/1e6, FFTamp(:,m), 'LineWidth', 1.2);
end
xlabel('Frequency (MHz)');
ylabel('Amplitude');
xlim([0,6])
set(gca, 'YScale', 'log');
title('Single-sided Amplitude Spectrum at Focal Position');
grid on;
legend(filenames, 'Interpreter','none', 'Location','best');
hold off;

% save all the processed data and parameters into a .mat file. 
save([f_fig, '.mat'], 'all_data')
