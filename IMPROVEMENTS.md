# Code Improvements and Recommendations

This document outlines specific improvements that could enhance the maintainability, usability, and robustness of the MEA analysis code.

## Priority 1: Critical Issues (Prevent Runtime Failures)

### 1.1 Fix Missing Function Call

**Issue**: `dsParser.m` line 10 calls `nexread2019` but only `nexread` exists in the repository.

**Current Code** (dsParser.m:10):
```matlab
sp = nexread2019([pathName fileName]);
```

**Recommended Fix**:
```matlab
sp = nexread([pathName fileName]);
```

**Impact**: This prevents immediate runtime failure when running dsParser.m.

---

### 1.2 Implement Missing `deletechannels` Function

**Issue**: `dsParser.m` line 30 calls undefined `deletechannels` function.

**Current Code** (dsParser.m:30):
```matlab
sp = deletechannels(sp, analogCh);
```

**Option A - Create Function**:
Create `MEA/deletechannels.m`:
```matlab
function sp = deletechannels(sp, channels)
% DELETECHANNELS Remove specified channels from spike data structure
%   sp = deletechannels(sp, channels) removes the channels specified
%   by their indices from the spike data structure
%
%   Inputs:
%       sp - Spike data structure (from nexread)
%       channels - Vector of channel indices to remove
%
%   Output:
%       sp - Updated spike data structure

    sp.data(:, channels) = [];
    sp.channels(channels) = [];
    sp.nchan = sp.nchan - length(channels);
    sp.x(channels) = [];
    sp.y(channels) = [];
end
```

**Option B - Inline Replacement**:
Replace line 30 in dsParser.m with:
```matlab
sp.data(:, analogCh) = [];
sp.channels(analogCh) = [];
sp.nchan = sp.nchan - length(analogCh);
sp.x(analogCh) = [];
sp.y(analogCh) = [];
```

---

### 1.3 Document `circ_median` Dependency

**Issue**: `dsAnalyzer.m` line 64 uses `circ_median` from external toolbox.

**Solution**: Add to README.md:

```markdown
## Required External Toolboxes

### CircStat - Circular Statistics Toolbox

This analysis requires the CircStat toolbox for circular statistics.

**Installation**:
1. Download from: https://github.com/circstat/circstat-matlab
2. Add to MATLAB path:
   ```matlab
   addpath('/path/to/circstat-matlab')
   ```

**Citation**: P. Berens, CircStat: A Matlab Toolbox for Circular Statistics, 
Journal of Statistical Software, 2009

**Alternative**: MATLAB's Statistics and Machine Learning Toolbox includes 
circular statistics functions if available.
```

---

## Priority 2: Code Quality Improvements

### 2.1 Parameterize Hardcoded Values

**Issue**: Experiment-specific values are hardcoded, reducing portability.

**Create Configuration File**: `MEA/config_example.m`

```matlab
% MEA Analysis Configuration
% Copy this file to config.m and modify for your experiment

config = struct();

% TTL Pulse Detection Thresholds (dsParser)
config.ttl_first_threshold = 2980;    % Voltage threshold for first TTL
config.ttl_last_threshold = 3990;     % Voltage threshold for last TTL
config.analog_channels = [1 2];       % Columns containing TTL data

% Direction Selectivity Analysis (dsAnalyzer)
config.rate_threshold = 4;            % Minimum firing rate (Hz) for DS analysis
config.dsi_threshold = 0.3;           % DSI threshold for DSGC classification
config.n_dirs = 1;                    % Number of preferred directions
config.speed_index = 1;               % Speed index for preferred direction
config.wavelength_indices = 2:3;      % Wavelength indices for preferred direction

% Array Geometry (nexread)
config.array_type = '252-electrode';  % Array type identifier
config.apply_coordinate_transform = true;  % Apply specific coordinate transform
```

**Modified dsParser.m** (beginning):
```matlab
% Load configuration
if exist('config.m', 'file')
    config_file;
else
    warning('Using default configuration. Copy config_example.m to config.m to customize.');
    config.ttl_first_threshold = 2980;
    config.ttl_last_threshold = 3990;
    config.analog_channels = [1 2];
end

% ... existing code ...

% Use config values
analogCh = config.analog_channels;
firstTtl = find(analog(:,1) > config.ttl_first_threshold, 1, 'first');
lastTtl = find(analog(:,2) > firstTtl & analog(:,2) < config.ttl_last_threshold, 1, 'last');
```

