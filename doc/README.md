# R Scripts for Bayesian Hierarchical Spatial Model

This directory contains the refactored R scripts for fitting the Bayesian Hierarchical Spatial Model using `nimble`. The scripts have been updated to use the `sf` package instead of the deprecated `rgdal` and `maptools` packages.

## File Descriptions

1.  **`ControlScript.R`**: The master script. Run this to execute the entire analysis. It loads libraries, defines parameters, sources other scripts, and runs the MCMC simulation.
2.  **`DataMatrix.R`**: Prepares the data. It loads CSVs and Shapefiles, processes transect data, and generates the spatial adjacency matrix.
3.  **`NimModUniPrior.R`**: Defines the NIMBLE model structure (priors, likelihoods, spatial effects).
4.  **`posteriorSummariesWITHdetectionPlot.R`**: Analyzes the MCMC output, calculates statistics (Mean, SD, Credible Intervals), and plots detection functions.
5.  **`cell_abundance.R`**: Estimates abundance at grid cells and generates density surface maps (Shapefiles and PDFs).

## How to Run

1.  Open `ControlScript.R` in RStudio.
2.  Ensure your data files are in the parent directory (or update the paths in `ControlScript.R`):
    -   `nhb.csv`
    -   `TRidentity.csv`
    -   `cov1km.shp` (and associated files)
    -   `TRchtcovariates1.csv`
3.  Run the code in `ControlScript.R` line by line or source the entire file.

## Requirements

-   `nimble`
-   `coda`
-   `spdep`
-   `sf` (replaces `rgdal`, `maptools`)
-   `mcmcse`
-   `matrixStats`

## Rtools (C++ Compiler) - High Performance

To run the model efficiently (using C++ compilation), you **must** have a version of Rtools that matches your R version:

-   **R 4.5.x** requires **Rtools45**.
-   **R 4.4.x** requires **Rtools44**.
-   **R 4.2.x** requires **Rtools42**.

If Rtools is missing or mismatched, the script will automatically fallback to **Uncompiled Mode**, which is significantly slower (e.g., 5-15 mins vs <1 min).
To fix this, download and install the correct Rtools from [CRAN](https://cran.r-project.org/bin/windows/Rtools/).

Install missing packages:
```r
install.packages(c("nimble", "coda", "spdep", "sf", "mcmcse", "matrixStats"))
```
