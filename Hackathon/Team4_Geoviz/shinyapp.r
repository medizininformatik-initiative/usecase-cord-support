#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

packages <- c("config","dplyr", "ggmap", "ggplot2", "knitr", "leaflet", "pander", "readr", "sf", "stringr", "tidygeocoder", "tidyr","shiny","utils","gridExtra")
#install.packages(setdiff(packages, rownames(installed.packages())))
lapply(packages, require, character.only = TRUE)

conf <- config::get(file = paste0(getwd(),"/config/conf.yml"))

Sys.setenv(http_proxy=conf$http_proxy)
Sys.setenv(https_proxy=conf$https_proxy)
load('data.RData')

cracked_result <- read_delim(file = conf$cracked_result,delim = ";",col_types = cols(patient_id = col_character(), age = col_integer(), gender = col_character(), hospital_name = col_character(), hospital_zip = col_character(), patient_zip = col_character(), diagnosis = col_character()))
distance_result <- read_delim(file = conf$distance_result,delim = ";",col_types = cols(patient_id = col_character(), age = col_integer(), gender = col_character(), hospital_name = col_character(), hospital_zip = col_character(), patient_zip = col_character(), diagnosis = col_character(), bird_flight_distance = col_character(), route_distance = col_character()))

# baseurl = "data/"

# Define a function to fix the bounding box to be in EPSG:3857
ggmap_bbox <- function(map) {
  if (!inherits(map, "ggmap")) stop("map must be a ggmap object")
  # Extract the bounding box (in lat/lon) from the ggmap to a numeric vector, 
  # and set the names to what sf::st_bbox expects:
  map_bbox <- setNames(unlist(attr(map, "bb")), 
                       c("ymin", "xmin", "ymax", "xmax"))
  
  # Convert the bbox to an sf polygon, transform it to 3857, 
  # and convert back to a bbox (convoluted, but it works)
  bbox_3857 <- st_bbox(st_transform(st_as_sfc(st_bbox(map_bbox, crs = 4326)), 3857))
  
  # Overwrite the bbox of the ggmap object with the transformed coordinates 
  attr(map, "bb")$ll.lat <- bbox_3857["ymin"]
  attr(map, "bb")$ll.lon <- bbox_3857["xmin"]
  attr(map, "bb")$ur.lat <- bbox_3857["ymax"]
  attr(map, "bb")$ur.lon <- bbox_3857["xmax"]
  map
}

# Load ICD10-GM catalog & hierarchy
# icdcatalog <- read_delim(paste0(baseurl, "d_med_adm_icd.csv"),
#                          delim = ";",
#                          skip = 0,
#                          col_types = cols(.default = col_character(),version_id = col_double(),version_valid_from = col_date(format = ""),version_valid_to = col_date(format = ""),icd_raredisease_flag = col_double(),icd_ifsg_notification_flag = col_double(),icd_ifsg_lab_flag = col_double()))

# Download & extract shapes of German administrative regions from https://gadm.org/ unless already available
#if (!file.exists("data/gadm36_DEU.gpkg")) {
# download.file("https://biogeo.ucdavis.edu/data/gadm3.6/gpkg/gadm36_DEU_gpkg.zip", "data/gadm36_DEU_gpkg.zip")
# unzip("data/gadm36_DEU_gpkg.zip", "gadm36_DEU.gpkg", junkpaths = TRUE)
#}

# Load shapes of German states
# shapes.bundeslaender <- st_read("data/gadm36_DEU.gpkg", layer="gadm36_DEU_1", quiet = TRUE)
#shapes.bundeslaender <- read.csv(file = paste("data/shapes.bundeslaender.csv"),sep = ";")

# Load mapping of German states to unique codes
# mapping.bundeslaender <- read_delim(paste0(baseurl, "map_bundesland.csv"), 
#                                     delim = ";",
#                                     col_types = cols(bundesland_team3 = col_character(), bundesland_name = col_character(), bundesland_code = col_character(), bundesland_ags_code = col_character()))

# Load Basemap for Germany
boundingbox <- c(4.3451573, 46.9942196, 15.5267352, 55.176929)
#map.germany <- get_stamenmap(bbox = boundingbox, maptype="terrain", crop=TRUE, zoom = 7)

# Remap bounding box to ggmap coordinate system
#map.germany <- ggmap_bbox(map.germany)