---

### 2.2 Add Error Handling

**Issue**: No validation or error checking throughout code.

**Example Improvements for dsParser.m**:

```matlab
%% LOADING FILES & DEFINING PATH FOR SAVING PARSED DATA
% load spike data from a txt file exported from Neuroexplorer
[fileName, pathName] = uigetfile('*.txt','Select TXT_ file');
if fileName == 0
    error('No spike data file selected. Analysis cancelled.');
end

% Verify file exists and is readable
fullPath = [pathName fileName];
if ~exist(fullPath, 'file')
    error('Spike data file not found: %s', fullPath);
end

try
    sp = nexread(fullPath);
catch ME
    error('Failed to read spike data: %s', ME.message);
end

% Validate structure
if ~isfield(sp, 'data') || ~isfield(sp, 'channels')
    error('Invalid spike data structure. Missing required fields.');
end

clear fileName pathName

% load stimulus data
[fileName, pathName] = uigetfile('*.mat', 'Select STIM_ file');
if fileName == 0
    error('No stimulus file selected. Analysis cancelled.');
end

try
    stim_data = load([pathName fileName]);
catch ME
    error('Failed to load stimulus file: %s', ME.message);
end

% Validate stimulus data
if ~isfield(stim_data, 'DS_IN') || ~isfield(stim_data, 'DS_OUT')
    error('Stimulus file must contain DS_IN and DS_OUT structures.');
end

DS_IN = stim_data.DS_IN;
DS_OUT = stim_data.DS_OUT;

% Validate required fields
required_in = {'direction', 'speed', 'duration', 'nRepeats'};
required_out = {'direction', 'speed', 'wavelength'};

for i = 1:length(required_in)
    if ~isfield(DS_IN, required_in{i})
        error('DS_IN missing required field: %s', required_in{i});
    end
end

for i = 1:length(required_out)
    if ~isfield(DS_OUT, required_out{i})
        error('DS_OUT missing required field: %s', required_out{i});
    end
end

clear fileName pathName stim_data
```

**Add to nexread.m**:
```matlab
function sp = nexread(filename)
% NEXREAD Import spike data from Neuroexplorer text export
%   sp = nexread(filename) reads a tab-delimited text file containing
%   spike timestamps exported from Neuroexplorer
%
%   Input:
%       filename - Path to text file
%
%   Output:
%       sp - Structure with fields:
%            data: Matrix of spike timestamps
%            channels: Cell array of channel names
%            nchan: Number of channels
%            x, y: Electrode coordinates

% Validate input
if nargin < 1 || isempty(filename)
    error('nexread:InvalidInput', 'Filename is required');
end

if ~exist(filename, 'file')
    error('nexread:FileNotFound', 'File not found: %s', filename);
end

% Try to open file
fid = fopen(filename, 'rt');
if fid == -1
    error('nexread:FileOpenError', 'Could not open file: %s', filename);
end

% Ensure file is closed even if error occurs
cleanup = onCleanup(@() fclose(fid));

% ... rest of existing code ...
```

---

### 2.3 Replace Deprecated Functions

**Issue**: `str2num` is deprecated in modern MATLAB.

**Current Code** (nexread.m:13):
```matlab
while isempty(str2num(channames{nchan}))
```

**Recommended Fix**:
```matlab
while isnan(str2double(channames{nchan}))
```

**Why**: 
- `str2num` uses `eval()` internally (security risk)
- `str2double` is faster and safer
- `str2double` returns `NaN` for non-numeric strings (vs empty array)

---

### 2.4 Remove Empty Else Blocks

**Issue**: Multiple empty `else` statements add clutter without function.

**Examples to Clean**:

dsAnalyzer.m:
```matlab
% Lines 29-30: Remove
else
end

% Lines 46-47: Remove  
else
end

% Lines 68-69: Remove
else
end

% Lines 76-77: Remove
else
end
```

dsParser.m:
```matlab
% Line 61: Remove
else
end
```

