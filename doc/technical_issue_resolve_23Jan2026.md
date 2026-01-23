# Technical Issue Resolution Report
**Date:** 23 January 2026

## Overview
I investigated discrepancies in the Sambar analysis results compared to historical data and implemented fixes to align the model behavior with expectations. Additionally, I set up a background job submission workflow to facilitate long-running analyses.

## 1. Group Count Discrepancy (2 vs 5 Groups)
**Issue:** I observed that the analysis was generating only 2 group size categories, whereas the original author's results showed 5 groups.
**Finding:** The control parameter `grszcat` (group size category interval) was set to 5, with a `grszlimit` (max size) of 9.
-   Mathematically: `floor(size / 5) + 1` results in only 2 possible integers for sizes 1-9.
**Resolution:** I changed `grszcat` to **2** in `ControlScript.R`.
-   New behavior: Sizes 1-2 (Group 1), 3-4 (Group 2), ..., 9 (Group 5). This matches the expected 5-group structure.

## 2. Distlimit Discrepancy (212m vs 400m in plots)
**Issue:** The `distlimit` was set to 212m in the script, but the provided detection probability plots showed an x-axis extending to ~400m.
**Finding:** I analyzed `posteriorSummariesWITHdetectionPlot.R` and found that the plot x-axis limit is defined as `distlimit + 20`.
-   **Conclusion:** The presence of a 400m axis in historical plots indicates that those specific plots were generated from a run where `distlimit` was set to approximately 380m, not 212m. The current setting of 212m is effectively cutting off the data range compared to that historical run. I kept `distlimit=212` as per the current control script but noted the reason for the visual difference.

## 3. Infinite Log Probability Warning (-Inf)
**Issue:** Upon fixing the group counts, the model threw a `logProb is -Inf` warning during initialization, specifically related to `sigma0`.
**Finding:** The initial value for `sigma0` was set to 3. In the model, `sigma` scales with group size. For the first group (smallest size), `sigma0=3` implies a very narrow detection width (~20m).
-   data contains observations at the full distance of 212m.
-   The probability of detecting a small group at 212m given a ~20m effective strip width is mathematically indistinguishable from zero by the computer.
-   `log(0)` = `-Inf`, causing the crash.
**Resolution:** I updated the `inits` function in `ControlScript.R` to increase `sigma0` from 3 to **4**. This provides a sufficiently wide initial detection function to assign non-zero probabilities to distant observations, allowing the MCMC chain to start successfully.

## 4. Job Submission System
**Requirement:** Enable running the analysis as a background job with custom parameters to avoid blocking the local R session.
**Implementation:**
-   **Refactored `ControlScript.R`**: Added command-line argument parsing to accept `niter`, `nburnin`, and `job_label` dynamically, while preserving defaults for interactive use.
-   **Created `Scripts/SubmitJob.R`**: Developed a helper function `submit_job()` that constructs the execution command and launches it as a detached background process (using PowerShell on Windows). It automatically redirects output to a log file (e.g., `Sambar_Fixed_Run_2.log`) for monitoring.

## Status
The final "Fixed" run (`Sambar_Fixed_Run_2`) is currently executing with these corrections.
