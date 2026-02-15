# MEA Drifting Grating Analysis Guide

## Overview

This repository contains MATLAB scripts for analyzing direction-selective responses to drifting grating stimuli in multielectrode array (MEA) recordings from retinal ganglion cells. The analysis pipeline was developed for the manuscript:

**Soto et al., "AMIGO2 Scales Dendrite Arbors in the Retina" Cell Reports, 2019**

## Analysis Pipeline

The analysis consists of three sequential steps:

### 1. Data Import (`nexread.m`)

**Purpose**: Import spike timestamp data from Neuroexplorer text file exports.

**Input**: 
- Tab-delimited text file exported from Neuroexplorer containing spike timestamps
- Each column represents one electrode channel
- First row contains channel labels (e.g., "A01", "B12")

**Output**: 
- `sp` structure with fields:
  - `sp.data`: Matrix of spike timestamps (rows = spikes, columns = channels)
  - `sp.channels`: Cell array of channel names
  - `sp.nchan`: Number of channels
  - `sp.x`, `sp.y`: Spatial coordinates of electrodes on the array

**Key Features**:
- Automatically detects channel labels from file header
- Converts NaN values to -1 for easier processing
- Extracts electrode spatial coordinates from channel names (assumes 252-electrode array geometry)

### 2. Stimulus Parsing (`dsParser.m`)

**Purpose**: Parse spike trains according to different stimulus conditions (direction, speed, wavelength).

**Inputs Required**:
1. Spike data text file (from Neuroexplorer)
2. Stimulus data MAT file containing:
   - `DS_IN`: Input stimulus parameters
     - `DS_IN.direction`: Array of stimulus directions (degrees)
     - `DS_IN.speed`: Array of stimulus speeds
     - `DS_IN.duration`: Stimulus presentation duration (seconds)
     - `DS_IN.nRepeats`: Number of stimulus repetitions
   - `DS_OUT`: Output stimulus sequence
     - `DS_OUT.direction`: Actual directions presented (row vector)
     - `DS_OUT.speed`: Actual speeds presented (row vector)
     - `DS_OUT.wavelength`: Actual wavelengths presented (row vector)

**TTL Pulse Detection**:
- Assumes columns 1-2 of spike data contain TTL pulse timestamps
- TTL pulses mark stimulus onset and offset
- **Hardcoded thresholds**: 
  - First TTL: `analog(:,1) > 2980`
  - Last TTL: `analog(:,2) < 3990`
  - ⚠️ These values are experiment-specific and may need adjustment

**Output**: 
- MAT file containing `ds` structure array (one element per channel):
  - `ds(h).channel`: Channel identifier
  - `ds(h).drift(i,j,k).spikes`: Spike times for:
    - `i`: Direction index
    - `j`: Speed index  
    - `k`: Wavelength index
  - Spike times are relative to stimulus onset and concatenated across repeats

**Processing**:
- For each channel and stimulus condition, extracts spikes occurring during stimulus presentation
- Normalizes spike times to stimulus onset
- Concatenates repeated presentations with appropriate time offsets

### 3. Direction Selectivity Analysis (`dsAnalyzer.m`)

**Purpose**: Compute direction selectivity metrics and classify cells as direction-selective ganglion cells (DSGCs) or non-DS.

**Input**: 
- MAT file from `dsParser.m`

**Key Parameters** (currently hardcoded):
```matlab
rateThresh = 4;      % Minimum firing rate (Hz) for DS analysis
dsiThresh = 0.3;     % DSI threshold for DSGC classification
nDirs = 1;           % Number of preferred directions to index
sIdx = 1;            % Speed index for determining preferred direction
wIdx = 2:3;          % Wavelength indices for determining preferred direction
```

**Computed Metrics**:

1. **Firing Rate**: 
   ```matlab
   rate = spike_count / (duration * nRepeats)
   ```

2. **Direction Selectivity Index (DSI)**:
   Uses circular variance:
   ```matlab
   circVar = sum(rate .* exp(1i*radDir)) / sum(rate)
   DSI = abs(circVar)
   ```
   - Range: 0 (non-selective) to 1 (perfectly selective)

3. **Preferred Direction**:
   ```matlab
   prefDir = rad2deg(angle(circVar))
   ```

