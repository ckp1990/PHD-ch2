dstf <- 'Data/nhb.csv'
trf <- 'Data/TRidentity.csv'
shp <- 'Data/cov1km.shp'
trcov <- 'Data/TRsbrcovariates1.csv'
sps <- 'SBR'

distcatsize=20
distlimit=370
grszcat=5
grszlimit=60

# Replicate DataMatrix.R logic
x2=read.table(dstf,header=TRUE,sep=',')
print(paste("Rows in x2:", nrow(x2)))
print(paste("walk.no class:", class(x2$walk.no)))
print(head(unique(x2$walk.no)))

x=subset(x2,x2$walk.no!='NA')
print(paste("Rows in x (walk.no != 'NA'):", nrow(x)))

y=subset(x,x$species==sps)
print(paste("Rows in y (species == SBR):", nrow(y)))

if(nrow(y) > 0) {
  print(summary(y$p.dist))
  print(summary(y$gr.sz))
  
  t5=floor(y$p.dist/distcatsize)+1;
  ndistcat=max(t5, na.rm=TRUE);
  print(paste("ndistcat:", ndistcat))

  hold=floor(y$gr.sz/grszcat)+ 1;
  ngs=max(hold, na.rm=TRUE);
  print(paste("ngs:", ngs))

  grszMean = seq(sum(1:grszcat)/grszcat, by=grszcat, length=ngs)
  print("grszMean:")
  print(grszMean)
} else {
  print("Y is empty!")
}