# Load aggregate 1 (age group & gender by site)
agg1 <- read_delim(conf$aggregation1_op,
                   delim = ";",
                   col_types = cols(hospital_name = col_character(), hospital_zip = col_character(), age = col_character(), gender = col_character(), count = col_double()))
agg1_raw <- agg1

# Extract age group intervals
agg1 <- agg1 %>% 
  extract(col = age, into = c("age_from", "age_to"), regex = '[\\]|\\[](\\d+), *(\\d+)\\]', remove = FALSE, convert = TRUE) %>%
  mutate(age_binwidth = age_to - age_from,
         age_center   = age_from + age_binwidth / 2) %>%
  arrange(age_from)

# Pivot gender from long to wide
agg1 <- agg1 %>% pivot_wider(names_from = gender, values_from = count)

# Load aggregate 2 (birdflight distance group)
agg2 <- read_delim(conf$aggregation2_op,
                   delim = ";",
                   col_types = cols(hospital_name = col_character(), hospital_zip = col_character(), bird_flight_distance = col_character(), count = col_double()))
agg2_raw <- agg2

# Extract distance group intervals & percentiles
agg2 <- agg2 %>%
  extract(col = bird_flight_distance, into = c("bird_flight_distance_from", "bird_flight_distance_to"), regex = '[\\]|\\[](\\d+), *(\\d+)\\]', remove = FALSE, convert = TRUE) %>%
  mutate(bird_flight_distance_binwidth = bird_flight_distance_to - bird_flight_distance_from,
         bird_flight_distance_center = bird_flight_distance_from + bird_flight_distance_binwidth / 2) %>%
  arrange(bird_flight_distance_from) %>%
  mutate(percentile = cumsum(count)/sum(count)*100)

# Load aggregate 3 (diagnosis)
agg3 <- read_delim(conf$aggregation3_op,
                   delim = ";",
                   col_types = cols(hospital_name = col_character(), hospital_zip = col_character(), diagnosis_1 = col_character(), diagnosis_2 = col_character(), count = col_double()))
agg3_raw <- agg3

# Merge first & second diagnosis codes
agg3.diagnosis_1 <- agg3 %>% 
  select(hospital_name, hospital_zip, diagnosis_1, count) %>% 
  rename(diagnosis = diagnosis_1)
agg3.diagnosis_2 <- agg3 %>% 
  filter(!is.na(diagnosis_2)) %>% 
  select(hospital_name, hospital_zip, diagnosis_2, count) %>% 
  rename(diagnosis = diagnosis_2)
agg3 <- bind_rows(agg3.diagnosis_1, agg3.diagnosis_2) %>% 
  group_by(hospital_name, hospital_zip, diagnosis) %>%
  summarize(count = sum(count), .groups = "keep")

# Add ICD10-GM chapter names and 3-digit code names
agg3.icd3 <- agg3 %>% 
  inner_join(icdcatalog %>% select(chapter_code, chapter_name, icd3_code, icd3_name) %>% distinct(), by = c("diagnosis" = "icd3_code")) %>%
  group_by(hospital_name, hospital_zip, diagnosis, icd3_name, chapter_code, chapter_name)

# Load aggregate 4 (diagnosis, age group)
agg4 <- read_delim(conf$aggregation4_op,
                   delim = ";",
                   col_types = cols(hospital_name = col_character(), hospital_zip = col_character(), diagnosis_1 = col_character(), diagnosis_2 = col_character(), age = col_character(), count = col_double()))
agg4_raw <- agg4

# Merge first & second diagnosis codes
agg4.diagnosis_1 <- agg4 %>% 
  select(hospital_name, hospital_zip, diagnosis_1, age, count) %>% 
  rename(diagnosis = diagnosis_1)
agg4.diagnosis_2 <- agg4 %>% 
  filter(!is.na(diagnosis_2)) %>% 
  select(hospital_name, hospital_zip, diagnosis_2, age, count) %>% 
  rename(diagnosis = diagnosis_2)
agg4 <- bind_rows(agg4.diagnosis_1, agg4.diagnosis_2) %>% 
  group_by(hospital_name, hospital_zip, diagnosis, age) %>%
  summarize(count = sum(count), .groups = "keep")