**Cell Classification**:
- **DSGC** (Direction-Selective Ganglion Cell): 
  - Maximum firing rate > `rateThresh`
  - Average DSI ≥ `dsiThresh`
  - Assigns preferred and null direction indices
- **Non-DS**: All other cells

**Output**: 
- Updates the input MAT file with additional fields in `ds` structure:
  - `ds(i).rate(l,k,j)`: Firing rates for each condition
  - `ds(i).dsi(k,j)`: Direction selectivity index
  - `ds(i).pref(k,j)`: Preferred direction (degrees)
  - `ds(i).type`: 'DS' or 'non-DS'
  - `ds(i).prefIdx`: Index of preferred direction(s)
  - `ds(i).nullIdx`: Index of null direction(s)

## Required External Dependencies

The scripts require functions not included in this repository:

### 1. `nexread2019` (called in dsParser.m, line 10)
- **Status**: ❌ Missing (script calls this but repository contains `nexread.m` instead)
- **Likely issue**: Should call `nexread` instead of `nexread2019`
- **Fix**: Change line 10 in dsParser.m:
  ```matlab
  % Current:
  sp = nexread2019([pathName fileName]);
  
  % Should be:
  sp = nexread([pathName fileName]);
  ```

### 2. `deletechannels` (called in dsParser.m, line 30)
- **Status**: ❌ Missing
- **Purpose**: Remove specified channels from spike data structure
- **Workaround**: Manual implementation:
  ```matlab
  % Instead of: sp = deletechannels(sp, analogCh);
  sp.data(:, analogCh) = [];
  sp.channels(analogCh) = [];
  sp.nchan = sp.nchan - length(analogCh);
  sp.x(analogCh) = [];
  sp.y(analogCh) = [];
  ```

### 3. `circ_median` (called in dsAnalyzer.m, line 64)
- **Status**: ❌ Missing
- **Purpose**: Compute circular median of angular data
- **Source**: CircStat toolbox by Philipp Berens
  - Available at: https://github.com/circstat/circstat-matlab
  - Alternative: MATLAB's Circular Statistics Toolbox
- **Citation**: P. Berens, CircStat: A Matlab Toolbox for Circular Statistics, Journal of Statistical Software, 2009

## Data Format Requirements

### Stimulus Data Structure
The stimulus MAT file must contain `DS_IN` and `DS_OUT` structures:

**DS_IN** (input parameters):
```matlab
DS_IN.direction = [0, 45, 90, 135, 180, 225, 270, 315];  % degrees
DS_IN.speed = [100, 200, 400];                            % units/sec
DS_IN.duration = 2;                                       % seconds
DS_IN.nRepeats = 5;                                       % number of repetitions
```

**DS_OUT** (presentation sequence):
```matlab
DS_OUT.direction = [0, 90, 180, ...];    % row vector, one per trial
DS_OUT.speed = [100, 100, 200, ...];     % row vector, one per trial
DS_OUT.wavelength = [50, 100, 50, ...];  % row vector, one per trial
```

### Spike Data Format
- Tab-delimited text file
- First row: Channel labels (e.g., A01, B02, ...)
- Subsequent rows: Spike timestamps (one row per timestamp)
- Columns 1-2: TTL pulse timestamps (stimulus markers)
- Columns 3+: Spike timestamps for each electrode

## Usage Instructions

### Basic Workflow

1. **Prepare Data**:
   - Export spike data from Neuroexplorer as tab-delimited text
   - Ensure stimulus data is saved in MAT file with DS_IN and DS_OUT structures

2. **Run dsParser.m**:
   ```matlab
   % In MATLAB:
   run('MEA/dsParser.m')
   ```
   - Select spike data text file when prompted
   - Select stimulus MAT file when prompted
   - Save parsed data to desired location

3. **Run dsAnalyzer.m**:
   ```matlab
   % In MATLAB:
   run('MEA/dsAnalyzer.m')
   ```
   - Select the parsed MAT file from step 2
   - Results are saved back to the same file

