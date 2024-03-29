############################################################
# Running HMZDelFinder on 50 samples from 1000 genomes, create RPKM Files and analysis your own data#
############################################################

# define working directory:
setwd("/home/msina/Desktop/HMN/")
workDir <- getwd() 
# set project and data directory 
# replace mainDir with the location you want to store experiment results
mainDir <- paste0(workDir ,"/HMZDelFinder/"); if (!file.exists(mainDir)){dir.create(mainDir)}
dataDir <- paste0(mainDir, "data/" , sep=""); if (!file.exists(dataDir)){dir.create(dataDir)} # data directory


# Install missing packages from CRAN
list.of.packages <- c("RCurl", "gdata", "data.table", "parallel", "Hmisc", "matrixStats")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)


# Install missing packages from Bioconductor
install.packages("BiocManager")

# Note: for Windows users: Rsubread has to be installed from file  
biocLitePackages <- c("DNAcopy", "GenomicRanges", "Rsubread") 
new.biocLitePackage <- biocLitePackages[!(biocLitePackages %in% installed.packages()[,"Package"])]
if(length(new.biocLitePackage)) { source("http://bioconductor.org/biocLite.R"); biocLite(new.biocLitePackage)}


# Install and load the required package

install.packages("remotes")
install.packages("Hmisc")
install.packages("RCurl")
install.packages("data.table")
install.packages("gdata")
install.packages("parallel")
install.packages("Hmisc")
install.packages("matrixStats")
BiocManager::install("DNAcopy")
BiocManager::install("GenomicRanges")
install.packages("GenomicRanges")
BiocManager::install("Rsubread")
install.packages("matrixStats")
install.packages("httr")


# load packages
library(RCurl)
library(data.table)
library(gdata)
library(parallel)
library(Hmisc)
library(matrixStats)
library(DNAcopy)
library(GenomicRanges)
library(Rsubread) 
library(matrixStats) 
library(Rsubread)
library(httr)




# load HMZDelFinder source code
# Note: source ("https://....")  does not work on some platforms
eval( expr = parse( text = getURL("https://raw.githubusercontent.com/BCM-Lupskilab/HMZDelFinder/master/src/HMZDelFinder.R") ))

# download RPKM data for 50 samples from 1000genomes
# if this does not work, the file can be downloaded from:
# https://www.dropbox.com/s/6y14wftyhh6r2j0/TGP.tar.gz?dl=0
# and uncompressed manually into dataDir folder
if (!file.exists(paste0(dataDir, "TGP/"))){
  if (file.exists(paste0(dataDir, "TGP.tar.gz")))file.remove(paste0(dataDir, "TGP.tar.gz"))
  dl_from_dropbox( paste0(dataDir, "TGP.tar.gz"), "6y14wftyhh6r2j0")
  untar(paste0(dataDir, "TGP.tar.gz"), exdir = dataDir)
}
# download BED file
# if this does not work, the file can be downloaded from:
# https://www.dropbox.com/s/1v5jbbm2r809ssy/tgp_hg19.bed.tar.gz?dl=0
# and uncompressed manually into dataDir folder
if (!file.exists(paste0(dataDir, "tgp_hg19.bed"))){ 
  if (file.exists(paste0(dataDir, "tgp_hg19.bed.tar.gz"))){file.remove(paste0(dataDir, "tgp_hg19.bed.tar.gz"))}
  dl_from_dropbox( paste0(dataDir, "tgp_hg19.bed.tar.gz"), "1v5jbbm2r809ssy")
  untar(paste0(dataDir, "tgp_hg19.bed.tar.gz"), exdir =  dataDir)
}

# set/create other paths and identifiers
bedFile <- paste0(dataDir, "tgp_hg19.bed") # set path to BED file
outputDir <- paste0(mainDir, "out/" , sep=""); if (!file.exists(outputDir)){dir.create(outputDir)} # create output directory
plotsDir <- paste0(mainDir, "plots/" , sep=""); if (!file.exists(plotsDir)){dir.create(plotsDir)} # create output plots directory
rpkmFiles <- dir(paste(dataDir, "TGP/",sep=""), "rpkm2.txt$")	# list of RPKM file names
rpkmFids <- gsub(".rpkm2.txt", "", rpkmFiles) 					# list of sample identifiers
rpkmPaths <- paste0(paste0(dataDir, "TGP/"), rpkmFiles) 		# list of paths to RPKM files
aohDir <- paste0(mainDir, "AOH/" , sep=""); if (!file.exists(aohDir)){dir.create(aohDir)} 
aohRDataOut <- paste(mainDir, "AOH/extAOH_small.RData", sep="")	# temprary file to store AOH data