nexread.m:
```matlab
% Line 56: Remove
else
end
```

**Better Pattern**:
```matlab
% Instead of:
if condition
    % code
else
end

% Use:
if condition
    % code
end
```

---

## Priority 3: Maintainability Enhancements

### 3.1 Convert Scripts to Functions

**Issue**: Scripts use UI dialogs and global variables, preventing automation.

**Example Refactored dsParser**:

```matlab
function ds = dsParser(spikeFile, stimFile, outputFile, varargin)
% DSPARSER Parse spike data by drifting grating stimulus conditions
%
%   ds = dsParser(spikeFile, stimFile, outputFile) parses spike data
%   according to stimulus parameters
%
%   Inputs:
%       spikeFile - Path to Neuroexplorer text export
%       stimFile - Path to MAT file with DS_IN and DS_OUT structures
%       outputFile - Path for saving parsed data
%
%   Optional Parameters:
%       'TTLThresholds' - [first, last] voltage thresholds (default: [2980, 3990])
%       'AnalogChannels' - TTL channel indices (default: [1 2])
%       'ShowProgress' - Display waitbar (default: true)
%
%   Output:
%       ds - Parsed data structure array
%
%   Example:
%       ds = dsParser('spikes.txt', 'stimulus.mat', 'output.mat');
%       ds = dsParser('spikes.txt', 'stimulus.mat', 'output.mat', ...
%                     'TTLThresholds', [3000, 4000]);

% Parse optional inputs
p = inputParser;
addParameter(p, 'TTLThresholds', [2980, 3990]);
addParameter(p, 'AnalogChannels', [1 2]);
addParameter(p, 'ShowProgress', true);
parse(p, varargin{:});

ttl_thresholds = p.Results.TTLThresholds;
analogCh = p.Results.AnalogChannels;
show_progress = p.Results.ShowProgress;

% Load data with error handling
try
    sp = nexread(spikeFile);
catch ME
    error('Failed to load spike data: %s', ME.message);
end

try
    stim_data = load(stimFile);
    stimIn = stim_data.DS_IN;
    stimOut = stim_data.DS_OUT;
catch ME
    error('Failed to load stimulus data: %s', ME.message);
end

% ... rest of parsing logic ...

% Save results
try
    save(outputFile, 'ds', 'stimD', 'stimS', 'stimW', 'duration', ...
        'nRepeats', 'stimIn', 'stimOut');
catch ME
    error('Failed to save results: %s', ME.message);
end

end
```

**Benefits**:
- Can be called from other scripts
- Suitable for batch processing
- Testable with automated tests
- Clear input/output contract

---

### 3.2 Reduce Nesting Complexity

**Issue**: 4-level nested loops in dsParser.m (lines 56-81) are hard to read.

**Current Structure**:
```matlab
for h=1:nChannels
    for i=1:length(stimD)
        for j=1:length(stimS)
            for k=1:length(stimW)
                % complex logic here
            end
        end
    end
end
```

**Refactored Approach**:
```matlab
for h=1:nChannels
    ds(h) = parseChannel(data(:,h), channel(h), ttls, stimD, stimS, stimW, ...
                         dOrder, sOrder, wOrder, duration);
end

function channelData = parseChannel(spikeTrain, channelName, ttls, ...
                                    stimD, stimS, stimW, dOrder, sOrder, wOrder, duration)
    channelData.channel = channelName;
    
    % Find relevant spikes
    firstSpike = find(spikeTrain >= ttls(1,1), 1, 'first');
    lastSpike = find(spikeTrain <= ttls(end,2) & spikeTrain > 0, 1, 'last');
    
    if isempty(firstSpike) || isempty(lastSpike)
        channelData.drift = [];
        return;
    end
    
    spikeTrain = spikeTrain(firstSpike:lastSpike);
    
    % Parse by stimulus conditions
    for i=1:length(stimD)
        for j=1:length(stimS)
            for k=1:length(stimW)
                channelData.drift(i,j,k) = parseCondition(spikeTrain, ttls, ...
                    stimD(i), stimS(j), stimW(k), dOrder, sOrder, wOrder, duration);
            end
        end
    end
end

function condition = parseCondition(spikeTrain, ttls, dir, speed, wavelength, ...
                                    dOrder, sOrder, wOrder, duration)
    stimIdx = find(dOrder==dir & sOrder==speed & wOrder==wavelength);
    condition.spikes = [];
    
    for l=1:length(stimIdx)
        trialSpikes = spikeTrain(spikeTrain >= ttls(stimIdx(l),1) & ...
                                 spikeTrain <= ttls(stimIdx(l),2));
        trialSpikes = trialSpikes - ttls(stimIdx(l),1);
        
        if l > 1
            trialSpikes = trialSpikes + (l-1)*duration;
        end
        
        condition.spikes = [condition.spikes; trialSpikes];
    end
end
```