4. **Analyze Results**:
   ```matlab
   % Load results
   load('your_analyzed_file.mat')
   
   % Find DSGCs
   dsIdx = find(strcmp({ds.type}, 'DS'));
   fprintf('Found %d DSGCs out of %d channels\n', length(dsIdx), length(ds));
   
   % Plot tuning curve for first DSGC
   if ~isempty(dsIdx)
       figure;
       polar(deg2rad(stimD), ds(dsIdx(1)).rate(:,1,1));
       title(sprintf('Channel %s, DSI=%.2f', ...
           ds(dsIdx(1)).channel, ds(dsIdx(1)).dsi(1,1)));
   end
   ```

## Limitations and Considerations

### Experiment-Specific Parameters

Several values are **hardcoded for specific experimental conditions**:

1. **TTL Thresholds** (dsParser.m, lines 25-26):
   - Values: 2980 and 3990
   - May need adjustment for different recording systems
   - Verify TTL pulse voltages in your data

2. **Analog Channel Indices** (dsParser.m, line 23):
   - Assumes TTL pulses in columns 1-2
   - Verify channel configuration in your exports

3. **Array Geometry** (nexread.m, lines 51-54):
   - Assumes 252-electrode array layout
   - Coordinate transformation is specific to certain array types
   - May need modification for different MEA configurations

4. **Analysis Parameters** (dsAnalyzer.m, lines 12-16):
   - Rate threshold (4 Hz) and DSI threshold (0.3) are publication-specific
   - Consider adjusting based on your cell types and recording conditions

### Known Issues

1. **No Error Handling**: Scripts will fail silently if:
   - Files are not found or improperly formatted
   - Required variables (DS_IN, DS_OUT) are missing
   - Stimulus sequence doesn't match expectations

2. **Manual File Selection**: 
   - All scripts use UI dialogs (`uigetfile`, `uiputfile`)
   - Prevents batch processing or automation
   - Not suitable for analyzing multiple datasets

3. **Memory Usage**:
   - Entire spike dataset loaded into memory
   - May be problematic for very long recordings

4. **Processing Speed**:
   - Nested loops (4 levels deep in dsParser.m)
   - Can be slow for large channel counts or many stimulus conditions

## Tips for Successful Analysis

1. **Verify TTL Pulses**:
   ```matlab
   % Load and inspect TTL channels
   sp = nexread('your_file.txt');
   figure; plot(sp.data(:,1), ones(size(sp.data(:,1))), 'r.');
   hold on; plot(sp.data(:,2), 2*ones(size(sp.data(:,2))), 'b.');
   title('TTL Pulses'); ylabel('Channel'); xlabel('Time (s)');
   ```

2. **Check Stimulus Alignment**:
   - Ensure number of TTL pulse pairs matches expected trial count
   - Verify `length(DS_OUT.direction)` equals number of stimulus presentations

3. **Monitor Progress**:
   - dsParser.m shows a waitbar during processing
   - For large datasets, consider adding timestamps to track progress

4. **Validate Results**:
   - Check that DSI values are between 0 and 1
   - Verify preferred directions are within 0-360°
   - Inspect firing rate distributions

## Troubleshooting

### Problem: "Undefined function 'nexread2019'"
**Solution**: Edit dsParser.m line 10 to use `nexread` instead

### Problem: "Undefined function 'deletechannels'"
**Solution**: Implement manual deletion (see Dependencies section)

### Problem: "Undefined function 'circ_median'"
**Solution**: Install CircStat toolbox from https://github.com/circstat/circstat-matlab

### Problem: No TTL pulses detected
**Solution**: 
- Verify analog channels contain TTL data
- Adjust threshold values in dsParser.m lines 25-26
- Check that `analogCh = [1 2]` is correct for your data

### Problem: Empty ds structure for all channels
**Solution**:
- Verify spike timestamps fall within TTL pulse range
- Check that spike times are in seconds (not milliseconds)
- Ensure channels have recorded spikes

### Problem: All cells classified as non-DS
**Solution**:
- Verify rate threshold isn't too high for your recording
- Check DSI threshold is appropriate
- Inspect raw firing rates: `[ds.rate]`

## Contact

For questions or to request additional scripts and example data:
- Email: kerschensteinerd@wustl.edu

## Citation

If you use this code, please cite:

Soto F, Hsiang JC, Rajagopal R, Piggott K, Harocopos GJ, Couch SM, Custer P, Morgan JL, Kerschensteiner D. "AMIGO2 Scales Dendrite Arbors in the Retina" Cell Reports, 2019.
