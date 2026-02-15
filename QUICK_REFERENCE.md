# Quick Reference Guide

## Analysis Workflow

```
Neuroexplorer Data → nexread.m → dsParser.m → dsAnalyzer.m → Results
```

## Data Structures

### Spike Data (sp)
```matlab
sp.data       % Matrix [n_spikes × n_channels] of timestamps (seconds)
sp.channels   % Cell array of channel names {'A01', 'B02', ...}
sp.nchan      % Number of channels
sp.x, sp.y    % Electrode coordinates on array
```

### Stimulus Data (required in MAT file)

**DS_IN** (input parameters):
```matlab
DS_IN.direction  % [0, 45, 90, 135, 180, 225, 270, 315]  degrees
DS_IN.speed      % [100, 200, 400]  units/sec
DS_IN.duration   % 2  seconds per stimulus
DS_IN.nRepeats   % 5  number of repetitions
```

**DS_OUT** (presentation sequence):
```matlab
DS_OUT.direction    % [0, 90, 180, ...] one per trial
DS_OUT.speed        % [100, 100, 200, ...] one per trial  
DS_OUT.wavelength   % [50, 100, 50, ...] one per trial
```

### Parsed Data (ds)
```matlab
ds(i).channel           % Channel identifier
ds(i).drift(d,s,w)      % Spikes for direction d, speed s, wavelength w
  .spikes               % Spike times relative to stimulus onset (concatenated repeats)
```

### Analyzed Data (ds, after dsAnalyzer)
```matlab
ds(i).rate(d,s,w)   % Firing rate (Hz) for each condition
ds(i).dsi(s,w)      % Direction selectivity index [0-1]
ds(i).pref(s,w)     % Preferred direction (degrees, 0-360)
ds(i).type          % 'DS' or 'non-DS'
ds(i).prefIdx       % Index of preferred direction
ds(i).nullIdx       % Index of null direction (opposite of preferred)
```

## Key Formulas

### Firing Rate
```matlab
rate = spike_count / (duration * nRepeats)
```

### Direction Selectivity Index (DSI)
```matlab
% Using circular variance
directions_rad = deg2rad([0, 45, 90, 135, 180, 225, 270, 315]);
rates = [r0, r45, r90, r135, r180, r225, r270, r315];

circVar = sum(rates .* exp(1i * directions_rad)) / sum(rates);
DSI = abs(circVar);           % Range: 0 (non-selective) to 1 (perfect)
preferredDir = angle(circVar); % In radians
```

### DSGC Classification Criteria
```matlab
is_DSGC = (max_firing_rate > 4 Hz) AND (average_DSI >= 0.3)
```

## File Naming Conventions

Recommended naming scheme:
```
Spike data:     TXT_experimentID_date.txt
Stimulus data:  STIM_experimentID_date.mat
Parsed data:    DS_experimentID_date.mat
```

## Common Parameter Values

### From Soto et al. 2019
- Rate threshold: **4 Hz**
- DSI threshold: **0.3**
- Stimulus duration: **2 seconds**
- Number of repeats: **5**
- Directions: **8 (every 45°)**

### Adjustable Parameters
| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| rate_threshold | 4 Hz | 2-10 Hz | Higher = fewer cells analyzed |
| dsi_threshold | 0.3 | 0.2-0.5 | Higher = fewer DSGCs |
| ttl_first_threshold | 2980 | System-specific | TTL pulse detection |
| ttl_last_threshold | 3990 | System-specific | TTL pulse detection |

## Command Line Cheat Sheet

### Load and Inspect Results
```matlab
% Load analyzed data
load('DS_experiment001.mat')

% Count DSGCs
nDS = sum(strcmp({ds.type}, 'DS'));
nNonDS = sum(strcmp({ds.type}, 'non-DS'));
fprintf('%d DSGCs, %d non-DS cells\n', nDS, nNonDS);

% Get DSGC indices
dsIdx = find(strcmp({ds.type}, 'DS'));

% View first DSGC
if ~isempty(dsIdx)
    cellIdx = dsIdx(1);
    fprintf('Channel: %s\n', ds(cellIdx).channel);
    fprintf('DSI: %.3f\n', ds(cellIdx).dsi(1,1));
    fprintf('Preferred direction: %.1f°\n', ds(cellIdx).pref(1,1));
end
```