---

### 3.3 Improve Variable Naming

**Issue**: Single-letter loop variables in complex contexts.

**Improvements**:
```matlab
% Instead of:
for i=1:length(stimD)
    for j=1:length(stimS)
        for k=1:length(stimW)

% Use:
for dirIdx=1:length(stimD)
    for speedIdx=1:length(stimS)
        for waveIdx=1:length(stimW)

% Or:
nDirections = length(stimD);
nSpeeds = length(stimS);
nWavelengths = length(stimW);

for dirIdx=1:nDirections
    for speedIdx=1:nSpeeds
        for waveIdx=1:nWavelengths
```

---

### 3.4 Add Progress Logging

**Issue**: Only visual waitbar, no text output for batch processing.

**Enhancement**:
```matlab
function ds = dsParser(spikeFile, stimFile, outputFile, varargin)
    % ... setup code ...
    
    fprintf('Starting MEA spike data parsing...\n');
    fprintf('  Spike file: %s\n', spikeFile);
    fprintf('  Stimulus file: %s\n', stimFile);
    fprintf('  Output file: %s\n', outputFile);
    
    fprintf('Loading data...\n');
    sp = nexread(spikeFile);
    fprintf('  Loaded %d channels\n', sp.nchan);
    
    stim_data = load(stimFile);
    fprintf('  Loaded %d directions, %d speeds, %d wavelengths\n', ...
            length(stimIn.direction), length(stimIn.speed), ...
            length(unique(stimOut.wavelength)));
    
    fprintf('Parsing spikes by stimulus conditions...\n');
    tic;
    
    if show_progress
        g = waitbar(0, 'Processing channels...');
    end
    
    for h=1:nChannels
        % ... processing ...
        
        if show_progress
            waitbar(h/nChannels, g, sprintf('Channel %d/%d', h, nChannels));
        end
        
        if mod(h, 50) == 0
            fprintf('  Processed %d/%d channels (%.1f%%)...\n', ...
                    h, nChannels, 100*h/nChannels);
        end
    end
    
    if show_progress
        close(g);
    end
    
    elapsed = toc;
    fprintf('Parsing complete in %.1f seconds\n', elapsed);
    fprintf('Saving results to %s...\n', outputFile);
    save(outputFile, 'ds', ...);
    fprintf('Done!\n');
end
```

---

## Priority 4: Testing and Validation

### 4.1 Create Unit Tests

**Create `MEA/tests/test_nexread.m`**:

```matlab
function tests = test_nexread
    tests = functiontests(localfunctions);
end

function test_basic_import(testCase)
    % Test basic file import
    % Create test data file
    testFile = create_test_spike_file();
    
    % Import
    sp = nexread(testFile);
    
    % Verify structure
    verifyTrue(testCase, isfield(sp, 'data'));
    verifyTrue(testCase, isfield(sp, 'channels'));
    verifyTrue(testCase, isfield(sp, 'nchan'));
    verifyTrue(testCase, isfield(sp, 'x'));
    verifyTrue(testCase, isfield(sp, 'y'));
    
    % Cleanup
    delete(testFile);
end

function test_nan_handling(testCase)
    % Test NaN conversion
    testFile = create_test_file_with_nans();
    sp = nexread(testFile);
    
    % Verify NaNs converted to -1
    verifyEqual(testCase, sum(isnan(sp.data(:))), 0);
    verifyTrue(testCase, any(sp.data(:) == -1));
    
    delete(testFile);
end

function filename = create_test_spike_file()
    % Helper to create test data
    filename = tempname;
    fid = fopen(filename, 'w');
    fprintf(fid, 'A01\tB02\tC03\n');
    fprintf(fid, '1.23\t2.34\t3.45\n');
    fprintf(fid, '4.56\t5.67\t6.78\n');
    fclose(fid);
end
```