# Extract age group intervals
agg4 <- agg4 %>% 
  extract(col = age, into = c("age_from", "age_to"), regex = '[\\]|\\[](\\d+), *(\\d+)\\]', remove = FALSE, convert = TRUE) %>%
  mutate(age_binwidth = age_to - age_from,
         age_center   = age_from + age_binwidth / 2) %>%
  arrange(age_from)

# Add ICD10-GM chapter names and 3-digit code names
agg4.icd3 <- agg4 %>% 
  inner_join(icdcatalog %>% select(chapter_code, chapter_name, icd3_code, icd3_name) %>% distinct(), by = c("diagnosis" = "icd3_code")) %>%
  group_by(hospital_name, hospital_zip, diagnosis, icd3_name, chapter_code, chapter_name)

# Aggregate to ICD10-GM chapters
agg4.chapters <- agg4.icd3 %>%
  group_by(hospital_name, hospital_zip, age, age_from, age_to, age_binwidth, age_center, chapter_code, chapter_name) %>%
  summarize(count = sum(count), .groups = "keep") %>%
  mutate(chapter_codename = paste0(chapter_code, ". ", chapter_name))

# Load aggregate 5 (diagnosis, gender)
agg5 <- read_delim(conf$aggregation5_op,
                   delim = ";",
                   col_types = cols(hospital_name = col_character(), hospital_zip = col_character(), diagnosis_1 = col_character(), diagnosis_2 = col_character(), gender = col_character(), count = col_double()))
agg5_raw <- agg5

# Merge first & second diagnosis codes
agg5.diagnosis_1 <- agg5 %>% 
  select(hospital_name, hospital_zip, diagnosis_1, gender, count) %>% 
  rename(diagnosis = diagnosis_1)
agg5.diagnosis_2 <- agg5 %>% 
  filter(!is.na(diagnosis_2)) %>% 
  select(hospital_name, hospital_zip, diagnosis_2, gender, count) %>% 
  rename(diagnosis = diagnosis_2)
agg5 <- bind_rows(agg5.diagnosis_1, agg5.diagnosis_2) %>% 
  group_by(hospital_name, hospital_zip, diagnosis, gender) %>%
  summarize(count = sum(count), .groups = "keep")

# Add ICD10-GM chapter names and 3-digit code names
agg5.icd3 <- agg5 %>% 
  inner_join(icdcatalog %>% select(chapter_code, chapter_name, icd3_code, icd3_name) %>% distinct(), by = c("diagnosis" = "icd3_code")) %>%
  group_by(hospital_name, hospital_zip, diagnosis, icd3_name, chapter_code, chapter_name)

# Pivot gender from long to wide format
agg5.combined <- agg5.icd3 %>%
  pivot_wider(names_from = gender, values_from = count, values_fill = 0)

# Load aggregate 6 (diagnosis, distance group)
agg6 <- read_delim(conf$aggregation6_op,
                   delim = ";",
                   col_types = cols(hospital_name = col_character(), hospital_zip = col_character(), diagnosis_1 = col_character(), diagnosis_2 = col_character(), bird_flight_distance = col_character(), count = col_double()))
agg6_raw <- agg6

# Merge first & second diagnosis codes
agg6.diagnosis_1 <- agg6 %>% 
  select(hospital_name, hospital_zip, diagnosis_1, bird_flight_distance, count) %>% 
  rename(diagnosis = diagnosis_1)
agg6.diagnosis_2 <- agg6 %>% 
  filter(!is.na(diagnosis_2)) %>% 
  select(hospital_name, hospital_zip, diagnosis_2, bird_flight_distance, count) %>% 
  rename(diagnosis = diagnosis_2)
agg6 <- bind_rows(agg6.diagnosis_1, agg6.diagnosis_2) %>% 
  group_by(hospital_name, hospital_zip, diagnosis, bird_flight_distance) %>%
  summarize(count = sum(count), .groups = "keep")

# Extract distance group intervals & percentiles
agg6 <- agg6 %>%
  extract(col = bird_flight_distance, into = c("bird_flight_distance_from", "bird_flight_distance_to"), regex = '[\\]|\\[](\\d+), *(\\d+)\\]', remove = FALSE, convert = TRUE) %>%
  mutate(bird_flight_distance_binwidth = bird_flight_distance_to - bird_flight_distance_from,
         bird_flight_distance_center = bird_flight_distance_from + bird_flight_distance_binwidth / 2) %>%
  arrange(bird_flight_distance_from) %>%
  mutate(percentile = cumsum(count)/sum(count)*100)

