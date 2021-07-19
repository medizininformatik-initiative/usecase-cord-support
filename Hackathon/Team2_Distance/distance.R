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
zip_coord  <- read_xlsx(path =paste(getwd(),"/data/PLZ_manual_correction.cleaned.xlsx",sep = "") )# file for calculating birdflight distance with approximately 8295 plz entries

# input file for patient longitude and latitude
ptzip_coord <- read.csv(file = paste(getwd(),"/data/PLZ_pat_manual_cleaned.csv",sep = ""),sep = ";")

#  read the input file from fhircrackr team 1 step in the pre-defined format i.e pseudonym; alter; geschlecht; zentrum_name; zentrum_plz;patient_plz; icd_code
dat_orig <- read.csv(file = paste(getwd(),"/input/result.csv",sep = ""),sep = ";")# output from fhircrackr team 1

# leading zeros to zipcode
ptzip_coord$zipcode2<- stringr::str_pad(ptzip_coord$zipcode, 5, side = "left", pad = 0)

zip_coord <- mutate(zip_coord, kh_plz, kh_plz2 = as.numeric(kh_plz))
ptzip_coord <- mutate(ptzip_coord, zipcode, zipcode2 = as.numeric(zipcode))
#############################################################################################################################################################################################
# left join on  zip codes. 
################################################################################################################################################################
patzip_orig <- left_join(dat_orig,ptzip_coord,by=c("patient_zip" = "zipcode2"))
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

data <- select(patzip_orig,patient_id,age,gender,hospital_name,hospital_zip,patient_zip,longitude,latitude,diagnosis)

#center latitude and longitude 
center_tmp <- na.omit(inner_join(patzip_orig, zip_coord, by=c("hospital_zip" = "kh_plz2")))
center_long <- center_tmp$kh_plz_lon[1]
center_lat <- center_tmp$kh_plz_lat[1]

data <- data %>%
	# Creating a column with center longitude data 
	add_column(dest_plz_lon = center_long, .after="latitude")

data <- data %>%
	# Creating a column with center latitude data 
	add_column(dest_plz_lat = center_lat, .after="dest_plz_lon")

# calculate the bird flight distance using the function defined
data_s <- data[,c('longitude','latitude','dest_plz_lon','dest_plz_lat')]
distance <- apply(data_s[1:4],1, birdflight_distance)
# round distance value
distance <- round(distance)
data <- data %>%
	# Creating a column with distance
	add_column(bird_flight_distance = distance, .after="diagnosis")

data <- data %>%
	# Creating a column with route distance
	add_column(route_distance = 0, .after="bird_flight_distance")    

#filter only selected columns
data <- data[,c('patient_id','age','gender', 'hospital_name', 'hospital_zip', 'patient_zip','diagnosis','bird_flight_distance','route_distance')]

# leading zeros to zip code
data$hospital_zip<- stringr::str_pad(data$hospital_zip, 5, side = "left", pad = 0)
data$patient_zip<- stringr::str_pad(data$patient_zip, 5, side = "left", pad = 0)

# write result to a csv file with semicolon as separator
write.csv2(data,file= "team2_result.csv",row.names=F)

