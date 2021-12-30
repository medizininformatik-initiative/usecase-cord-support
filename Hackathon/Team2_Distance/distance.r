if (!require('readr')) install.packages('readr')#
if (!require('tidyr')) install.packages('tidyr')#
if (!require('dplyr')) install.packages('dplyr')#
if (!require('tibble')) install.packages('tibble')#
if (!require('geosphere')) install.packages('geosphere')# to calculate bird flight distance
library(readxl)
library(dplyr)
library(tidyr)
library(tidyverse)
library(geosphere)
library(tibble) 
##############################################################################################################################################################################################
conf <- config::get(file = paste(getwd(),"/config/conf.yml",sep=""))

#  read the input file from fhircrackr team 1 step in the pre-defined format i.e pseudonym; alter; geschlecht; zentrum_name; zentrum_plz;patient_plz; icd_code
dat_orig <- read.csv(file = paste(getwd(),"/",conf$cracked_result,sep = ""),sep = ";")# output from fhircrackr team 1

# Input file for  longitude and latitude
ptzip_coord <- read.csv(file = paste(getwd(),"/",conf$plz_input,sep = ""),sep = ";")

#############################################################################################################################################################################################
# left join on  zip codes.
################################################################################################################################################################
patzip_orig <- left_join(dat_orig,ptzip_coord,by=c("patient_zip" = "zipcode"))
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

#print(data$hospital_zip[0])
#center latitude and longitude 
center_tmp <- na.omit(inner_join(patzip_orig, ptzip_coord, by=c("hospital_zip" = "zipcode")))
center_long <- center_tmp$longitude.y[1]
center_lat <- center_tmp$latitude.y[1]

data <- data %>%
	# Creating a column with center longitude data 
	add_column(dest_zip_lon = center_long, .after="latitude")

data <- data %>%
	# Creating a column with center latitude data 
	add_column(dest_zip_lat = center_lat, .after="dest_zip_lon")

#converting latitude to numeric because bird flight distance function requires numeric values
data <- mutate(data, latitude, latitude = as.numeric(latitude))
data <- mutate(data, dest_zip_lat, dest_zip_lat = as.numeric(dest_zip_lat))
# calculate the bird flight distance using the function defined
data_s <- data[,c('longitude','latitude','dest_zip_lon','dest_zip_lat')]
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

# write result to a csv file with semicolon as separator and remove quotes by setting quote parameter to  false
#write.csv2(data,file=conf$distance_result,row.names=F,quote=F)

an.error.occured <- FALSE

# write csv with ";" to file
tryCatch( {write.csv2(data,file=conf$distance_result,row.names=F,quote=F)},
           error = function(err) {an.error.occured <<-TRUE
              message("write to csv failed. This may be attributed to the missing object distance_result of the dataframe or the distance_result does not exists")
              message(err)
              })   
