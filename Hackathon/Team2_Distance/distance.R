##################################################################################################################################################################################################
# Aim: To calculate birdflight distance, route distance and duration between patient and clinic locations and write them in an excel output file
# # before executing the code please create a folder 'entfernung' in the working directory and place the following two files in that folder
# PLZ_manual_correction.cleaned.xlsx file and result.csv file
# clinic location latitude and longitude read from config file
##################################################################################################################################################################################################
#if (!require('osrm')) install.packages('osrm')# open street map to calculate the route

if (!require('readr')) install.packages('readr')#
if (!require('tidyr')) install.packages('tidyr')#
if (!require('dplyr')) install.packages('dplyr')#
if (!require('geosphere')) install.packages('geosphere')# to calculate bird flight distance
library(readxl)
library(dplyr)
library(tidyr)
library(geosphere)
##############################################################################################################################################################################################
# Input files
# before executing the code please create a folder 'input' in the working directory and place the following two files in that folder
# patient location obtained from PLZ_manual_correction.cleaned.xlsx file
# result.csv file from team 1 fhircrackr 
# manually collected postal area codes in PLZ_manual_correction.cleaned.xlsx file if needed uncomment and use
#############################################################################################################################################################################################

plz_coord  <- read_xlsx(path =paste(getwd(),"/input/PLZ_manual_correction.cleaned.xlsx",sep = "") )# file for calculating birdflight distance with approximately 8295 plz entries

#############################################################################################################################################################################################
#  Read the input file from fhircrackr team 1 step in the pre-defined format i.e pseudonym; alter; geschlecht; zentrum_name; zentrum_plz;patient_plz; icd_code
#############################################################################################################################################################################################
dat_orig <- read.csv(file = paste(getwd(),"/input/result.csv",sep = ""),sep = ";")# output from fhircrackr team 1

#############################################################################################################################################################################################
# example config.yml file is as follows 
# default:
#    user: "username"
#    password: "password"
#    serverbase: 'http://hapi.fhir.org/fhir/'
#    hospital_name: 'Your Center'
#    hospital_zip: 'Center Zip Code'
#############################################################################################################################################################################################
webconn <- config::get(file = paste(getwd(),"/config/conf.yml",sep=""))

plz_coord <- mutate(plz_coord, kh_plz, kh_plz2 = as.numeric(kh_plz))
#############################################################################################################################################################################################
# inner join to identify and match only the available zip codes. Zipcode column from fhircrackr team 1 generated file is 'patient_zip'. Zipcode column from  PLZ_manual_correction.cleaned.xlsx
# is  "kh_plz2"
#############################################################################################################################################################################################
dat_orig <- inner_join(dat_orig, plz_coord, by=c("patient_zip" = "kh_plz2"))

#############################################################################################################################################################################################
#  Function to calculate the birdflight distance using Haversine distance
#############################################################################################################################################################################################
birdflight_distance <- function(v) {
	# unpacking lists (from tibble) to vectors
	source_long <- v[[1]]
	source_lat  <- v[[2]]
	dest_long   <- v[[3]]
	dest_lat    <- v[[4]]
	dist_km     <- distHaversine(p1 = c(source_long, source_lat),
				     p2 = c(dest_long, dest_lat))/1000
	return(dist_km)
}

#dat_orig2

data <- select(dat_orig, kh_plz_lon, kh_plz_lat )

data <- data %>%
	# Creating a column with center longitude data from config file
	add_column(dest_plz_lon = webconn$center_long, .after="kh_plz_lat")

data <- data %>%
	# Creating a column with center latitude data from config file
	add_column(dest_plz_lat = webconn$center_lat, .after="dest_plz_lon")

# change data type of destination i.e clinic location to numeric
data <- mutate(data, dest_plz_lon = as.numeric(dest_plz_lon))
data <- mutate(data, dest_plz_lat = as.numeric(dest_plz_lat))

#############################################################################################################################################################################################
# calculate the bird flight distance using the function defined
#############################################################################################################################################################################################
distance <- apply(data[1:4],1, birdflight_distance)

data <- data %>%
	# Creating a column with center zip code from config file as stated in the requirement
	add_column(bird_flight_distance = distance, .after="diagnosis")

data <- data %>%
	# Creating a column with center zip code from config file as stated in the requirement
	add_column(entfernung_route = 0, .after="bird_flight_distance")    

#filter only selected columns
data <- data[,c('patient_id','age','gender', 'hospital_name', 'hospital_zip', 'patient_zip','icd_code','bird_flight_distance','route_distance')]

#############################################################################################################################################################################################
# write result to a csv file
############################################################################################################################################################################################
write.csv2(data,file= "result.csv",row.names=F)
############################################################################################################################################################################################
