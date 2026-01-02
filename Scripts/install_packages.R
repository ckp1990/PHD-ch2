# Install required packages
# Set CRAN mirror
r = getOption("repos")
r["CRAN"] = "https://cloud.r-project.org"
options(repos = r)

pkgs <- c("nimble", "coda", "spdep", "sf", "mcmcse", "matrixStats")
install.packages(pkgs)