# Add ICD10-GM chapter names and 3-digit code names
agg6.icd3 <- agg6 %>% 
  inner_join(icdcatalog %>% select(chapter_code, chapter_name, icd3_code, icd3_name) %>% distinct(), by = c("diagnosis" = "icd3_code")) %>%
  group_by(hospital_name, hospital_zip, diagnosis, icd3_name, chapter_code, chapter_name)

# Aggregate to ICD10-GM chapters
agg6.chapters <- agg6.icd3 %>%
  group_by(hospital_name, hospital_zip, bird_flight_distance, bird_flight_distance_from, bird_flight_distance_to, bird_flight_distance_binwidth, bird_flight_distance_center, chapter_code, chapter_name) %>%
  summarize(count = sum(count), .groups = "keep") %>%
  mutate(chapter_codename = paste0(chapter_code, ". ", chapter_name)) %>%
  group_by(chapter_code) %>%
  arrange(chapter_code, bird_flight_distance_center) %>%
  mutate(percentile = cumsum(count)/sum(count)*100)

# Load aggregate 6 (diagnosis, distance group)
agg7 <- read_delim(conf$aggregation7_op,
                   delim = ";",
                   col_types = cols(hospital_name = col_character(), hospital_zip = col_character(), diagnosis_1 = col_character(), diagnosis_2 = col_character(), patient_zip = col_character(), count = col_double()))
agg7_raw <- agg7

# Merge first & second diagnosis codes
agg7.diagnosis_1 <- agg7 %>% 
  select(hospital_name, hospital_zip, diagnosis_1, patient_zip, count) %>% 
  rename(diagnosis = diagnosis_1)
agg7.diagnosis_2 <- agg7 %>% 
  filter(!is.na(diagnosis_2)) %>% 
  select(hospital_name, hospital_zip, diagnosis_2, patient_zip, count) %>% 
  rename(diagnosis = diagnosis_2)
agg7 <- bind_rows(agg7.diagnosis_1, agg7.diagnosis_2) %>% 
  group_by(hospital_name, hospital_zip, diagnosis, patient_zip) %>%
  summarize(count = sum(count), .groups = "keep")

# Add ICD10-GM chapter names and 3-digit code names
agg7.icd3 <- agg7 %>% 
  inner_join(icdcatalog %>% select(chapter_code, chapter_name, icd3_code, icd3_name) %>% distinct(), by = c("diagnosis" = "icd3_code")) %>%
  group_by(hospital_name, hospital_zip, diagnosis, icd3_name, chapter_code, chapter_name)

# Aggregate to states & ICD10-GM chapters
agg7.chapters <- agg7.icd3 %>%
  group_by(hospital_name, hospital_zip, patient_zip, chapter_code, chapter_name) %>%
  summarize(count = sum(count), .groups = "keep") %>%
  mutate(chapter_codename = paste0(chapter_code, ". ", chapter_name))

# Aggregate to states
agg7.states <- agg7 %>%
  group_by(patient_zip) %>% summarize(count = sum(count), .groups = "keep") %>%
  summarize(count = sum(count), .groups = "keep") %>%
  inner_join(mapping.bundeslaender %>% select(bundesland_team3, bundesland_ags_code, bundesland_name), 
             by = c("patient_zip" = "bundesland_team3")) 

## Overall distribution of rare disease patients and states

# Geocode hospital location
agg7.hospitals <- agg7 %>%
  ungroup() %>%
  select(hospital_zip, hospital_name) %>%
  distinct() %>%
  mutate(addr = paste0(hospital_zip, " ", hospital_name))
agg7.hospitals <- agg7.hospitals %>%
  geocode(addr, method = 'osm', lat = latitude , long = longitude)

# Calculate radius of overall catchment area of the hospital (80% of overall patients)
agg2.catchment_area <- agg2 %>% filter(percentile > 80) %>% filter(row_number() == 1) %>% select(bird_flight_distance_center) %>% rename(catchment_area = bird_flight_distance_center)
agg7.hospitals$catchment_area <- agg2.catchment_area$catchment_area
agg7.hospitals$catchment_area_label <- paste0("Einzugsgebiet (80% der Patienten): ", agg7.hospitals$catchment_area, "km")

