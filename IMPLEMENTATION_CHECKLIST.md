# Implementation Checklist for Code Improvements

This checklist provides a step-by-step guide for implementing the improvements documented in IMPROVEMENTS.md. Items are organized by priority and can be tackled incrementally.

## ✅ Priority 1: Critical Fixes (Prevent Runtime Failures)

These fixes are essential for the code to run properly.

### 1.1 Fix nexread Function Call
- [ ] Open `MEA/dsParser.m`
- [ ] Navigate to line 10
- [ ] Change `sp = nexread2019([pathName fileName]);` to `sp = nexread([pathName fileName]);`
- [ ] Save file
- [ ] Test by running dsParser.m with sample data

**Estimated time:** 2 minutes  
**Risk:** None (simple find-replace)

---

### 1.2 Implement deletechannels Function
Choose **Option A** (recommended) or **Option B**:

#### Option A: Create Standalone Function
- [ ] Create new file `MEA/deletechannels.m`
- [ ] Copy function code from IMPROVEMENTS.md section 1.2
- [ ] Save file
- [ ] Test with: `sp = nexread('test.txt'); sp = deletechannels(sp, [1 2]);`

**Estimated time:** 5 minutes  
**Risk:** Low

#### Option B: Inline Replacement
- [ ] Open `MEA/dsParser.m`
- [ ] Navigate to line 30
- [ ] Replace `sp = deletechannels(sp, analogCh);` with 5 lines from IMPROVEMENTS.md
- [ ] Save file

**Estimated time:** 3 minutes  
**Risk:** Low

---

### 1.3 Install and Document CircStat Dependency
- [ ] Download CircStat from https://github.com/circstat/circstat-matlab
- [ ] Extract to a suitable location (e.g., `~/MATLAB/toolboxes/circstat-matlab`)
- [ ] Add to MATLAB path: `addpath('/path/to/circstat-matlab')`
- [ ] Save path: `savepath`
- [ ] Test: `help circ_median`
- [ ] Update README.md with installation instructions (already done!)

**Estimated time:** 10 minutes  
**Risk:** None

---

## 🔧 Priority 2: Code Quality Improvements

These improvements enhance code quality without changing functionality.

### 2.1 Replace Deprecated str2num
- [ ] Open `MEA/nexread.m`
- [ ] Navigate to line 13
- [ ] Change `while isempty(str2num(channames{nchan}))` to `while isnan(str2double(channames{nchan}))`
- [ ] Save file
- [ ] Test with sample data to ensure channel detection still works

**Estimated time:** 3 minutes  
**Risk:** Low (well-tested replacement)

---

### 2.2 Remove Empty Else Blocks
Files to clean:

#### dsAnalyzer.m
- [ ] Remove empty else block at lines 29-30
- [ ] Remove empty else block at lines 46-47
- [ ] Remove empty else block at lines 68-69
- [ ] Remove empty else block at lines 76-77
- [ ] Save file

#### dsParser.m
- [ ] Remove empty else block at line 61
- [ ] Save file

#### nexread.m
- [ ] Remove empty else block at line 56
- [ ] Save file

**Estimated time:** 10 minutes  
**Risk:** None (no functional change)

---

### 2.3 Create Configuration File System
- [ ] Copy `MEA/config_example.m` to `MEA/config.m` (or instruct users to do so)
- [ ] Modify dsParser.m to load config values:
  - [ ] Add config loading section at beginning
  - [ ] Replace hardcoded values with config variables
- [ ] Modify dsAnalyzer.m to load config values:
  - [ ] Add config loading section at beginning
  - [ ] Replace hardcoded values with config variables
- [ ] Test with different config values to ensure they're being used

**Estimated time:** 45 minutes  
**Risk:** Medium (requires testing)

---

### 2.4 Add Error Handling
Choose critical areas first, then expand:

#### Phase 1: File I/O (Highest Priority)
- [ ] Add file existence checks in dsParser.m
- [ ] Add try-catch around nexread calls
- [ ] Add try-catch around stimulus file loading
- [ ] Add structure validation for DS_IN and DS_OUT

**Estimated time:** 30 minutes  
**Risk:** Low

#### Phase 2: Data Validation
- [ ] Create `MEA/validate_stimulus.m` function (code in IMPROVEMENTS.md)
- [ ] Call from dsParser.m after loading stimulus file
- [ ] Test with intentionally malformed data

**Estimated time:** 20 minutes  
**Risk:** Low

#### Phase 3: Graceful Failures
- [ ] Add error handling for empty channels in dsParser.m
- [ ] Add warning messages for skipped channels
- [ ] Add try-catch around save operations

**Estimated time:** 20 minutes  
**Risk:** Low

---

## 📦 Priority 3: Maintainability Enhancements

These changes improve long-term maintainability and usability.

### 3.1 Convert Scripts to Functions

This is a larger refactoring. Consider doing one script at a time.

#### Phase 1: dsParser.m → Function
- [ ] Create backup: `cp dsParser.m dsParser_original.m`
- [ ] Add function signature with arguments
- [ ] Add input parser for optional parameters
- [ ] Replace `uigetfile` with function arguments
- [ ] Add function documentation header
- [ ] Test both old script and new function work
- [ ] Update documentation to show both usage methods

**Estimated time:** 2 hours  
**Risk:** Medium (significant refactor)

#### Phase 2: dsAnalyzer.m → Function
- [ ] Same steps as Phase 1
- [ ] Ensure works with dsParser function output

**Estimated time:** 1.5 hours  
**Risk:** Medium

---

### 3.2 Reduce Nesting Complexity