########################################
# THRESHOLDS
#
# See description of HMZDelFinder function for details
########################################
is_cmg <- FALSE 		# only for CMG project - otherwhise use FALSE
lowRPKMthreshold <- 0.65# RPKM threshold  
maxFrequency <- 0.05	# max frequncy of HMZ deletion; default =0.005
minAOHsize <- 1000		# min AOH size
minAOHsig <- 0.45		# min AOH signal threshold
mc.cores<-4 				# number of cores
vR_id<-"VR"				# ID from VCF FORMAT indicating the number of variant reads, for other variant callers could be "AD"
tR_id<-"DP"				# ID from VCF FORMAT indicating the number total reads 
filter <- "PASS"		# for other variant callers be  '.'

# running HMZDelFinder

rpkmFiles <- dir(paste(dataDir, "TGP/",sep=""), "rpkm2.txt$")	# list of RPKM file names
rpkmFids <- gsub(".rpkm2.txt", "", rpkmFiles) 					# list of sample identifiers
rpkmPaths <- paste0(paste0(dataDir, "TGP/"), rpkmFiles) 		# list of paths to RPKM files

results <- runHMZDelFinder (NULL,		# vcfPaths - paths to VCF files for AOH analysis (not used for 1000 genomes) 
                            NULL,		# vcfFids - sample identifiers corresponding to VCF files  (not used for 1000 genomes) 
                            rpkmPaths, 	# paths to RPKM files 
                            rpkmFids,	# samples identifiers corresponding to RPKM files
                            mc.cores,	# number of CPU cores
                            aohRDataOut,# temp file to store AOH data
                            bedFile,	# bed file with target 
                            lowRPKMthreshold, #  RPKM threshold 
                            minAOHsize, # min AOH size
                            minAOHsig,	# min AOH signal threshold
                            is_cmg,		# flag used for CMG specific annotations; TRUE samples are from BHCMG cohort, FALSE otherwhise
                            vR_id, 		# ID for 'the number of variants reads' in VCF FORMAT column (default='VR');
                            tR_id,		# ID for 'the number of total reads' in VCF FORMAT column (default='DP')
                            filter)		# only variants with this value in the VCF FILTER column will be used in AOH analysis 


# saving results in csv files
write.csv(results$filteredCalls, paste0(outputDir,"hmzCalls-3.csv"), row.names=F )

# plotting deletions
lapply(1:nrow(results$filteredCalls),function(i){
  plotDeletion (results$filteredCalls, i, results$bedOrdered, results$rpkmDtOrdered,  lowRPKMthreshold, plotsDir, mainText=""  )})

## Selected columns from the results$filteredCalls object:					
#					Chr     Start      Stop   Genes Start_idx     FID
#					1:   5 140235634 140236833 PCDHA10    133937 NA11919
#					2:   X  47918257  47919256  ZNF630    167263 NA18856
#					3:  11   7817521   7818489   OR5P2     27561 NA19137
#					4:  11   7817521   7818489   OR5P2     27561 NA19236
#					5:   9 107379729 107380128  OR13C9    161704 NA19473
#					6:   1 196795959 196796135   CFHR1     15101 NA20798
#					7:   5  42629139  42629205     GHR    130161 NA07347
#					8:   5  42629139  42629205     GHR    130161 NA12342
#					9:   5  42629139  42629205     GHR    130161 NA19213
#					10:  16  55866915  55866967    CES1     64208 NA18553
## NOTE: Deletions of CES1, CFHR1 and OR13C9 are located within segmental duplications, and thus they were not reported in the manuscript



######if using our HMZdelfider data stted up in your device then analysis your file go for you bam files, 

# create new mainDir with the location you want to store experiment results
mainDir <- paste0(workDir ,"/HMZDelFinder2/"); if (!file.exists(mainDir)){dir.create(mainDir)}
dataDir <- paste0(mainDir, "data/" , sep=""); if (!file.exists(dataDir)){dir.create(dataDir)} # data directory
TGPDir <- file.path(mainDir, "data", "TGP"); if (!file.exists(TGPDir)) {dir.create(TGPDir, recursive = TRUE)}

