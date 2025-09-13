# Script name:         runGGIR.R
# Purpose of script:   extract data from AX6 for Ambient-BD
# Author:              Cathy Wyse
# Date Created:        2024-01-04
# Contact:             cathy.wyse@mu.ie

library (GGIR)
library(dplyr)
library(stringr)
library("rstudioapi")

#======================================================================================
#  Notes:
#      - this is designed for processing single files because of the long duration of the datafiles (3 months)
#      - paste only one cwa file into the datadir
#      - the date in the filename prevents overwriting, but still watch for this
#======================================================================================
#
# Stage 1 - Set up temporary local folders for input of cwa file and export of results
#
#======================================================================================

# set the working directory to the UoE sharepoint - raw data and results go to Z

setwd("C:/Users/cwyse/University of Edinburgh/Ambient-BD - Documents/Workstream 1_Assessing data collection methods/2. Data analysis/Axivity Processing")
#setwd("C:/Users/Admin/University of Edinburgh/Ambient-BD - Documents/Workstream 1_Assessing data collection methods/2. Data analysis/Axivity Processing")
# the cwa download from omgui should result in a folder with studyID name in here Z:\Axivity\cwa_files\ 
# the steps implemented by this script are:
# 
# 1  Check folders to set up processing and transfer to Z:
# 2  Run GGIR 
# 3  Check for errors and missing days
# 4  Transfer cwa file and GGIR sleep and circadian output to Z:
# 5  Extract time series data (for circadian rhythms analysis) and GGIR parameters that we will use
# 6  Transfer all results generated from GGIR to Z: for use by other researchers

#put the studyID here
studyID <- "abd5660"

# List all matching files in the directory using a wildcard
file_list <- list.files(
  path = paste0("Z:/Axivity/cwa_files/", studyID),
  pattern = paste0("acc_", studyID, "_.*\\.cwa$"),
  full.names = TRUE
)

# Set datadir based on the number of matching files
if (length(file_list) == 1) {
  datadir <- file_list[1]
} else if (length(file_list) > 1) {
  print(file_list)
  message("There is more than one cwa file matching the criteria.")
}
outputdir <- "C:/temp_GGIR_output"  # Location of GGIR output on local PC - also the source folder for items to export to Z

# Check if the directory exists
if (dir.exists(outputdir)) {
  # Delete the directory and all its contents
  unlink(outputdir, recursive = TRUE, force = TRUE)
  files <- list.files(outputdir, recursive = TRUE, full.names = TRUE)
  unlink(files, force = TRUE)  # Delete files first
  unlink(outputdir, recursive = TRUE, force = TRUE)  # Now delete directory
  cat("Directory and all contents deleted:", outputdir, "\n")
} else {
  cat("Directory does not exist:", outputdir, "\n")
}

dir.create(outputdir, recursive = TRUE)
cat("Directory recreated:", outputdir, "\n")

# define directory for testing demo
datadir <- "C:/Users/cwyse/Downloads/17864_0000000000.cwa"
outputdir <- "C:/temp"  
#datadir <- "C:/temp_GGIR_output/acc_abd2201_90days_6026273.cwa"
#datadir <- "C:/temp_GGIR_output/acc_abd2421_110days_6032662.cwa"


#======================================================================================
#
# Stage 2 - Run GGIR with Ambient-BD standard arguments
#
#======================================================================================

mode = c(1,2,3,4,5)
studyname = "AmbientBD" 
f0 = 1  # file number to start
f1 = 2  # file number to end

