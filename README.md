# Soto2019_amigo2-dendrite-scaling

This repository contains MATLAB code for analyzing direction-selective responses to drifting grating stimuli in multielectrode array (MEA) recordings from retinal ganglion cells.

## Publication

**Soto F, Tien NW, Goel A, Zhao L, Ruzycki PA, Kerschensteiner D.**  
*"AMIGO2 Scales Dendrite Arbors in the Retina"*  
Cell Reports, 2019

[Read the paper](./Soto%20et%20al.%202019%20-%20AMIGO2%20Scales%20Dendrite%20Arbors%20in%20the%20Retina.pdf)

## Overview

The analysis pipeline processes spike data from 252-electrode MEA recordings and characterizes direction-selective ganglion cells (DSGCs) based on their responses to drifting grating stimuli of varying:
- **Direction** (0-360°)
- **Speed** (temporal frequency)
- **Wavelength** (spatial frequency)

## Quick Start

### Requirements

- MATLAB R2016b or later
- CircStat toolbox (for circular statistics): https://github.com/circstat/circstat-matlab

### Basic Usage

1. **Parse spike data by stimulus conditions:**
   ```matlab
   run('MEA/dsParser.m')
   ```
   - Select spike data text file (exported from Neuroexplorer)
   - Select stimulus MAT file containing DS_IN and DS_OUT structures
   - Save parsed data

2. **Analyze direction selectivity:**
   ```matlab
   run('MEA/dsAnalyzer.m')
   ```
   - Select parsed MAT file from step 1
   - Results are saved back to the same file

3. **View results:**
   ```matlab
   load('your_analyzed_file.mat')
   dsIdx = find(strcmp({ds.type}, 'DS'));
   fprintf('Found %d DSGCs out of %d channels\n', length(dsIdx), length(ds));
   ```

## Documentation

- **[ANALYSIS_GUIDE.md](./ANALYSIS_GUIDE.md)** - Comprehensive guide to the analysis pipeline, data formats, and usage
- **[IMPROVEMENTS.md](./IMPROVEMENTS.md)** - Detailed recommendations for code improvements and modernization

## Scripts

### MEA/nexread.m
Imports spike timestamp data from Neuroexplorer text file exports.

**Input:** Tab-delimited text file with channel labels and spike timestamps  
**Output:** Structure with spike data and electrode coordinates

### MEA/dsParser.m
Parses spike trains according to stimulus conditions (direction, speed, wavelength).

**Inputs:** 
- Spike data text file
- Stimulus MAT file (DS_IN and DS_OUT structures)

**Output:** MAT file with parsed spike trains for each stimulus condition

### MEA/dsAnalyzer.m
Computes direction selectivity index (DSI) and classifies cells as DSGCs or non-DS.

**Input:** Parsed MAT file from dsParser  
**Output:** Updated MAT file with DSI, preferred directions, and cell classifications

## Important Notes

### Missing Dependencies

This repository references functions not included in the codebase:

1. **`nexread2019`** - Called in dsParser.m but should be `nexread`
   - **Fix:** Change line 10 of dsParser.m from `nexread2019` to `nexread`

2. **`deletechannels`** - Used to remove analog channels from spike data
   - **Workaround:** See IMPROVEMENTS.md for implementation

3. **`circ_median`** - Circular statistics function
   - **Install:** CircStat toolbox from https://github.com/circstat/circstat-matlab

See [IMPROVEMENTS.md](./IMPROVEMENTS.md) for detailed solutions.

### Experiment-Specific Parameters

Several values are hardcoded for specific experimental conditions:
- TTL pulse voltage thresholds (2980, 3990)
- Analog channel indices ([1, 2])
- MEA array geometry (252-electrode layout)
- Direction selectivity thresholds

These may need adjustment for different recording systems. See [ANALYSIS_GUIDE.md](./ANALYSIS_GUIDE.md) for details.

## Troubleshooting

### Common Issues

**"Undefined function 'nexread2019'"**
- Change line 10 of dsParser.m to use `nexread` instead

**"Undefined function 'circ_median'"**
- Install CircStat toolbox: https://github.com/circstat/circstat-matlab

**No TTL pulses detected**
- Verify TTL voltage thresholds match your recording system
- Check that analog channels [1,2] contain TTL data

See [ANALYSIS_GUIDE.md](./ANALYSIS_GUIDE.md) for more troubleshooting tips.

## Additional Resources

Additional scripts and example data are available upon request.

## Contact

For questions or to request additional materials:
- Email: kerschensteinerd@wustl.edu

## Citation

If you use this code, please cite:

```
Soto F, Hsiang JC, Rajagopal R, Piggott K, Harocopos GJ, Couch SM, Custer P, 
Morgan JL, Kerschensteiner D. AMIGO2 Scales Dendrite Arbors in the Retina. 
Cell Reports, 2019.
```

## License

This code is provided for research purposes. See publication for details.
