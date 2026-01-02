### R SCRIPT – PART 5 ###
### cell_abundance.R ###
### This script is for estimating local, site-level and landscape-level abundances, and generating density surface map ###

N=length(mc[,'beta1'])
# Check if cov1km is data frame or sf object. If sf, get just data for calcs.
# In DataMatrix.R, we created cov1km_data (the data frame) and kept modelpoly (the sf object)
M=nrow(cov1km_data) 
holde=matrix(0, nrow=M, ncol=N)

for(i in 1:N){
  holde[,i]=exp(mc[i,3:1794] + mc[i,'beta1']*cov1km_data[,3]+
                  mc[i,'beta2']*cov1km_data[,4] + mc[i,'beta3']*cov1km_data[,5] + mc[i,'beta4']*cov1km_data[,6])
}

## Estimate SD ##
sdZ=NULL
for(i in 1:M){
  sdZ[i]=sd(holde[i,])
}

## Save histogram of SD ##
pdf(paste0(sps,'sdZ_',format(Sys.Date(), "%d%b%Y"),".pdf"), onefile= FALSE)
hist(sdZ)
dev.off()

## Save histogram of Mean ##
pdf(paste0(sps,'meanZ_',format(Sys.Date(), "%d%b%Y"),".pdf"), onefile= FALSE)
meanZ=rowMeans(holde)
medianZ=rowMedians(holde)
hist(meanZ)
dev.off()

## Write cell specific values to csv file ##
write.csv(cbind(cov1km_data[,1],cbind(meanZ,medianZ)),
          paste0(sps,"Zs_",
                 format(Sys.Date(), "%d%b%Y"),".csv"),
          row.names = F)
write.csv(cbind(cov1km_data[,1],sdZ),
          paste0(sps,"sdZ_",
                 format(Sys.Date(), "%d%b%Y"),".csv"),
          row.names = F)

## Generate map and save shape file ##
meanZresults<-as.data.frame(cbind(cov1km_data[,1],cbind(meanZ, medianZ)))
colnames(meanZresults)<-c("ID",paste0(sps,"meanZ"),paste0(sps,"medianZ"))

# Merge results back to sf object
# We assume 'modelpoly' is the sf object from DataMatrix.R
modelpoly_results <- merge(modelpoly, meanZresults, by.x="NUMMER", by.y="ID", all.x=TRUE)

pdf(paste0(sps,'meanZ_map_',format(Sys.Date(), "%d%b%Y"),".pdf"))
plot(modelpoly_results[paste0(sps,"meanZ")], main = paste(sps,'mean abundance'), border="transparent")
dev.off()

pdf(paste0(sps,'medianZ_map_',format(Sys.Date(), "%d%b%Y"),".pdf"))
plot(modelpoly_results[paste0(sps,"medianZ")], main = paste(sps,'median abundance'), border="transparent")
dev.off()

# Save as Shapefile using sf
st_write(modelpoly_results, 
         dsn=paste0(sps,'Zs_map_', format(Sys.Date(), "%d%b%Y"), ".shp"), 
         driver="ESRI Shapefile", 
         delete_dsn = TRUE) 
# Note: delete_dsn=TRUE acts like overwrite_layer=T

### Compute abundance at site level ###
holde.s<-holde[-c(1772:1792),]
cluSum.S<-colSums(holde.s)
abundance.S<-cluSum.S*aveGroupSize
m1<-mean(abundance.S)
m2<-median(abundance.S)
m3<-quantile(abundance.S, probs = c(0.025,0.975))
m4<-HPDinterval(as.mcmc(abundance.S))
msd1<-sd(abundance.S)

stats.abundance.S<-(c(m1,m2,m3,m4,msd1))
names(stats.abundance.S)<-c("mean", "median", "95%CI_L", "95%CI_U", "95%HPD_L", "95%HPD_U","SD")
m5<-mean(cluSum.S)
m6<-median(cluSum.S)
m7<-quantile(cluSum.S, probs=c(0.025, 0.975))
m8<-HPDinterval(as.mcmc(cluSum.S))
msd2<-sd(cluSum.S)
stats.cluster.S<-c(m5,m6,m7,m8,msd2)
names(stats.cluster.S)<-c("mean", "median", "95%CI_L", "95%CI_U", "95%HPD_L", "95%HPD_U","SD")

stats.out<-rbind(stats.cluster.S, stats.abundance.S)
write.csv(stats.out,
          paste0(sps,"_landscape_stats_",
                 format(Sys.Date(), "%d%b%Y"),".csv"),
          row.names = T)