### Plot Tuning Curve
```matlab
% Select a DSGC
cellIdx = dsIdx(1);

% Get tuning data (speed index 1, wavelength index 1)
directions = stimD;  % Degrees
rates = ds(cellIdx).rate(:, 1, 1);  % Firing rates

% Plot polar tuning curve
figure;
polarplot([deg2rad(directions); deg2rad(directions(1))], ...
          [rates; rates(1)], '-o', 'LineWidth', 2);
title(sprintf('Channel %s, DSI=%.2f', ds(cellIdx).channel, ...
              ds(cellIdx).dsi(1,1)));

% Plot Cartesian tuning curve
figure;
plot(directions, rates, '-o', 'LineWidth', 2);
xlabel('Direction (degrees)');
ylabel('Firing Rate (Hz)');
title(sprintf('Channel %s, DSI=%.2f', ds(cellIdx).channel, ...
              ds(cellIdx).dsi(1,1)));
grid on;
```

### Analyze Population
```matlab
% Get all DSI values for DSGCs
dsIdx = find(strcmp({ds.type}, 'DS'));
dsi_values = arrayfun(@(i) ds(i).dsi(1,1), dsIdx);

% Plot DSI distribution
figure;
histogram(dsi_values, 20);
xlabel('Direction Selectivity Index');
ylabel('Count');
title(sprintf('DSI Distribution (n=%d DSGCs)', length(dsIdx)));

% Get preferred directions
pref_dirs = arrayfun(@(i) ds(i).pref(1,1), dsIdx);

% Plot preferred direction distribution
figure;
polarhistogram(deg2rad(pref_dirs), 16);
title('Preferred Direction Distribution');
```

### Export Results
```matlab
% Create summary table
dsIdx = find(strcmp({ds.type}, 'DS'));
nCells = length(dsIdx);

channels = cell(nCells, 1);
dsi_vals = zeros(nCells, 1);
pref_dirs = zeros(nCells, 1);
max_rates = zeros(nCells, 1);

for i = 1:nCells
    idx = dsIdx(i);
    channels{i} = ds(idx).channel;
    dsi_vals(i) = ds(idx).dsi(1,1);
    pref_dirs(i) = ds(idx).pref(1,1);
    max_rates(i) = max(ds(idx).rate(:,1,1));
end

% Create and save table
T = table(channels, dsi_vals, pref_dirs, max_rates, ...
          'VariableNames', {'Channel', 'DSI', 'PreferredDir', 'MaxRate'});
writetable(T, 'DSGC_summary.csv');

fprintf('Saved summary to DSGC_summary.csv\n');
```

## Troubleshooting Quick Fixes

### Error: "Undefined function 'nexread2019'"
```matlab
% Edit dsParser.m line 10
% Change: sp = nexread2019([pathName fileName]);
% To:     sp = nexread([pathName fileName]);
```

### Error: "Undefined function 'deletechannels'"
```matlab
% Add before line 30 of dsParser.m:
sp.data(:, analogCh) = [];
sp.channels(analogCh) = [];
sp.nchan = sp.nchan - length(analogCh);
sp.x(analogCh) = [];
sp.y(analogCh) = [];
% Then comment out line 30:
% sp = deletechannels(sp, analogCh);
```

### Error: "Undefined function 'circ_median'"
```matlab
% Install CircStat toolbox
% Download from: https://github.com/circstat/circstat-matlab
% Add to path:
addpath('/path/to/circstat-matlab')
savepath
```

### All cells classified as non-DS
```matlab
% Check your thresholds in dsAnalyzer.m
% Lines 12-13:
rateThresh = 2;    % Try lowering (was 4)
dsiThresh = 0.25;  % Try lowering (was 0.3)
```

### No TTL pulses detected
```matlab
% Check TTL channels and thresholds in dsParser.m
% Load your data first:
sp = nexread('your_file.txt');

% Plot TTL channels
figure;
plot(sp.data(:,1), ones(size(sp.data(:,1))), 'r.', 'MarkerSize', 10);
hold on;
plot(sp.data(:,2), 2*ones(size(sp.data(:,2))), 'b.', 'MarkerSize', 10);
ylabel('Channel'); xlabel('Time (s)');
title('TTL Pulses');

% Adjust thresholds in dsParser.m lines 25-26 based on plot
```

## Additional Resources

- **Full documentation**: See ANALYSIS_GUIDE.md
- **Code improvements**: See IMPROVEMENTS.md
- **Configuration**: See MEA/config_example.m
- **Questions**: kerschensteinerd@wustl.edu
