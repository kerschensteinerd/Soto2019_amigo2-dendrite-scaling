% MEA Analysis Configuration File
%
% This is an example configuration file. Copy this to config.m and modify
% for your specific experimental setup.
%
% Usage:
%   1. Copy this file: config_example.m -> config.m
%   2. Edit config.m with your experiment-specific values
%   3. Load in your analysis scripts: run('config.m')

%% TTL Pulse Detection (dsParser.m)

% Voltage thresholds for TTL pulse detection
% Adjust these based on your recording system's TTL pulse voltages
config.ttl_first_threshold = 2980;    % Threshold for first TTL pulse
config.ttl_last_threshold = 3990;     % Threshold for last TTL pulse

% Analog channel indices containing TTL pulse timestamps
% These channels will be removed from spike data after parsing
config.analog_channels = [1 2];       % Columns in spike data with TTL pulses

%% Direction Selectivity Analysis (dsAnalyzer.m)

% Minimum firing rate (Hz) for including a cell in DS analysis
% Cells with max firing rate below this threshold are classified as non-DS
config.rate_threshold = 4;

% Direction selectivity index (DSI) threshold for DSGC classification
% Range: 0 (non-selective) to 1 (perfectly selective)
% Typical values: 0.2-0.4
config.dsi_threshold = 0.3;

% Number of preferred directions to index per cell
% Typically 1 for standard DSGC analysis
config.n_dirs = 1;

% Speed index for determining preferred direction
% Index into stimIn.speed array
config.speed_index = 1;

% Wavelength indices for determining preferred direction
% Indices into stimIn.wavelength array
config.wavelength_indices = 2:3;

%% Array Geometry (nexread.m)

% Array type identifier
% Used for documentation purposes
config.array_type = '252-electrode MEA';

% Apply coordinate transformation
% Set to false if using a different array geometry
config.apply_coordinate_transform = true;

%% Processing Options

% Display progress indicators (waitbars, etc.)
config.show_progress = true;

% Verbose logging to console
config.verbose = true;

%% Notes

% TTL Threshold Calibration:
% - Plot your TTL channels to determine appropriate thresholds:
%     sp = nexread('your_file.txt');
%     figure; plot(sp.data(:,1), 'r.'); hold on; plot(sp.data(:,2), 'b.');
%     title('TTL Pulses'); xlabel('Sample'); ylabel('Voltage');
% - Thresholds should be between baseline and peak TTL voltages

% Direction Selectivity Thresholds:
% - rate_threshold: Typical range 2-10 Hz depending on cell type
% - dsi_threshold: 0.3 is standard from Soto et al. 2019
%   - More stringent: 0.4-0.5
%   - Less stringent: 0.2-0.25

% Array Geometry:
% - If using a different MEA layout, modify coordinate transformation
%   logic in nexread.m lines 48-58