GGIR(
  mode = mode, # ggir modes to run
  datadir = datadir , # location of cwa file
  outputdir = outputdir,  # output to temporary local drive
  metadatadir = outputdir, # output metadata to local drive
  studyname = studyname, 
  f0 = f0, 
  f1 = f1, 
  overwrite = TRUE, # reuse early phases of ggir if available
  do.imp = TRUE, # input missing data
  idloc = 1, # location of ID - not needed
  print.filename = FALSE, # not needed
  storefolderstructure = FALSE, #store structure of folder with cwa
  verbose = TRUE,
  

  #------------------------------# Part 1 parameters: #------------------------------
  
  windowsizes = c(5,900,3600), #this will give 5s epoch files and 60 min non-wear evaluation window [epoch lengths for acc, angle and non-wear epochs]
  do.cal = TRUE, # apply autocalibration
  do.enmo = TRUE, # calculates the metric: = _x^2 + acc_y^2 + acc_z^2 - 1 
  do.anglez = TRUE, #calculate arm angle
  chunksize = 1, # autocalibration procedure
  printsummary = TRUE, # print autocalibation results to screen
  
  
  
  #------------------------------# Part 2 parameters: #------------------------------
  data_masking_strategy = 1, # how to deal with knowledge about study protocol - might be applied in later stages of ABD
  ndayswindow = 7,  # used as part of data_masking_strategy 
  hrs.del.start = 1, # disregard first hour
  hrs.del.end = 1, # disregard last hour
  maxdur = 0, # days after start of experiment did experiment definitely stop, zero if unknown
  includedaycrit = 16, # minimum required number of valid hours in calendar day 
  M5L5res = 10, # Resolution of L5 and M5 analysis in minutes
  winhr = c(5,10), # Vector of window size(s) (unit: hours) of LX and MX analysis
  qlevels = NULL,  # vector of percentiles eg c(c(1380/1440),c(1410/1440)),
  qwindow = c(0,24), 
  ilevels = NULL, # Levels for acceleration value frequency distribution in m eg c(seq(0,400,by=50),8000)
  mvpathreshold = c(100,120), # acceleration threshold for MVPA if c(), then MVPA is not estimated.  We might as well calculate this but not used in ABD
  
  
  #------------------------------# Part 3 parameters: #------------------------------
  timethreshold = c(5), # Time threshold (minutes) for sustained inactivity periods detection
  anglethreshold = 5, # Angle threshold (degrees) for sustained inactivity periods detection.
  ignorenonwear = TRUE, # ignore detected monitor non-wear periods to avoid confusion between monitor non-wear time and sustained inactivity
  
  
  #------------------------------# Part 4 parameters: #------------------------------
  excludefirstlast = FALSE, # first and last night of the measurement are ignored for the sleep assessment in g.part4
  includenightcrit = 16, # Minimum number of valid hours per night (24 hour window between noon and noon), used for sleep assessment in g.part4
  def.noc.sleep = 1, # The time window during which sustained inactivity will be assumed to represent sleep, 1 uses van hees algorithm
  #loglocation = "D:/sleeplog.csv", 
  outliers.only = FALSE, # all available nights are included in the visual representation of the data and sleeplog
  criterror = 4,  # sleep log
  relyonguider = FALSE,  # sleep log
  colid = 1, # sleep log
  coln1 = 2,  # sleep log
  do.visual = TRUE, #generate a pdf with a visual representation of the overlap between the sleeplog entries and the accelerometer detections
  
  
  
  #------------------------------# Part 5 parameters: #------------------------------
  
  # Key functions: Merging physical activity with sleep analyses 
  threshold.lig = c(30,40,50), # Threshold for light physical activity 
  threshold.mod = c(100,120),  # Threshold for mod physical activity
  threshold.vig = c(400,500),  # Threshold for vig physical activity
  boutcriter = 0.8, # bout definitions
  boutcriter.in = 0.9, 
  boutcriter.lig = 0.8, 
  boutcriter.mvpa = 0.8, 
  boutdur.in = c(10,20,30), 
  boutdur.lig = c(1,5,10), 
  boutdur.mvpa = c(1,5,10),
  save_ms5rawlevels = TRUE,
  timewindow = c("WW"), # timewindow over which summary statistics are derived. Value can be “MM” (midnight to midnight), “WW” (waking time to waking time), “OO” (sleep onset to sleep onset)
  
  epochvalues2csv = TRUE, # epoch values are exported to a csv file
  
  
  
  #------------------------------# Part 6 parameters: #------------------------------
  
  #cosinor = TRUE, # we will do that separately ourselves
  #part6CR = TRUE,
  
  
  #----------------------------------# Report generation #------------------------------
  do.report = c(1,2,3,4,5))


#rm(list=ls(all=TRUE)) # clear environment


#======================================================================================
#
# Stage 3 - Check the data quality before moving data to the server
#
#======================================================================================

# view the QC files before moving the results to the server

pdffile <- list.files(outputdir, pattern = "plots_to_check_data_quality_1.pdf", recursive = TRUE, full.names = TRUE)
shell.exec(pdffile)

# look at the visual output to make sure all is okay before moving to next stage.  If not, then look at more data quality parameters in outputdir 
# If all okay, move to z:, next stage
# no need to save pdf


#=============================================================================================
#
# Stage 4 Extract the csv time series and GGIR variables into results folders in Z:

#=============================================================================================

# Extract studyID from the single cwa file
cwa_name <- list.files(datadir)[1]  # Get the single file name
name <- substr(cwa_name, start = 5, stop = 11)  # Extract the study ID (first 7 characters)

# copy the csv file for each participant to csv_files results folder on Z:
new_filename <- paste0("acc_timeseries_", name, "_",format(Sys.Date(), "%d%m%Y"), ".RData")
add_path_to_csv <- paste0("output_",name,"/meta/csv")
csv_folder <- file.path(outputdir, add_path_to_csv)
rdata_file <- list.files(csv_folder,  full.names = TRUE) #assuming only one file 
new_file_path <- file.path("Z:/Axivity/Results/csv_files", new_filename)
file.copy(rdata_file, new_file_path)

# move the ggir data for each participant to ggir_variables folder on Z:
new_filename_ggir <- paste0("acc_ggir_", name, ".csv")
add_path_to_ggir_data <- paste0("output_",name,"/Results")
ggir_folder <- file.path(outputdir, add_path_to_ggir_data) #define the folder with sleep data and other resutls
data_file_ggir <- list.files(ggir_folder, pattern = "part4_summary_sleep_cleaned.csv", full.names = TRUE) #get the sleep data we need
new_file_path_ggir <- file.path("Z:/Axivity/Results/ggir_variables", new_filename_ggir)
file.copy(data_file_ggir, new_file_path_ggir)




#================================================================================================
#
# Stage 5 Transfer all generated GGIR data to Z: and delete temporary local files
#
#================================================================================================

# Z:\Axivity\studyID_GGIR_output - this folder collects all GGIR data for future projects
move_GGIR_results <- "Z:/Axivity/Results/GGIR_output"  # Path to create GGIR results folder for each participant and move results there

# Get the list of files in the Axivity output local folder
files <- list.files(outputdir, full.names = TRUE)

# Define the source and destination paths
source_dir <- files  # dir to move
destination_dir <- file.path(move_GGIR_results)  # Full path of destination

# Copy the entire directory including subdirectories and files
file.copy(source_dir, destination_dir, recursive = TRUE)
rm(list=ls(all=TRUE)) # clear environment


# Restart the R session (this will reset the environment)
restartSession()

