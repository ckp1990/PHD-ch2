### R SCRIPT – PART 1 ###
### ControlScript.R ###
### Load required libraries and scripts ###
library(nimble)
library(coda)
library(spdep)
library(sf)       # Replaces maptools, rgdal
library(mcmcse)
library(matrixStats)

# setwd("/ungulate/CHT") # REMOVED: Use RStudio Project root or relative paths

### Choose species to be analysed ###
### The data from 5 species; CHT-chital, SBR-sambar, GAR-gaur, PIG-wild pig, MJK-muntjac were analyzed using these scripts###
sps='SBR'


### Specify input files ###
# Assume input files are in a 'Data' directory at the project root.
dstf <- 'Data/nhb.csv'
# transect details file; see Appendix 1 for data structure #
trf <- 'Data/TRidentity.csv'
# Shape files with landscape level covariates; see Appendix 1 for data structure #
shp <- 'Data/cov1km.shp'
# transect level covariates; see Appendix 1 for data structure #
trcov <- 'Data/TRsbrcovariates1.csv'



### Specify values for estimating detection function ###
distcatsize=20; # distance category size; 15 to 20 categories are ideal#
distlimit=370; # maximum distance observed#
grszcat=5; # cluster category size; 10 to 15 categories are ideal#
grszlimit=60; # maximum cluster size observed#

### Specify sampling design ###
## Number of transects in the study design ##
uqid=83 # use the maximum number of grids intersected by any transect to arrive at this number; edit lines in the DataMatrix.R script based on sampling design details
igrid=11
# Clean and remove transects which are not sampled, e.g., outside the park administrative boundary, and hence not sampled in our case #

# List of transects outside the study area; these are specific to the data being analyzed #
subsetlist=c(40,54,61,67,72,78)
## List of rows with wrong transect IDs ##
wrid<-c(58,59,60, 65,66,67)
## Assign correct ID to the above##
rrid=40

## Specify columns with transect number and transect level covariates; these depend on the data being analyzed ##
sb1<-c("tr.no","SBRpalplants.m2","thabitat.disturb.km")

## Specify columns with landscape level covariates; these depend on the data being analyzed ##
sb2<-c("VARSLOPE","WTRAVGDIST","ECODISTAVG","PCHSCR")

### Process data ###
source('Scripts/DataMatrix.R')

### model definition ###
# Ngrid comes from modelpoly which is created in DataMatrix.R
print("--- DIGANOSTICS ---")
print(paste("ngs:", ngs))
print("grszMean:")
print(grszMean)
print(paste("Is vector?", is.vector(grszMean)))
print(paste("Length:", length(grszMean)))
print("-------------------")

Ngrid=nrow(modelpoly) 

sumNumNeigh=length(unlist(adjmatrix))
adj=unlist(adjmatrix)
num=sapply(adjmatrix, length)
bigM=as.matrix(bigM2)
cov1km_mat=as.matrix(cov1km_data) # Renamed to avoid confusion with sf object
covsites=as.matrix(covsites)

## define constants in the model ##
const <- list(sumNumNeigh=sumNumNeigh, bigM=bigM,
              adj=adj, num=num,
              cov1km=cov1km_mat,
              covsites=covsites, ntrans=ntrans,
              ndistcat=ndistcat, ngs=ngs, newy=newy,
              Ngrid=Ngrid, ndistwalk=ndistwalk, grszcat=grszcat,
              distBreaks=distBreaks, logFactorial= logFactorial)

## read nimble model script for the analysis WITHOUT indicator variables##
### edit lines in the 'NimModUniPrior.R' script based on the number of covariates used ###
source('Scripts/NimModUniPrior.R')

## define parameters for the model WITHOUT indicator variables ##
parameters <- c("b", "p", "lams", "sigs", "beta1", "beta2",
                "beta3", "beta4", "alpha1", "alpha2", "gs", "grszMean","sigma","sigma0")

## specify either random or plausible initial values for the model WITHOUT indicator variables##
a=1
b=as.vector(rnorm(Ngrid, 0, .5))
inits <- function(){list(b=b, p=0.2, lams=5, sigs=1, sigma0=3, beta1=a, beta2=a, beta3=a, beta4=a, alpha1=a, alpha2=a)}

### running nimble model ###
# Running in UNCOMPILED mode due to Rtools mismatch (R 4.5 vs Rtools42)
print("Building model (Uncompiled)...")
model <- nimbleModel(code = NimModUniPrior, constants = const, inits = inits())

print("Configuring MCMC...")
mcmcConf <- configureMCMC(model, monitors = parameters)
mcmc <- buildMCMC(mcmcConf)

print("Running MCMC (Uncompiled - this may be slow)...")
# Run MCMC
# Note: nburnin is handled by removing samples after run or custom loop. 
# nimbleMCMC wrapper handles this, but runMCMC also has nburnin arg logic?
# runMCMC returns samples matrix by default.
samples <- runMCMC(mcmc, niter = 2000, nburnin = 200)

t1=Sys.time()
# Wrap in list to match structure expected by posterior script
output_list <- list(samples = samples)
assign(paste0(sps,"UP"), output_list)
print(Sys.time()-t1)

### save objects as a backup to avoid any loss ###
### comment this if you want to save read/write time ###
save.image()

### Compute summaries of posterior distribution ###
## check object ‘grszBreaks’ to determine which ‘groupsizes’ should be plotted ##
## uncomment lines in 'posteriorSummariesWITHdetectionPlot.R' if you are using the model WITH indicator variables ##
grszSeq = seq(1:length(grszBreaks))
source('Scripts/posteriorSummariesWITHdetectionPlot.R')

## Compute local, site-level and landscape-level abundances and generate density surface map ##
## Update lines 6-7 in the 'cell_abundance.R' script depending on the number of covariates used in the analysis ##
source('Scripts/cell_abundance.R')
save.image()