# Merge der Fallzahlen mit den Shapes
agg7.mapdata <- shapes.bundeslaender %>%
  left_join(agg7.states, by = c("CC_1" = "bundesland_ags_code")) %>%
  mutate(label = paste0(NAME_1, ": ", ifelse(is.na(count), 0, count), " Fälle"))

# Transform shapes to EPSG3857 coordinate system used by ggmap
agg7.mapdata3857 <- st_transform(agg7.mapdata, 3857)

# Loop over ICD10-GM chapters
agg7.chapter_maps <- NULL
for(code in levels(as.factor(agg7.chapters$chapter_code))) {
  
  # Aggregation of patients within the current chapter
  agg <- agg7.chapters %>%
    filter(chapter_code == code) %>%
    inner_join(mapping.bundeslaender %>% select(bundesland_team3, bundesland_ags_code), 
               by = c("patient_zip" = "bundesland_team3")) 
  
  # Merge der Fallzahlen mit den Shapes
  mapdata <- shapes.bundeslaender %>%
    left_join(agg, by = c("CC_1" = "bundesland_ags_code")) %>%
    mutate(chapter_code = code, 
           label = paste0(ifelse(is.na(count), 0, count), " Patienten"),
           group = paste0("ICD-Kapitel ", code)) %>%
    replace_na(list(count = 0))
  
  # Karte für das ICD-Kapitel plotten
  #    ggplot2::ggplot() +
  #        geom_sf(data=mapdata, aes(fill = anzahl), color="black", size=0.1, alpha=0.5) +
  #        scale_fill_fermenter(palette="Spectral", trans="log", breaks = c(1, 10, 100, 1000, 10000, 100000), na.value='#bbbbbb')
  
  # Append map data of current ICD10-GM chapter to tibble
  agg7.chapter_maps <- agg7.chapter_maps %>% bind_rows(mapdata)
}