---

### 4.2 Add Input Validation Functions

**Create `MEA/validate_stimulus.m`**:

```matlab
function validate_stimulus(DS_IN, DS_OUT)
% VALIDATE_STIMULUS Check stimulus data structure validity
%   validate_stimulus(DS_IN, DS_OUT) validates that stimulus structures
%   contain all required fields and have compatible dimensions

    % Check DS_IN fields
    required_in = {'direction', 'speed', 'duration', 'nRepeats'};
    for i = 1:length(required_in)
        if ~isfield(DS_IN, required_in{i})
            error('DS_IN missing required field: %s', required_in{i});
        end
    end
    
    % Check DS_OUT fields
    required_out = {'direction', 'speed', 'wavelength'};
    for i = 1:length(required_out)
        if ~isfield(DS_OUT, required_out{i})
            error('DS_OUT missing required field: %s', required_out{i});
        end
    end
    
    % Check dimensions
    nTrials = length(DS_OUT.direction);
    if length(DS_OUT.speed) ~= nTrials
        error('DS_OUT.speed length (%d) does not match direction length (%d)', ...
              length(DS_OUT.speed), nTrials);
    end
    if length(DS_OUT.wavelength) ~= nTrials
        error('DS_OUT.wavelength length (%d) does not match direction length (%d)', ...
              length(DS_OUT.wavelength), nTrials);
    end
    
    % Check value ranges
    if any(DS_IN.direction < 0) || any(DS_IN.direction >= 360)
        error('DS_IN.direction values must be in range [0, 360)');
    end
    
    if DS_IN.duration <= 0
        error('DS_IN.duration must be positive');
    end
    
    if DS_IN.nRepeats < 1 || mod(DS_IN.nRepeats, 1) ~= 0
        error('DS_IN.nRepeats must be a positive integer');
    end
    
    fprintf('Stimulus validation passed\n');
end
```

---

## Summary of Recommended Actions

### Immediate (Critical)
1. ✅ Fix `nexread2019` → `nexread` in dsParser.m line 10
2. ✅ Implement or document `deletechannels` function
3. ✅ Document `circ_median` dependency and installation

### Short-term (Important)
4. ✅ Create configuration file for experiment-specific parameters
5. ✅ Add error handling and input validation
6. ✅ Replace deprecated `str2num` with `str2double`
7. ✅ Remove empty else blocks

### Medium-term (Maintainability)
8. ✅ Convert scripts to functions with clear APIs
9. ✅ Reduce nesting complexity with helper functions
10. ✅ Improve variable naming
11. ✅ Add comprehensive logging

### Long-term (Scalability)
12. ✅ Create unit test suite
13. ✅ Add input validation functions
14. ✅ Consider vectorization for performance
15. ✅ Add batch processing utilities

---

## Example Modernized Workflow

After implementing these improvements:

```matlab
% Configure analysis
config.ttl_first_threshold = 3000;
config.ttl_last_threshold = 4000;
config.dsi_threshold = 0.35;

% Parse data (no UI dialogs)
ds = dsParser('recordings/exp001_spikes.txt', ...
              'recordings/exp001_stimulus.mat', ...
              'results/exp001_parsed.mat', ...
              'TTLThresholds', [config.ttl_first_threshold, config.ttl_last_threshold]);

% Analyze direction selectivity
ds = dsAnalyzer('results/exp001_parsed.mat', ...
                'results/exp001_analyzed.mat', ...
                'DSIThreshold', config.dsi_threshold);

% Batch process multiple files
files = dir('recordings/*_spikes.txt');
for i = 1:length(files)
    fprintf('Processing %s...\n', files(i).name);
    % Automated processing
end
```

This modernized approach is:
- ✅ Automatable
- ✅ Testable
- ✅ Portable across experiments
- ✅ Robust with error handling
- ✅ Well-documented