############
## NOTE 1 ## 
############
## To use own WES data and create RPKM files from BAM files one can use calcRPKMsFromBAMs function.
## e.g:
bedFile <- paste0(dataDir, "IAD200103_1000_Submitted_Mofifiedforexomedepth.bed") # set path to BED file
outputDir <- paste0(mainDir, "out/" , sep=""); if (!file.exists(outputDir)){dir.create(outputDir)} # create output directory
plotsDir <- paste0(mainDir, "plots/" , sep=""); if (!file.exists(plotsDir)){dir.create(plotsDir)} # create output plots directory
rpkmFiles <- dir(paste(dataDir, "TGP/",sep=""), "rpkm2.txt$")	# list of RPKM file names
rpkmFids <- gsub(".rpkm2.txt", "", rpkmFiles) 					# list of sample identifiers
rpkmPaths <- paste0(paste0(dataDir, "TGP/"), rpkmFiles) 		# list of paths to RPKM files
aohDir <- paste0(mainDir, "AOH/" , sep=""); if (!file.exists(aohDir)){dir.create(aohDir)} 
aohRDataOut <- paste(mainDir, "AOH/extAOH_small.RData", sep="")	
RPKMsDir <- paste0(mainDir, "plots/" , sep=""); if (!file.exists(RPKMsDir)){dir.create(plotsDir)} # create output plots directory
bed <- fread(bedFile)
df <- data.frame(cbind(1:nrow(bed), bed))
colnames(df) <- c("GeneID", "Chr", "Start", "End", "Strand")
if (!file.exists(outputDir)){dir.create(outputDir)}
pathToBams <- "/home/msina/Desktop/BAM/" 
bamFiles <- paste0(pathToBams, dir(pathToBams, "bam$"))
rpkmFiles <- dir(paste(dataDir, "TGP/",sep=""), "rpkm2.txt$")	# list of RPKM file names
rpkmFids <- gsub(".rpkm2.txt", "",rpkmFiles) 					# list of sample identifiers
rpkmPaths <- paste0(paste0(dataDir, "TGP/"), rpkmFiles) 		# list of paths to RPKM files
pathToBed <- '/home/msina/Desktop/BAM/HMZ/HMZDelFinder2/data/'
bedFile <- paste0(pathToBed, dir(pathToBed, "bed$"))
rpkmDir <- ("/home/msina/Desktop/HMN/HMZDelFinder2/data/TGP/")
sampleNames <- sapply(strsplit(dir(pathToBams, "bam$"), "[/\\.]"), function(x){x[length(x)-1]})
bedFile <- paste0(dataDir, "IAD200103_1000_Submitted_Mofifiedforexomedepth.bed")
calcRPKMsFromBAMs(bedFile,bamFiles,sampleNames,rpkmDir,4)



########################################
# THRESHOLDS
#
# See description of HMZDelFinder function for details
########################################
is_cmg <- FALSE 		# only for CMG project - otherwhise use FALSE
lowRPKMthreshold <- 0.65# RPKM threshold  
maxFrequency <- 0.05	# max frequncy of HMZ deletion; default =0.005
minAOHsize <- 1000		# min AOH size
minAOHsig <- 0.45		# min AOH signal threshold
mc.cores<-4 				# number of cores
vR_id<-"VR"				# ID from VCF FORMAT indicating the number of variant reads, for other variant callers could be "AD"
tR_id<-"DP"				# ID from VCF FORMAT indicating the number total reads 
filter <- "PASS"		# for other variant callers be  '.'

# running HMZDelFinder

rpkmFiles <- dir(paste(dataDir, "TGP/",sep=""), "rpkm2.txt$")	# list of RPKM file names
rpkmFids <- gsub(".rpkm2.txt", "", rpkmFiles) 					# list of sample identifiers
rpkmPaths <- paste0(paste0(dataDir, "TGP/"), rpkmFiles) 		# list of paths to RPKM files

results <- runHMZDelFinder (NULL,		# vcfPaths - paths to VCF files for AOH analysis (not used for 1000 genomes) 
                            NULL,		# vcfFids - sample identifiers corresponding to VCF files  (not used for 1000 genomes) 
                            rpkmPaths, 	# paths to RPKM files 
                            rpkmFids,	# samples identifiers corresponding to RPKM files
                            mc.cores,	# number of CPU cores
                            aohRDataOut,# temp file to store AOH data
                            bedFile,	# bed file with target 
                            lowRPKMthreshold, #  RPKM threshold 
                            minAOHsize, # min AOH size
                            minAOHsig,	# min AOH signal threshold
                            is_cmg,		# flag used for CMG specific annotations; TRUE samples are from BHCMG cohort, FALSE otherwhise
                            vR_id, 		# ID for 'the number of variants reads' in VCF FORMAT column (default='VR');
                            tR_id,		# ID for 'the number of total reads' in VCF FORMAT column (default='DP')
                            filter)		# only variants with this value in the VCF FILTER column will be used in AOH analysis 


# saving results in csv files
write.csv(results$filteredCalls, paste0(outputDir,"hmzCalls-4.csv"), row.names=F )

# plotting deletions
lapply(1:nrow(results$filteredCalls),function(i){
  plotDeletion (results$filteredCalls, i, results$bedOrdered, results$rpkmDtOrdered,  lowRPKMthreshold, plotsDir, mainText=""  )})