# Calculate catchment area radius (80% der Patienten) per ICD10-GM chapter
agg7.chapter_hospitals <- agg6.chapters %>% 
  group_by(chapter_code) %>% 
  filter(percentile > 80) %>% 
  filter(row_number() == 1) %>% 
  select(chapter_code, bird_flight_distance_center) %>% 
  rename(catchment_area = bird_flight_distance_center) %>%
  mutate(catchment_area_label = paste0("Einzugsgebiet (80% der Patienten) für ICD-Kapitel ", chapter_code, ": ", catchment_area, "km"),
         group = paste0("ICD-Kapitel ", chapter_code)) %>%
  bind_cols(agg7.hospitals %>% select(addr, latitude, longitude))

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("CORD Schaufenster Visualisierung"),    
  # Sidebar with Radio Button choices
  sidebarLayout(
    sidebarPanel(
      radioButtons(inputId = "plotKind", label = "Please choose...", 
                   choices = c('Aggregation 1: Age group & gender'='agg1' 
                               ,'Aggregation 2: Birdflight distance group'='agg2'
                               ,'Aggregation 3: Diagnosis (ICD10-GM 3-digit code)'='agg3'
                               ,'Aggregation 4: Diagnosis (ICD10-GM 3-digit code) & age group'='agg4'
                               ,'Aggregation 5: Diagnosis (ICD10-GM 3-digit code) & gender'='agg5'
                               ,'Aggregation 6: Diagnosis (ICD10-GM 3-digit code) & distance group'='agg6'
                               #,'Aggregation 6: Diagnosis (ICD10-GM 3-digit code) & distance group'='agg62'
                               ,'Aggregation 7: Diagnosis (ICD10-GM 3-digit code) and state'='agg7'
                               #,'agg7 plot static maps of ICD10-GM chapters vs. state'='agg72'
                               #'agg7 plot leaflet map with layers for overall & chapter-based data'='agg73'
                   ), selected = c('agg1'), inline = F),
      #      radioButtons(inputId = "plotKind", label = "Please choose...", choices = c('agg1 (breakdown by age group & gender)'='agg1', 'agg2 (breakdown by birdflight distance group)'='agg2','agg3 (breakdown by 3-digit ICD diagnosis)'='agg3','agg4 (breakdown by 3-digit ICD diagnosis & age group)'='agg4','agg5 (breakdown by 3-digit ICD diagnosis & gender)'='agg5','agg6 (breakdown by 3-digit ICD diagnosis & birdflight distance group)1'='agg61','agg6 (breakdown by 3-digit ICD diagnosis & birdflight distance group)2'='agg62','agg7 (breakdown by state & 3-digit ICD diagnosis)1'='agg71','agg7 (breakdown by state & 3-digit ICD diagnosis)2'='agg72','agg7 (breakdown by state & 3-digit ICD diagnosis)3'='agg73'), selected = c('agg1'), inline = F)
      #downloadButton('cracked_result',paste0("Download ",conf$cracked_result)),
      #downloadButton('distance_result',paste0("Download ",conf$distance_result)),
      #downloadButton('agg1',paste0("Download ",conf$aggregation1_op)),
      #downloadButton('agg2',paste0("Download ",conf$aggregation2_op)),
      #downloadButton('agg3',paste0("Download ",conf$aggregation3_op)),
      #downloadButton('agg4',paste0("Download ",conf$aggregation4_op)),
      #downloadButton('agg5',paste0("Download ",conf$aggregation5_op)),
      #downloadButton('agg6',paste0("Download ",conf$aggregation6_op)),
      #downloadButton('agg7',paste0("Download ",conf$aggregation7_op)),
      downloadButton('datazip',"Download data.zip"),
      downloadButton('vispdf',"Download visualization.pdf")
    ),
    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("seriesPlot")
      #,leafletOutput("map")
    )
  ),
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  library(tidyverse)
  library(ggplot2)
  output$cracked_result <- downloadHandler(
    filename = function(){conf$cracked_result}, 
    content = function(fname){
      write.csv2(cracked_result, fname,row.names=F,quote=F)
    }
  )
  output$distance_result <- downloadHandler(
    filename = function(){conf$distance_result}, 
    content = function(fname){
      write.csv2(distance_result, fname,row.names=F,quote=F)
    }
  )
  output$agg1 <- downloadHandler(
    filename = function(){conf$aggregation1_op}, 
    content = function(fname){
      write.csv2(agg1_raw, fname,row.names=F,quote=F)
    }
  )
  output$agg2 <- downloadHandler(
    filename = function(){conf$aggregation2_op}, 
    content = function(fname){
      write.csv2(agg2_raw, fname,row.names=F,quote=F)
    }
  )
  output$agg3 <- downloadHandler(
    filename = function(){conf$aggregation3_op}, 
    content = function(fname){
      write.csv2(agg3_raw, fname,row.names=F,quote=F)
    }
  )
  output$agg4 <- downloadHandler(
    filename = function(){conf$aggregation4_op}, 
    content = function(fname){
      write.csv2(agg4_raw, fname,row.names=F,quote=F)
    }
  )
  output$agg5 <- downloadHandler(
    filename = function(){conf$aggregation5_op}, 
    content = function(fname){
      write.csv2(agg5_raw, fname,row.names=F,quote=F)
    }
  )
  output$agg6 <- downloadHandler(
    filename = function(){conf$aggregation6_op}, 
    content = function(fname){
      write.csv2(agg6_raw, fname,row.names=F,quote=F)
    }
  )
  output$agg7 <- downloadHandler(
    filename = function(){conf$aggregation7_op}, 
    content = function(fname){
      write.csv2(agg7_raw, fname,row.names=F,quote=F)
    }
  )
  output$datazip <- downloadHandler(
    filename <- function(){'data.zip'},
    content <- function(file) {
      file.copy("data/data.zip", file)
    },
    contentType = "application/zip"
  )
  output$vispdf <- downloadHandler(
    filename <- function(){'visualization.pdf'},
    content <- function(file) {
      file.copy("data/visualization.pdf", file)
    },
    contentType = "application/pdf"
  )
  output$seriesPlot <- renderPlot({
    
    if("agg1" %in% input$plotKind)
    {
      # Plot age pyramid
      options(repr.plot.width = 10, repr.plot.height = 7.5)
      ggplot2::ggplot(data = agg1) +
        geom_rect(aes(ymin = age_from, ymax = age_to, xmin = -female / age_binwidth, xmax = 0                  ), fill="red",  color = "black", alpha = 0.5) +
        geom_rect(aes(ymin = age_from, ymax = age_to, xmin = 0,                      xmax = male / age_binwidth), fill="blue", color = "black", alpha = 0.5) +
        labs(title = "Aggregation 1: Age group & gender\n", x = "count", y = "age")
    }
    else if("agg2" %in% input$plotKind)
    {
      # Plot barchart for distance groups
      options(repr.plot.width = 10, repr.plot.height = 5)
      ggplot2::ggplot(agg2) +
        geom_rect(aes(xmin = bird_flight_distance_from, xmax = bird_flight_distance_to, ymin = 0, ymax = count / bird_flight_distance_binwidth), fill="grey", color="black") +
        labs(title = "Aggregation 2: Birdflight distance group\n", x = "distance", y = "percentage")
    }
    else if("agg3" %in% input$plotKind)
    {
      # Plot barchart of 3-digit-codes, grouped & coloured by ICD chapter
      options(repr.plot.width = 10, repr.plot.height = 10)
      ggplot2::ggplot(data = agg3.icd3, aes(x = diagnosis, y = count, fill = chapter_code)) +
        geom_bar(stat = "identity") +
        coord_flip() +
        labs(title = "Aggregation 3: Diagnosis (ICD10-GM 3-digit code)\n", x = "diagnosis", y = "count")
    }
    else if("agg4" %in% input$plotKind)
    {
      # Scatterplot of ICD10-GM chapters vs. age groups
      options(repr.plot.width = 10, repr.plot.height = 5)
      ggplot2::ggplot(data = agg4.chapters, aes(x = age_center, y=chapter_code)) +
        geom_point(aes(size = count, color=chapter_code), alpha = 0.75) +
        theme(legend.text=element_text(size=6)) +
        labs(title = "Aggregation 4: Diagnosis (ICD10-GM 3-digit code) & age group\n", x = "age_center", y = "chapter_code")
    }
    else if("agg5" %in% input$plotKind)
    {
      # Plot barchart of 3-digit ICD code and gender
      options(repr.plot.width = 10, repr.plot.height = 10)
      ggplot2::ggplot(data = agg5.combined) +
        geom_bar(aes(x = diagnosis, y = -female, fill = chapter_code), stat="identity") +
        geom_bar(aes(x = diagnosis, y =  male,   fill = chapter_code), stat="identity") +
        coord_flip() +
        labs(title = "Aggregation 5: Diagnosis (ICD10-GM 3-digit code) & gender\n", y = "- female / + male", x = "chapter_code")
    }
    else if("agg6" %in% input$plotKind)
    {
      # Scatterplot chapters vs. distance group
      options(repr.plot.width = 100, repr.plot.height = 50)
      p1 <- ggplot2::ggplot(data = agg6.chapters, aes(x = bird_flight_distance_center, y=chapter_code)) +
        geom_point(aes(size = count, color=chapter_code), alpha = 0.75) +
        theme(legend.text=element_text(size=6)) +
        labs(title = "Aggregation 6: Diagnosis (ICD10-GM 3-digit code) & distance group\n", x = "bird_flight_distance_center", y = "chapter_code")
      
      # Scatterplot 3-digit codes vs. distance group
      #options(repr.plot.width = 10, repr.plot.height = 10)
      p2 <- ggplot2::ggplot(data = agg6.icd3, aes(x = bird_flight_distance_center, y=diagnosis)) +
        geom_point(aes(size = count, color=chapter_code), alpha = 0.75) +
        theme(legend.text=element_text(size=6)) +
        labs(x = "bird_flight_distance_center", y = "diagnosis")
      
      grid.arrange(p1, p2, ncol = 2)
    }
    else if("agg62" %in% input$plotKind)
    {
      # Scatterplot 3-digit codes vs. distance group
      options(repr.plot.width = 10, repr.plot.height = 10)
      ggplot2::ggplot(data = agg6.icd3, aes(x = bird_flight_distance_center, y=diagnosis)) +
        geom_point(aes(size = count, color=chapter_code), alpha = 0.75) +
        theme(legend.text=element_text(size=6)) +
        labs(title = "Aggregation 6: Diagnosis (ICD10-GM 3-digit code) & distance group\n", x = "bird_flight_distance_center", y = "diagnosis")
    }
    else if("agg7" %in% input$plotKind)
    {
      # Plot static ggmap
      p3 <- ggmap(map.germany) + 
        geom_sf(data = agg7.mapdata3857, aes(fill = count), color = "black", size=0.1, alpha=0.5, inherit.aes = FALSE) +
        scale_fill_fermenter(palette = "Spectral", trans = "log", breaks = c(1 ,10, 100, 1000, 10000, 100000), na.value='#bbbbbb') +
        theme(axis.title = element_blank(), axis.text = element_blank(), axis.ticks = element_blank()) +
        labs(title = "Aggregation 7: Diagnosis (ICD10-GM 3-digit code) and state\nOverall distribution of rare disease patients and states")
      # Plot static maps of ICD10-GM chapters vs. state
      options(repr.plot.width = 20, repr.plot.height = 15)
      p4 <- ggplot2::ggplot() +
        geom_sf(data=agg7.chapter_maps, aes(fill = count), color="black", size=0.1, alpha=0.5) +
        scale_fill_fermenter(palette="Spectral", trans="log", breaks = c(1, 10, 100, 1000, 10000, 100000), na.value='#bbbbbb') +
        theme(axis.title = element_blank(), axis.text = element_blank(), axis.ticks = element_blank()) +
        facet_wrap(~group, ncol = 5) +
        labs(title = "ICD10-GM chapter distribution of rare disease patients by state\n")
      
      grid.arrange(p3, p4, ncol = 2)
    }
    else if("agg72" %in% input$plotKind)
    {
      # Plot static maps of ICD10-GM chapters vs. state
      options(repr.plot.width = 20, repr.plot.height = 15)
      ggplot2::ggplot() +
        geom_sf(data=agg7.chapter_maps, aes(fill = count), color="black", size=0.1, alpha=0.5) +
        scale_fill_fermenter(palette="Spectral", trans="log", breaks = c(1, 10, 100, 1000, 10000, 100000), na.value='#bbbbbb') +
        theme(axis.title = element_blank(), axis.text = element_blank(), axis.ticks = element_blank()) +
        facet_wrap(~group, ncol = 5) +
        labs(title = "chapter count in states\n")
    }
  })
  output$map <- renderLeaflet({
    #if("agg73" %in% input$plotKind)
    {
      # Show heading for leaflet map only in HTML output
      #pandoc.header("Interactive map of overall or ICD10-GM chapter distribution of rare disease patients vs states", level = 2)
      
      # Prepare color scale
      pal <- colorBin(
        palette = "Spectral",
        bins = c(1, 10, 100, 1000, 10000, 100000),
        reverse = TRUE
      )
      # Plot leaflet map with layers for overall & chapter-based data
      layers <- c("Alle Patienten", levels(as.factor(agg7.chapter_maps$group)))
      options(repr.plot.width = 10, repr.plot.height = 10)
      leaflet(data = agg7.mapdata, width = "100%", height = "600px") %>%
        addTiles() %>%
        addPolygons(color = "black", 
                    weight = 0.5, 
                    opacity = 1, 
                    fillColor = ~pal(count),
                    fillOpacity = 0.5,
                    label = ~label,
                    group = "Alle Patienten") %>%
        addPolygons(data = agg7.chapter_maps,
                    color = "black", 
                    weight = 0.5, 
                    opacity = 1, 
                    fillColor = ~pal(count),
                    fillOpacity = 0.5,
                    label = ~label,
                    group = ~group) %>%
        addMarkers(data = agg7.hospitals, 
                   ~longitude, 
                   ~latitude,
                   label = ~addr) %>%
        addCircles(data = agg7.hospitals,
                   ~longitude, 
                   ~latitude,
                   ~catchment_area*1000,
                   color = "black",
                   opacity = 1,
                   weight = 0.5,
                   label = ~catchment_area_label,
                   group = "Alle Patienten") %>%
        addCircles(data = agg7.chapter_hospitals,
                   ~longitude, 
                   ~latitude,
                   ~catchment_area*1000,
                   color = "black",
                   opacity = 1,
                   weight = 0.5,
                   label = ~catchment_area_label,
                   group = ~group) %>%
        addLegend(pal = pal, values = ~count, title = "Anzahl Patienten",
                  position = "bottomright") %>%
        addLayersControl(overlayGroups = layers,
                         position = "topright",
                         options = layersControlOptions(collapsed = FALSE)) %>%
        hideGroup(layers[2:length(layers)]) # Hide ICD10-GM chapter layers initially
    }
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
