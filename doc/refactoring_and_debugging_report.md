# Refactoring and Debugging Report
**From:** `Rscripts.R` (Monolithic Legacy Script)
**To:** `Scripts/` (Modular, Modernized, and Debugged Pipeline)

This document details the step-by-step engineering process undertaken to transform the original legacy code into a working analysis pipeline.

## 1. Code Refactoring & Modernization
The original file `Rscripts.R` contained 5 different logical parts in a single text file, using deprecated libraries and hardcoded paths.

### A. Modularization
We split `Rscripts.R` into 5 separate, functional scripts:
1.  **`ControlScript.R`**: The main orchestrator (formerly Part 1).
2.  **`DataMatrix.R`**: Data loading and processing (formerly Part 2).
3.  **`NimModUniPrior.R`**: NIMBLE model definition (formerly Part 3).
4.  **`posteriorSummariesWITHdetectionPlot.R`**: Results analysis (formerly Part 4).
5.  **`cell_abundance.R`**: Mapping and abundance estimation (formerly Part 5).

### B. Library Migration
The code relied on `rgdal` and `maptools`, which are **deprecated/retired**. We migrated all spatial logic to the modern `sf` (Simple Features) package.
-   **Old**: `readShapePoly(...)` / `writeOGR(...)`
-   **New**: `st_read(...)` / `st_write(...)`
-   **Old**: `Map2poly` / `sp` adjacency
-   **New**: `spdep::poly2nb` directly objects on `sf` objects.

### C. Path Corrections
-   Removed hardcoded paths (e.g., `setwd("/ungulate/CHT")`).
-   Updated to use relative paths pointing to a `Data/` directory (e.g., `Data/nhb.csv`).

---

## 2. Programming & Logic Debugging
Once refactored, we encountered and resolved several runtime errors.

### A. R Language Logic Errors
1.  **Vector-to-Scalar Assignment (`DataMatrix.R`)**
    -   *Error*: `number of items to replace is not a multiple of replacement length`.
    -   *Cause*: The script tried to assign a vector of matches (`TRid$Nummer[b]`) to a single matrix cell.
    -   *Fix*: Explicitly selected the first element: `TRid$Nummer[b][1]`.

2.  **Vector-to-Scalar Logic (`NimModUniPrior.R`)**
    -   *Error*: `Code distBreaks was given as known but evaluates to a non-scalar`.
    -   *Cause*: NIMBLE expected a scalar value in the detection function `phi(...)`, but the entire `distBreaks` vector was passed.
    -   *Fix*: Changed to use `distBreaks[1]`.

3.  **BUGS/NIMBLE Assignment Syntax**
    -   *Error*: `Dimension of grszMean is 0`.
    -   *Cause*: Initializing a vector node with scalar syntax (`grszMean <- ...`) caused NIMBLE to define it as a scalar, conflicting with later vector usage (`grszMean[k]`).
    -   *Fix*: Changed assignment to vector syntax: `grszMean[1] <- ...` and `gs[1] <- ...`.
    -   *Fix*: Removed `grszMean` from the `constants` list to allow it to be a stochastic node.

---

## 3. Data & Configuration Debugging
Adjustments made to match the specific dataset provided by the user.

### A. Species Mismatch
-   **Issue**: Script defaulted to Chital (`CHT`), but only `TRsbrcovariates1.csv` (Sambar) was available.
-   **Fix**:
    1.  Changed species code to `sps = 'SBR'`.
    2.  Updated specific covariate column name from `CHTpalplants.m2` to `SBRpalplants.m2`.

### B. Environment Mismatch (Compilation)
-   **Issue**: `Failed to create the shared library`.
-   **Cause**: Version mismatch between **R 4.5.2** and **Rtools42**. NIMBLE requires matching versions to compile C++ models.
-   **Fix**: Modified `ControlScript.R` to run in **Uncompiled Mode**. This bypasses the C++ compiler requirement, allowing the model to run (albeit slower) without requiring system-level reinstallations.

---

## 4. Current Status (Live Update)
**Status**: `RUNNING`
**Mode**: Uncompiled (Interpretive R)
**Details**: The model has initialized successfully and is currently executing the MCMC sampling (2000 iterations). 
**Note**: Uncompiled execution is slower than compiled execution. No errors have occurred effectively since the start of sampling.