This improves readability but requires careful refactoring.

- [ ] Extract dsParser.m parsing logic into helper functions
- [ ] Create `parseChannel` helper function
- [ ] Create `parseCondition` helper function
- [ ] Test thoroughly to ensure identical results
- [ ] Run on sample data and compare output with original

**Estimated time:** 2 hours  
**Risk:** Medium (logic-heavy refactor)

---

### 3.3 Improve Variable Naming
- [ ] Replace single-letter loop variables in dsParser.m with descriptive names
- [ ] Replace single-letter loop variables in dsAnalyzer.m
- [ ] Use consistent naming conventions (camelCase or under_score)
- [ ] Test after changes

**Estimated time:** 30 minutes  
**Risk:** Low (simple rename with testing)

---

### 3.4 Add Logging and Progress Indicators
- [ ] Add fprintf statements at key points in dsParser.m
- [ ] Add timestamp logging
- [ ] Add summary statistics after processing
- [ ] Make logging configurable via config file
- [ ] Test with verbose=true and verbose=false

**Estimated time:** 45 minutes  
**Risk:** Low

---

## 🧪 Priority 4: Testing and Validation

These additions help ensure code correctness.

### 4.1 Create Test Data
- [ ] Create minimal test spike data file (10 channels, 100 spikes)
- [ ] Create corresponding test stimulus file
- [ ] Document expected outputs
- [ ] Store in `MEA/test_data/` directory

**Estimated time:** 1 hour  
**Risk:** Low

---

### 4.2 Create Unit Tests
If you have MATLAB's testing framework:

- [ ] Create `MEA/tests/` directory
- [ ] Create `test_nexread.m` (code in IMPROVEMENTS.md)
- [ ] Create `test_deletechannels.m`
- [ ] Create `test_validation.m`
- [ ] Run tests: `runtests('MEA/tests')`

**Estimated time:** 2 hours  
**Risk:** Low (but time-consuming)

---

### 4.3 Create Integration Test Script
- [ ] Create `test_full_pipeline.m`
- [ ] Uses test data from 4.1
- [ ] Runs complete pipeline
- [ ] Verifies output structure
- [ ] Checks for expected number of DSGCs
- [ ] Documents in README.md

**Estimated time:** 1 hour  
**Risk:** Low

---

## 📊 Optional Enhancements

These are nice-to-have improvements for advanced use cases.

### Batch Processing Support
- [ ] Create `batch_process_mea.m` script
- [ ] Accepts directory of spike files
- [ ] Automatically pairs with stimulus files
- [ ] Generates summary report
- [ ] Example usage in documentation

**Estimated time:** 2 hours  
**Risk:** Low

---

### Visualization Tools
- [ ] Create `plot_tuning_curves.m` helper function
- [ ] Create `plot_dsgc_map.m` for spatial distribution
- [ ] Create `generate_summary_report.m` for PDF export
- [ ] Add examples to documentation

**Estimated time:** 3 hours  
**Risk:** Low

---

### Performance Optimization
- [ ] Profile dsParser.m to identify bottlenecks
- [ ] Vectorize operations where possible
- [ ] Pre-allocate arrays instead of growing dynamically
- [ ] Consider parallel processing for channels
- [ ] Benchmark improvements

**Estimated time:** 4 hours  
**Risk:** Medium (requires careful testing)

---

## 📋 Implementation Strategy

### Minimal Viable Improvement (1-2 hours)
Focus on critical fixes only:
1. ✅ Fix nexread function call (1.1)
2. ✅ Implement deletechannels (1.2)
3. ✅ Install CircStat (1.3)
4. ✅ Replace str2num (2.1)

**Result:** Code runs without errors

---

### Basic Quality Improvement (4-6 hours)
Add critical fixes + basic quality improvements:
1. Complete Minimal Viable Improvement
2. ✅ Remove empty else blocks (2.2)
3. ✅ Add basic error handling (2.4 Phase 1)
4. ✅ Create configuration file system (2.3)

**Result:** Code is more robust and maintainable

---

### Comprehensive Refactor (15-20 hours)
Full improvement implementation:
1. Complete Basic Quality Improvement
2. Convert scripts to functions (3.1)
3. Reduce nesting complexity (3.2)
4. Add logging (3.4)
5. Create tests (4.1-4.3)

**Result:** Production-quality, maintainable codebase

---

## ✅ Verification Checklist

After implementing improvements, verify:

- [ ] Code runs without errors on test data
- [ ] Output matches expected format
- [ ] DSGCs are correctly identified
- [ ] Preferred directions are reasonable (0-360°)
- [ ] DSI values are in range [0, 1]
- [ ] All modified functions have documentation
- [ ] Configuration file works correctly
- [ ] Error messages are informative
- [ ] Code style is consistent
- [ ] Git commits are logical and well-described

---

## 📝 Notes

- **Backup before changes:** Always create backups of original files before modifying
- **Test incrementally:** Test after each change, not after all changes
- **Version control:** Commit after each completed item
- **Documentation:** Update documentation as you make changes
- **Peer review:** Have someone else review major refactors

---

## 🆘 Getting Help

If you encounter issues:
1. Check ANALYSIS_GUIDE.md for detailed explanations
2. Review IMPROVEMENTS.md for full code examples
3. Consult QUICK_REFERENCE.md for troubleshooting tips
4. Contact: kerschensteinerd@wustl.edu

---

## 📈 Progress Tracking

Track your progress by checking off items as you complete them. Update this file in your repository to keep track of what's been done.

**Started:** ___________  
**Last updated:** ___________  
**Completed:** ___________  
**Implemented by:** ___________
