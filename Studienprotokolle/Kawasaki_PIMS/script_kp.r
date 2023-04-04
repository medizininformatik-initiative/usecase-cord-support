####################################################################################################################
# To calculate the aggregate of patients corresponding to
# Kawasaki / PIMS
####################################################################################################################
start_time <- Sys.time()
options(warn = -1)# to suppress warnings
if (!require("fhircrackr")) {install.packages("fhircrackr"); library(fhircrackr)}
if (!require("config")) {install.packages("config"); library(config)}
if (!require("dplyr")) {install.packages("dplyr"); library(dplyr)}
if (!require("stringr")) {install.packages("stringr"); library(stringr)}

if (rstudioapi::isAvailable()){
  setwd(dirname(rstudioapi::getSourceEditorContext()$path))
  message("setting working directory to: ", getwd())
} else {
  setwd(getwd())
  message("setting working directory to: ", getwd())
}

dir.create(file.path(getwd(),"results"), showWarnings = FALSE)

conf <- config::get(file = paste(getwd(), "/conf.yml", sep = ""))

#check for proxy configuration
if (exists("http_proxy", where = conf) && nchar(conf$http_proxy) >= 1) {
  Sys.setenv(http_proxy = conf$http_proxy)
}

if (exists("https_proxy", where = conf) && nchar(conf$https_proxy) >= 1) {
  Sys.setenv(https_proxy = conf$https_proxy)
}

if (exists("no_proxy", where = conf) && nchar(conf$no_proxy) >= 1) {
  Sys.setenv(no_proxy = conf$no_proxy)
}

# check for custom recordedDate
if (exists("recordedDate_col", where = conf) && nchar(conf$recordedDate_col) >= 1) {
  recorded_date_custom <- conf$recordedDate_col
} else {
  recorded_date_custom <- "recordedDate"
}

# check for custom enddate
if (exists("enddate", where = conf) && nchar(conf$enddate) >= 1) {
  enddate_custom <- conf$enddate
} else {
  enddate_custom <- "2021-12-31"
}

search_date <- paste0("", strsplit(recorded_date_custom, "Date")[[1]][1],  "-date")
search_date_gt <- setNames("gt2014-12-31",search_date)
search_date_lt <- setNames(paste0("lt",enddate_custom),search_date)

# check for custom reference_prefix
if (exists("subject_reference_prefix", where = conf) && nchar(conf$subject_reference_prefix) >= 1) {
  subject_reference_prefix <- conf$subject_reference_prefix
} else {
  subject_reference_prefix <- "Patient/"
}
if (exists("encounter_reference_prefix", where = conf) && nchar(conf$encounter_reference_prefix) >= 1) {
  encounter_reference_prefix <- conf$encounter_reference_prefix
} else {
  encounter_reference_prefix <- "Encounter/"
}

# check for custom icd_code_system
if (exists("icd_code_system", where = conf) && nchar(conf$icd_code_system) >= 1) {
  icd_code_system_custom <- conf$icd_code_system
} else {
  icd_code_system_custom <- "http://fhir.de/CodeSystem/dimdi/icd-10-gm"
}

if (exists("ssl_verify_peer", where = conf) && (!conf$ssl_verify_peer) ) {
  httr::set_config(httr::config(ssl_verifypeer = 0L))
}

if (exists("max_bundles", where = conf) && nchar(conf$max_bundles) >= 1) {
  max_bundles_custom <- conf$max_bundles
} else {
  max_bundles_custom <- Inf
}

if (exists("count", where = conf) && nchar(conf$count) >= 1) {
  count_custom <- c("_count" = conf$count)
} else {
  count_custom <- c("_count" = 100)
}

if (exists("use_diag_sicherheit", where = conf) && (conf$use_diag_sicherheit) ) {
  use_diag_sicherheit <- TRUE
} else {
  use_diag_sicherheit <- FALSE
}

rare_icd10codes <- "A48.3,D76.1,D76.2,D76.3,D76.4,D89.8,D89.9,M30.3,R57.8,R65.0,R65.1,R65.2,R65.3,R65.9,R65.0%21,R65.1%21,R65.2%21,R65.3%21,R65.9%21,U10.9"
rare_icd10_combinations_a48 <- ",A48.3%20R65.0%21,A48.3%20R65.1%21,A48.3%20R65.2%21,A48.3%20R65.3%21,A48.3%20R65.4%21,A48.3%20R65.5%21,A48.3%20R65.6%21,A48.3%20R65.7%21,A48.3%20R65.8%21,A48.3%20R65.9%21,A48.3%20R65.0,A48.3%20R65.1,A48.3%20R65.2,A48.3%20R65.3,A48.3%20R65.4,A48.3%20R65.5,A48.3%20R65.6,A48.3%20R65.7,A48.3%20R65.8,A48.3%20R65.9"
rare_icd10_combinations_d76_1 <- ",D76.1%20R65.0%21,D76.1%20R65.1%21,D76.1%20R65.2%21,D76.1%20R65.3%21,D76.1%20R65.4%21,D76.1%20R65.5%21,D76.1%20R65.6%21,D76.1%20R65.7%21,D76.1%20R65.8%21,D76.1%20R65.9%21,D76.1%20R65.0,D76.1%20R65.1,D76.1%20R65.2,D76.1%20R65.3,D76.1%20R65.4,D76.1%20R65.5,D76.1%20R65.6,D76.1%20R65.7,D76.1%20R65.8,D76.1%20R65.9"
rare_icd10_combinations_d76_2 <- ",D76.2%20R65.0%21,D76.2%20R65.1%21,D76.2%20R65.2%21,D76.2%20R65.3%21,D76.2%20R65.4%21,D76.2%20R65.5%21,D76.2%20R65.6%21,D76.2%20R65.7%21,D76.2%20R65.8%21,D76.2%20R65.9%21,D76.2%20R65.0,D76.2%20R65.1,D76.2%20R65.2,D76.2%20R65.3,D76.2%20R65.4,D76.2%20R65.5,D76.2%20R65.6,D76.2%20R65.7,D76.2%20R65.8,D76.2%20R65.9"
rare_icd10_combinations_d76_3 <- ",D76.3%20R65.0%21,D76.3%20R65.1%21,D76.3%20R65.2%21,D76.3%20R65.3%21,D76.3%20R65.4%21,D76.3%20R65.5%21,D76.3%20R65.6%21,D76.3%20R65.7%21,D76.3%20R65.8%21,D76.3%20R65.9%21,D76.3%20R65.0,D76.3%20R65.1,D76.3%20R65.2,D76.3%20R65.3,D76.3%20R65.4,D76.3%20R65.5,D76.3%20R65.6,D76.3%20R65.7,D76.3%20R65.8,D76.3%20R65.9"
rare_icd10_combinations_d76_4 <- ",D76.4%20R65.0%21,D76.4%20R65.1%21,D76.4%20R65.2%21,D76.4%20R65.3%21,D76.4%20R65.4%21,D76.4%20R65.5%21,D76.4%20R65.6%21,D76.4%20R65.7%21,D76.4%20R65.8%21,D76.4%20R65.9%21,D76.4%20R65.0,D76.4%20R65.1,D76.4%20R65.2,D76.4%20R65.3,D76.4%20R65.4,D76.4%20R65.5,D76.4%20R65.6,D76.4%20R65.7,D76.4%20R65.8,D76.4%20R65.9"
rare_icd10_combinations_m30_3 <- ",M30.3%20R65.0%21,M30.3%20R65.1%21,M30.3%20R65.2%21,M30.3%20R65.3%21,M30.3%20R65.4%21,M30.3%20R65.5%21,M30.3%20R65.6%21,M30.3%20R65.7%21,M30.3%20R65.8%21,M30.3%20R65.9%21,M30.3%20R65.0,M30.3%20R65.1,M30.3%20R65.2,M30.3%20R65.3,M30.3%20R65.4,M30.3%20R65.5,M30.3%20R65.6,M30.3%20R65.7,M30.3%20R65.8,M30.3%20R65.9,M30.3%20B95.0%21,M30.3%20B95.1%21,M30.3%20B95.2%21,M30.3%20B95.3%21,M30.3%20B95.4%21,M30.3%20B95.5%21,M30.3%20B95.6%21,M30.3%20B95.7%21,M30.3%20B95.8%21,M30.3%20B95.9%21,M30.3%20B95.0,M30.3%20B95.1,M30.3%20B95.2,M30.3%20B95.3,M30.3%20B95.4,M30.3%20B95.5,M30.3%20B95.6,M30.3%20B95.7,M30.3%20B95.8,M30.3%20B95.9"
rare_icd10_combinations_r57 <- ",R57.8%20R65.0%21,R57.8%20R65.1%21,R57.8%20R65.2%21,R57.8%20R65.3%21,R57.8%20R65.4%21,R57.8%20R65.5%21,R57.8%20R65.6%21,R57.8%20R65.7%21,R57.8%20R65.8%21,R57.8%20R65.9%21,R57.8%20R65.0,R57.8%20R65.1,R57.8%20R65.2,R57.8%20R65.3,R57.8%20R65.4,R57.8%20R65.5,R57.8%20R65.6,R57.8%20R65.7,R57.8%20R65.8,R57.8%20R65.9"
rare_icd10_combinations_u10_9 <- ",U10.9%20B95.0%21,U10.9%20B95.1%21,U10.9%20B95.2%21,U10.9%20B95.3%21,U10.9%20B95.4%21,U10.9%20B95.5%21,U10.9%20B95.6%21,U10.9%20B95.7%21,U10.9%20B95.8%21,U10.9%20B95.9%21,U10.9%20B95.0,U10.9%20B95.1,U10.9%20B95.2,U10.9%20B95.3,U10.9%20B95.4,U10.9%20B95.5,U10.9%20B95.6,U10.9%20B95.7,U10.9%20B95.8,U10.9%20B95.9,U10.9%20B96.0%21,U10.9%20B96.1%21,U10.9%20B96.2%21,U10.9%20B96.3%21,U10.9%20B96.4%21,U10.9%20B96.5%21,U10.9%20B96.6%21,U10.9%20B96.7%21,U10.9%20B96.8%21,U10.9%20B96.9%21,U10.9%20B96.0,U10.9%20B96.1,U10.9%20B96.2,U10.9%20B96.3,U10.9%20B96.4,U10.9%20B96.5,U10.9%20B96.6,U10.9%20B96.7,U10.9%20B96.8,U10.9%20B96.9,U10.9%20U07.1%21,U10.9%20U07.1,U10.9%20U09.9%21,U10.9%20U09.9,U10.9%20U99.0%21,U10.9%20U99.0"

rare_icd10codes <- paste0(rare_icd10codes,rare_icd10_combinations_a48,rare_icd10_combinations_d76_1,rare_icd10_combinations_d76_2,rare_icd10_combinations_d76_3,rare_icd10_combinations_d76_4,rare_icd10_combinations_m30_3,rare_icd10_combinations_r57,rare_icd10_combinations_u10_9)

search_request_pat <- fhir_url(url = conf$serverbase,
                               resource = "Patient",
                               parameters = c(
                                 "_has:Condition:patient:code" = rare_icd10codes,
                                 "_has:Encounter:patient:date" = "ge2015",
                                 # blaze server takes 10x more time for the query with last _has
                                 #"_has:Encounter:patient:date" = "le2022",
                                 count_custom
                                 #,"_include" = "Patient:link"
                               )
)

patient_bundle <- fhir_search(request = search_request_pat,
                              username = conf$username,
                              password = conf$password,
                              token = conf$token,
                              verbose = 2,
                              max_bundles = max_bundles_custom)

ftd_conditions <- fhir_table_description(resource = "Condition"
                                         ,cols = c(diagnosis = "code/coding/code",
                                                   display = "code/coding/display",
                                                   system = "code/coding/system",
                                                   extension_url = "code/coding/extension",
                                                   extension_system = "code/coding/extension/valueCoding/system",
                                                   extension_code = "code/coding/extension/valueCoding/code",
                                                   recorded_date = recorded_date_custom,
                                                   patient_id = "subject/reference",
                                                   encounter_id = "encounter/reference"
                                         )
)

ftd_patients <- fhir_table_description(resource = "Patient"
                                       ,cols = c(patient_id = "id",
                                                 #hospital_id = "meta/source",
                                                 hospital_id = "identifier/assigner/identifier/value",
                                                 gender = "gender",
                                                 birthdate = "birthDate",
                                                 patient_zip = "address/postalCode",
                                                 countrycode = "address/country",
                                                 link = "link/other/reference"
                                       )
)

df_patients_raw <- fhir_crack(patient_bundle, ftd_patients, sep = "|", brackets = c("[", "]"), verbose = 2)

if (nrow(df_patients_raw) == 0) {
  stop('No patients found...exiting')
}

df_patients_tmp <- fhir_melt(df_patients_raw,
                             columns = c("patient_zip", "countrycode"),
                             brackets = c("[", "]"), sep = "|", all_columns = TRUE)

df_patients_tmp <- fhir_rm_indices(df_patients_tmp, brackets = c("[", "]"))

# remove duplicate entries
df_patients_tmp <- df_patients_tmp[!duplicated(df_patients_tmp$patient_id), ]

patient_ids <- paste0(subject_reference_prefix,unique(df_patients_tmp$patient_id))
nchar_for_ids <- 500 #- nchar(search_request_con)
n <- length(patient_ids)
list <- split(patient_ids, ceiling(seq_along(patient_ids)/n)) 
nchar <- sapply(list, function(x){sum(nchar(x))+(length(x)-1)}) 

#reduce the chunk size until number of characters is small enough
while(any(nchar > nchar_for_ids)){
  n <- n/2
  list <- split(patient_ids, ceiling(seq_along(patient_ids)/n))
  nchar <- sapply(list, function(x){sum(nchar(x))+(length(x)-1)})
}

komorb_icd10codes <- paste0(
  "U07.1,U07.2,U07.3,U07.4,U07.5",
  ",U07.1%21,U07.2%21,U07.3%21,U07.4%21,U07.5%21",
  ",U08.9,U08.9%21",
  ",U09.9,U09.9%21"
)

con_icd10codes <- paste0(
  rare_icd10codes,",",
  komorb_icd10codes
)

condition_bundle <- list()
message("Downloading Conditions.\n")
invisible({
  lapply(list, function(x){
    
    ids <- paste(x, collapse = ",")
    
    search_request_con <- fhir_url(url = conf$serverbase,
                                   resource = "Condition",
                                   parameters = c(
                                     "subject" = ids,
                                     "code" = con_icd10codes,
                                     search_date_gt,
                                     search_date_lt,
                                     count_custom
                                   )
    )

    condition_bundle <<- append(condition_bundle,fhir_search(request = search_request_con, username = conf$username, password = conf$password, token = conf$token, verbose = 2, max_bundles = max_bundles_custom))

  })
})
#bring condition results together and flatten
condition_bundle <- fhircrackr:::fhir_bundle_list(condition_bundle)

df_conditions_raw <- fhir_crack(condition_bundle, ftd_conditions, sep = "|", brackets = c("[", "]"), verbose = 2)

if (nrow(df_conditions_raw) == 0) {
  message('No conditions found. Retry with lowercase icd10codes.')
  condition_bundle <- list()
  invisible({
    lapply(list, function(x){
      
      ids <- paste(x, collapse = ",")
      
      search_request_con <- fhir_url(url = conf$serverbase,
                                     resource = "Condition",
                                     parameters = c(
                                       "subject" = ids,
                                       "code" = tolower(con_icd10codes),
                                       search_date_gt,
                                       search_date_lt,
                                       count_custom
                                     )
      )
      
      condition_bundle <<- append(condition_bundle,fhir_search(request = search_request_con, username = conf$username, password = conf$password, token = conf$token, verbose = 2, max_bundles = max_bundles_custom))
      
    })
  })
  #bring condition results together and flatten
  condition_bundle <- fhircrackr:::fhir_bundle_list(condition_bundle)
  
  df_conditions_raw <- fhir_crack(condition_bundle, ftd_conditions, sep = "|", brackets = c("[", "]"), verbose = 2)
}

if (nrow(df_conditions_raw) == 0) {
  stop('No conditions found...exiting')
}

df_conditions_tmp <- df_conditions_raw

# unnest raw conditions dataframe columns
melt <- TRUE
while (melt == TRUE) {
  columns <- data_frame()
  for ( column in colnames(df_conditions_tmp) ) {
    row <- c(column,str_locate(pattern = "]",na.omit(df_conditions_tmp[column]))[1])
    columns <- rbind(columns,row)
  }
  columns <- na.omit(columns)
  colnames(columns) <- c("name","position")
  columns$position <- as.integer(columns$position)
  i <- max(unlist(na.omit(columns$position)))
  melt_columns <- columns[which(columns$position == i), ][1]
  melt_columns <- melt_columns$name
  df_conditions_tmp <- fhir_melt(df_conditions_tmp,
                                 columns = melt_columns,
                                 brackets = c("[", "]"), sep = "|", all_columns = TRUE)
  if (i == 8) {
    
    df_conditions_tmp <- fhir_rm_indices(df_conditions_tmp, brackets = c("[", "]"))
    df_conditions_tmp <- df_conditions_tmp[!is.na(df_conditions_tmp$diagnosis),]
    melt = FALSE
  }
}

# unnest raw conditions dataframe columns
#melt_columns <- c("diagnosis", "system","extension_url","extension_system","extension_code")
#df_conditions_tmp <- fhir_melt(df_conditions_tmp,
#                               columns = melt_columns,
#                               brackets = c("[", "]"), sep = "|", all_columns = TRUE)

# unnest raw conditions dataframe columns
#df_conditions_tmp <- fhir_melt(df_conditions_tmp,
#                               columns = melt_columns,
#                               brackets = c("[", "]"), sep = "|", all_columns = TRUE)

#df_conditions_tmp <- fhir_rm_indices(df_conditions_tmp, brackets = c("[", "]"))

# remove the reference_prefix from column patient_id & encounter_id in condition resource
df_conditions_tmp$patient_id <- sub(subject_reference_prefix, "", df_conditions_tmp[, "patient_id"])
df_conditions_tmp$encounter_id <- sub(encounter_reference_prefix, "", df_conditions_tmp[, "encounter_id"])

# filter conditions by system to obtain only icd-10-gm system
df_conditions_tmp <- df_conditions_tmp[df_conditions_tmp$system == icd_code_system_custom, ]

# merge conditions and patients dataframe
df_conditions_patients <- base::merge(df_conditions_tmp, df_patients_tmp, by = "patient_id")

df_conditions_patients$recorded_date <- as.Date(df_conditions_patients$recorded_date, format = "%Y-%m-%d")
df_conditions_patients <- df_conditions_patients[df_conditions_patients$recorded_date > "2014-12-31", ]
df_conditions_patients <- df_conditions_patients[df_conditions_patients$recorded_date < enddate_custom, ]

# check for custom hospital_id
if (exists("hospital_name", where = conf) && nchar(conf$hospital_name) >= 1) {
  df_conditions_patients$hospital_id <- conf$hospital_name
} else if (unique(is.na(df_conditions_patients$hospital_id))) {
  message("Please provide hospital_id in conf.yml")
} 

# remove merge identifier column as its not needed and could cause problems
df_conditions_patients <- df_conditions_patients %>% select(-contains("resource_identifier"))

# check if birthdate is in format YYYY-MM-DD, if not append -01-01
df_conditions_patients <- mutate(df_conditions_patients, birthdate = ifelse(nchar(df_conditions_patients$birthdate) >= 10, df_conditions_patients$birthdate, paste0(df_conditions_patients$birthdate, "-01-01")))

# calculate age as of recorded_date - birthdate
df_conditions_patients$age <- floor(as.double(as.Date(df_conditions_patients$recorded_date) - as.Date(df_conditions_patients$birthdate)) / 365.25)
df_conditions_patients$age_dec <- as.numeric(as.double(as.Date(df_conditions_patients$recorded_date) - as.Date(df_conditions_patients$birthdate)) / 365.25)

if (!any(grepl('diagnosesicherheit', df_conditions_raw$extension_url, ignore.case = TRUE)) ) {
  #message("Diagnosesicherheit not found.")
  diag_sicherheit <- FALSE
} else {
  message("Diagnosesicherheit found. Please check conf.yml.sample for configuration.")
  diag_sicherheit <- TRUE
}

# set age groups
x_ag_0_19_99 <- c(1, 19, 199)
x_m <- c(1, 3, 12)
x <- c(1, 3, 5, 10, 15, 18, 20, 199)
df_conditions_patients$age_group_ag_0_19_99 <- cut(df_conditions_patients$age, x_ag_0_19_99, breaks = c(0, 19, 199), labels = c("[0,18]", "[19,99]"))
df_conditions_patients$age_group_m <- cut(df_conditions_patients$age_dec*12, x_m, breaks = c(0, 3, 12), labels = c("[0,3m]", "[3,12m]"))
df_conditions_patients$age_group <- cut(df_conditions_patients$age, x, breaks = c(1, 3, 5, 10, 15, 18, 20, 199), labels = c("[1,3]", "[4,5]", "[6,10]", "[11,15]", "[16,18]", "[19,20]", "[21,99]"))
df_conditions_patients$age_group_ag_0_5_15_18_99 <- cut(df_conditions_patients$age, x, breaks = c(0, 5, 15, 18, 199), labels = c("[0,5]", "[6,15]", "[16,18]", "[19,99]"))
df_conditions_patients <- df_conditions_patients %>% mutate(age_group = coalesce(age_group_m,age_group))

df_conditions_patients$recorded_year <- format(df_conditions_patients$recorded_date, format="%Y")

icd_code_display_occurence_list <- distinct(df_conditions_patients, diagnosis, display)
icd_code_display_occurence_list <- icd_code_display_occurence_list[order(icd_code_display_occurence_list$diagnosis), ]

df_conditions_patients$diagnosis_org <- df_conditions_patients$diagnosis
df_conditions_patients$diagnosis[grepl("A48",df_conditions_patients$diagnosis)] <- "A48.3, R57.8, R65.*"
df_conditions_patients$diagnosis[grepl("D76",df_conditions_patients$diagnosis)] <- "D76.1-4"
df_conditions_patients$diagnosis[grepl("D89",df_conditions_patients$diagnosis)] <- "D89.8/9"
df_conditions_patients$diagnosis[grepl("M30",df_conditions_patients$diagnosis)] <- "M30.3"
df_conditions_patients$diagnosis[grepl("R57",df_conditions_patients$diagnosis)] <- "A48.3, R57.8, R65.*"
df_conditions_patients$diagnosis[grepl("R65",df_conditions_patients$diagnosis)] <- "A48.3, R57.8, R65.*"
df_conditions_patients$diagnosis[grepl("U10",df_conditions_patients$diagnosis)] <- "U10.9"

zip_community_code_list <- read.csv(file = 'kreis_plz.csv', sep = ";", colClasses = c(zip_code="character", community_code="character"), stringsAsFactors = FALSE)

df_conditions_patients <- base::merge(df_conditions_patients, zip_community_code_list, by.x = "patient_zip", by.y = "zip_code", all.x = TRUE)

df_encounter_conditions <- data.frame(encounter_id = df_conditions_tmp$encounter_id, diagnosis = df_conditions_tmp$diagnosis)

#Wie häufig wird das Kawasaki-Syndrom bzw. PIMS im Zeitverlauf dokumentiert?
#Es sollen die jeweiligen Häufigkeiten Diagnosekodierung 
#M30.3 und D76.1-4, A48.3, R57.8, R65.0-9, D89.8/9 sowie U10.9 
#gemäß der Kataloge ICD-10-GM 2015 bis 2022 über einen Zeitraum von 2015 bis 2022 
#erfasst und Unterschiede zwischen dem Pandemiezeitraum/Pandemiezeiträumen 
#inklusive der Häufigkeit von COVID-19-Fällen (RKI-Meldedaten) und den übrigen Zeiträumen dargestellt werden.

# filter conditions for ICD-Code A48.3
df_conditions_a48_3 <- subset(df_conditions_patients, grepl("^A48.3", diagnosis))
# remove diag_sicherheit A
df_conditions_a48_3 <- subset(df_conditions_a48_3, !grepl("A$", extension_code))
# filter duplicated patient_ids
df_conditions_a48_3 <- df_conditions_a48_3[!duplicated(df_conditions_a48_3$patient_id), ]

df_conditions_d76 <- subset(df_conditions_patients, grepl("^D76", diagnosis))
df_conditions_d76 <- subset(df_conditions_d76, !grepl("A$", extension_code))
df_conditions_d76 <- df_conditions_d76[!duplicated(df_conditions_d76$patient_id), ]

df_conditions_d89_8 <- subset(df_conditions_patients, grepl("^D89.8", diagnosis))
df_conditions_d89_8 <- subset(df_conditions_d89_8, !grepl("A$", extension_code))
df_conditions_d89_8 <- df_conditions_d89_8[!duplicated(df_conditions_d89_8$patient_id), ]

df_conditions_d89_9 <- subset(df_conditions_patients, grepl("^D89.9", diagnosis))
df_conditions_d89_9 <- subset(df_conditions_d89_9, !grepl("A$", extension_code))
df_conditions_d89_9 <- df_conditions_d89_9[!duplicated(df_conditions_d89_9$patient_id), ]

df_conditions_i25_4 <- subset(df_conditions_patients, grepl("^I25.4_irrelevant", diagnosis))
df_conditions_i25_4 <- subset(df_conditions_i25_4, !grepl("A$", extension_code))
df_conditions_i25_4 <- df_conditions_i25_4[!duplicated(df_conditions_i25_4$patient_id), ]

df_conditions_m30_3 <- subset(df_conditions_patients, grepl("^M30.3", diagnosis))
df_conditions_m30_3 <- subset(df_conditions_m30_3, !grepl("A$", extension_code))
df_conditions_m30_3 <- df_conditions_m30_3[!duplicated(df_conditions_m30_3$patient_id), ]

df_conditions_r57_8 <- subset(df_conditions_patients, grepl("^R57.8", diagnosis))
df_conditions_r57_8 <- subset(df_conditions_r57_8, !grepl("A$", extension_code))
df_conditions_r57_8 <- df_conditions_r57_8[!duplicated(df_conditions_r57_8$patient_id), ]

df_conditions_r65 <- subset(df_conditions_patients, grepl("^R65", diagnosis))
df_conditions_r65 <- subset(df_conditions_r65, !grepl("A$", extension_code))
df_conditions_r65 <- df_conditions_r65[!duplicated(df_conditions_r65$patient_id), ]

df_conditions_u10_9 <- subset(df_conditions_patients, grepl("^U10.9", diagnosis))
df_conditions_u10_9 <- subset(df_conditions_u10_9, !grepl("A$", extension_code))
df_conditions_u10_9 <- df_conditions_u10_9[!duplicated(df_conditions_u10_9$patient_id), ]

df_conditions_a48_r57_8_r65 <- rbind(df_conditions_a48_3,df_conditions_r57_8,df_conditions_r65)

df_pims <- base::merge(df_conditions_patients, df_conditions_a48_3, by = "patient_id")
df_pims <- base::merge(df_pims, df_conditions_d76, by = "patient_id")
df_pims <- base::merge(df_pims, df_conditions_m30_3, by = "patient_id")
df_pims <- base::merge(df_pims, df_conditions_d89_8, by = "patient_id")
df_pims <- base::merge(df_pims, df_conditions_d89_9, by = "patient_id")
df_pims <- base::merge(df_pims, df_conditions_r57_8, by = "patient_id")
df_pims <- base::merge(df_pims, df_conditions_r65, by = "patient_id")

df_pims <- rbind(df_conditions_a48_3,df_conditions_d76,df_conditions_d89_8,df_conditions_d89_9,df_conditions_i25_4,df_conditions_m30_3,df_conditions_r57_8,df_conditions_r65,df_conditions_u10_9)

#----------------
#new
result_primaer_count <- ifelse(length(unique(df_pims$patient_id)) <= 5, "<5", length(unique(df_pims$patient_id)))

komorb_icd10codes_list <- as.list(strsplit(komorb_icd10codes, ",")[[1]])
komorb_icd10codes_list <- sub("%21", "!", komorb_icd10codes_list)

con_icd10codes_list <- c("A48.3, R57.8, R65.*", "D76.1-4", "D89.8/9", "M30.3", "U10.9")

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_2015_2021 <- data.frame()
for ( icdcode in sort(con_icd10codes_list)){
  for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_19_99)))){
    row <- c(conf$hospital_name,"2015-2021",icdcode,agegroup,as.integer(0))
    df_con_icd10codes_combined_2015_2021 <- rbind(df_con_icd10codes_combined_2015_2021, row)
  }
}
colnames(df_con_icd10codes_combined_2015_2021) <- c("Klinikum", "Jahr", "Diagn", "Alter", "Anzahl")
df_con_icd10codes_combined_2015_2021$Anzahl <- as.integer(df_con_icd10codes_combined_2015_2021$Anzahl)

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_2015_2021_gender <- data.frame()
for ( icdcode in sort(con_icd10codes_list)){
  for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_19_99)))){
    for ( gender in as.character(sort(unique(df_pims$gender)))){
      row <- c(conf$hospital_name,"2015-2021",gender,icdcode,agegroup,as.integer(0))
      df_con_icd10codes_combined_2015_2021_gender <- rbind(df_con_icd10codes_combined_2015_2021_gender, row)
    }
  }
}
colnames(df_con_icd10codes_combined_2015_2021_gender) <- c("Klinikum", "Jahr", "Geschlecht", "Diagn", "Alter", "Anzahl")
df_con_icd10codes_combined_2015_2021_gender$Anzahl <- as.integer(df_con_icd10codes_combined_2015_2021_gender$Anzahl)

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99 <- data.frame()
for ( icdcode in sort(con_icd10codes_list)){
  for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_5_15_18_99)))){
    row <- c(conf$hospital_name,"2015-2021",icdcode,agegroup,as.integer(0))
    df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99 <- rbind(df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99, row)
  }
}
colnames(df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99) <- c("Klinikum", "Jahr", "Diagn", "Alter", "Anzahl")
df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99$Anzahl <- as.integer(df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99$Anzahl)

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_ag_0_19_99 <- data.frame()
for ( year in sort(unique(df_pims$recorded_year))){
  for ( icdcode in sort(con_icd10codes_list)){
    for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_19_99)))){
      row <- c(conf$hospital_name,year,icdcode,agegroup,as.integer(0))
      df_con_icd10codes_combined_ag_0_19_99 <- rbind(df_con_icd10codes_combined_ag_0_19_99, row)
    }
  }
}
colnames(df_con_icd10codes_combined_ag_0_19_99) <- c("Klinikum", "Jahr", "Diagn", "Alter", "Anzahl")
df_con_icd10codes_combined_ag_0_19_99$Anzahl <- as.integer(df_con_icd10codes_combined_ag_0_19_99$Anzahl)

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_ag_0_19_99_gender <- data.frame()
for ( year in sort(unique(df_pims$recorded_year))){
  for ( icdcode in sort(con_icd10codes_list)){
    for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_19_99)))){
      for ( gender in as.character(sort(unique(df_pims$gender)))){
        row <- c(conf$hospital_name,year,gender,icdcode,agegroup,as.integer(0))
        df_con_icd10codes_combined_ag_0_19_99_gender <- rbind(df_con_icd10codes_combined_ag_0_19_99_gender, row)
      }
    }
  }
}
colnames(df_con_icd10codes_combined_ag_0_19_99_gender) <- c("Klinikum", "Jahr", "Geschlecht", "Diagn", "Alter", "Anzahl")
df_con_icd10codes_combined_ag_0_19_99_gender$Anzahl <- as.integer(df_con_icd10codes_combined_ag_0_19_99_gender$Anzahl)

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_ag_0_5_15_18_99 <- data.frame()
for ( year in sort(unique(df_pims$recorded_year))){
  for ( icdcode in sort(con_icd10codes_list)){
    for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_5_15_18_99)))){
      row <- c(conf$hospital_name,year,icdcode,agegroup,as.integer(0))
      df_con_icd10codes_combined_ag_0_5_15_18_99 <- rbind(df_con_icd10codes_combined_ag_0_5_15_18_99, row)
    }
  }
}
colnames(df_con_icd10codes_combined_ag_0_5_15_18_99) <- c("Klinikum", "Jahr", "Diagn", "Alter", "Anzahl")
df_con_icd10codes_combined_ag_0_5_15_18_99$Anzahl <- as.integer(df_con_icd10codes_combined_ag_0_5_15_18_99$Anzahl)

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2 <- data.frame()
for ( icdcode in sort(con_icd10codes_list)){
  for ( komorbcode in sort(c(komorb_icd10codes_list,"U10.9"))){
    for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_19_99)))){
      row <- c(conf$hospital_name,"2015-2021",icdcode,komorbcode,agegroup,as.integer(0))
      df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2 <- rbind(df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2, row)
    }
  }
}
colnames(df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2) <- c("Klinikum", "Jahr", "Diagn1", "Diagn2", "Alter", "Anzahl")
df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2$Anzahl <- as.integer(df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2$Anzahl)

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2_gender <- data.frame()
for ( icdcode in sort(con_icd10codes_list)){
  for ( komorbcode in sort(c(komorb_icd10codes_list,"U10.9"))){
    for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_19_99)))){
      for ( gender in as.character(sort(unique(df_pims$gender)))){
        row <- c(conf$hospital_name,"2015-2021",gender,icdcode,komorbcode,agegroup,as.integer(0))
        df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2_gender <- rbind(df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2_gender, row)
      }
    }
  }
}
colnames(df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2_gender) <- c("Klinikum", "Jahr", "Geschlecht", "Diagn1", "Diagn2", "Alter", "Anzahl")
df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2_gender$Anzahl <- as.integer(df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2_gender$Anzahl)

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99_diagn2 <- data.frame()
for ( icdcode in sort(con_icd10codes_list)){
  for ( komorbcode in sort(c(komorb_icd10codes_list,"U10.9"))){
    for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_5_15_18_99)))){
      row <- c(conf$hospital_name,"2015-2021",icdcode,komorbcode,agegroup,as.integer(0))
      df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99_diagn2 <- rbind(df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99_diagn2, row)
    }
  }
}
colnames(df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99_diagn2) <- c("Klinikum", "Jahr", "Diagn1", "Diagn2", "Alter", "Anzahl")
df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99_diagn2$Anzahl <- as.integer(df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99_diagn2$Anzahl)

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_ag_0_19_99_diagn2 <- data.frame()
for ( year in c("2020", "2021")){
  for ( icdcode in sort(con_icd10codes_list)){
    for ( komorbcode in sort(c(komorb_icd10codes_list,"U10.9"))){
      for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_19_99)))){
        row <- c(conf$hospital_name,year,icdcode,komorbcode,agegroup,as.integer(0))
        df_con_icd10codes_combined_ag_0_19_99_diagn2 <- rbind(df_con_icd10codes_combined_ag_0_19_99_diagn2, row)
      }
    }
  }
}
colnames(df_con_icd10codes_combined_ag_0_19_99_diagn2) <- c("Klinikum", "Jahr", "Diagn1", "Diagn2", "Alter", "Anzahl")
df_con_icd10codes_combined_ag_0_19_99_diagn2$Anzahl <- as.integer(df_con_icd10codes_combined_ag_0_19_99_diagn2$Anzahl)

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_ag_0_19_99_diagn2_gender <- data.frame()
for ( year in c("2020", "2021")){
  for ( icdcode in sort(con_icd10codes_list)){
    for ( komorbcode in sort(c(komorb_icd10codes_list,"U10.9"))){
      for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_19_99)))){
        for ( gender in as.character(sort(unique(df_pims$gender)))){
          row <- c(conf$hospital_name,year,gender,icdcode,komorbcode,agegroup,as.integer(0))
          df_con_icd10codes_combined_ag_0_19_99_diagn2_gender <- rbind(df_con_icd10codes_combined_ag_0_19_99_diagn2_gender, row)
        }
      }
    }
  }
}
colnames(df_con_icd10codes_combined_ag_0_19_99_diagn2_gender) <- c("Klinikum", "Jahr", "Geschlecht", "Diagn1", "Diagn2", "Alter", "Anzahl")
df_con_icd10codes_combined_ag_0_19_99_diagn2_gender$Anzahl <- as.integer(df_con_icd10codes_combined_ag_0_19_99_diagn2_gender$Anzahl)

# create table with all possible komorbidities for 0-count in result df
df_con_icd10codes_combined_ag_0_5_15_18_99_diagn2 <- data.frame()
for ( year in c("2020", "2021")){
  for ( icdcode in sort(con_icd10codes_list)){
    for ( komorbcode in sort(c(komorb_icd10codes_list,"U10.9"))){
      for ( agegroup in as.character(sort(unique(df_pims$age_group_ag_0_5_15_18_99)))){
        row <- c(conf$hospital_name,year,icdcode,komorbcode,agegroup,as.integer(0))
        df_con_icd10codes_combined_ag_0_5_15_18_99_diagn2 <- rbind(df_con_icd10codes_combined_ag_0_5_15_18_99_diagn2, row)
      }
    }
  }
}
colnames(df_con_icd10codes_combined_ag_0_5_15_18_99_diagn2) <- c("Klinikum", "Jahr", "Diagn1", "Diagn2", "Alter", "Anzahl")
df_con_icd10codes_combined_ag_0_5_15_18_99_diagn2$Anzahl <- as.integer(df_con_icd10codes_combined_ag_0_5_15_18_99_diagn2$Anzahl)


df_result_primaer_2015_2021 <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = "2015-2021", Diagn = df_pims$diagnosis, Alter = as.character(df_pims$age_group_ag_0_19_99)) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_primaer_2015_2021 <- rbind(df_result_primaer_2015_2021,df_con_icd10codes_combined_2015_2021)
df_result_primaer_2015_2021 <- distinct(df_result_primaer_2015_2021, Klinikum, Diagn, Alter, .keep_all= TRUE)
df_result_primaer_2015_2021 <- df_result_primaer_2015_2021[order(df_result_primaer_2015_2021$Alter), ]
df_result_primaer_2015_2021 <- df_result_primaer_2015_2021[order(df_result_primaer_2015_2021$Diagn), ]

df_result_primaer_2015_2021 <- mutate(df_result_primaer_2015_2021, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_primaer_2015_2021_lt20 <- df_result_primaer_2015_2021[df_result_primaer_2015_2021$Alter == "[0,18]", ]
#df_result_primaer_2015_2021_gt20 <- df_result_primaer_2015_2021[df_result_primaer_2015_2021$Alter != "[0,18]", ]

df_result_primaer_2015_2021_gender <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = "2015-2021", Diagn = df_pims$diagnosis, Alter = as.character(df_pims$age_group_ag_0_19_99), Geschlecht = df_pims$gender) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_primaer_2015_2021_gender <- rbind(df_result_primaer_2015_2021_gender,df_con_icd10codes_combined_2015_2021_gender)
df_result_primaer_2015_2021_gender <- distinct(df_result_primaer_2015_2021_gender, Klinikum, Geschlecht, Diagn, Alter, .keep_all= TRUE)
df_result_primaer_2015_2021_gender <- df_result_primaer_2015_2021_gender[order(df_result_primaer_2015_2021_gender$Geschlecht), ]
df_result_primaer_2015_2021_gender <- df_result_primaer_2015_2021_gender[order(df_result_primaer_2015_2021_gender$Alter), ]
df_result_primaer_2015_2021_gender <- df_result_primaer_2015_2021_gender[order(df_result_primaer_2015_2021_gender$Diagn), ]

df_result_primaer_2015_2021_gender <- mutate(df_result_primaer_2015_2021_gender, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_primaer_2015_2021_gender_lt20 <- df_result_primaer_2015_2021_gender[df_result_primaer_2015_2021_gender$Alter == "[0,18]", ]
#df_result_primaer_2015_2021_gender_gt20 <- df_result_primaer_2015_2021_gender[df_result_primaer_2015_2021_gender$Alter != "[0,18]", ]

df_result_primaer_2015_2021_ag_0_5_15_18_99 <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = "2015-2021", Diagn = df_pims$diagnosis, Alter = as.character(df_pims$age_group_ag_0_5_15_18_99)) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_primaer_2015_2021_ag_0_5_15_18_99 <- rbind(df_result_primaer_2015_2021_ag_0_5_15_18_99,df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99)
df_result_primaer_2015_2021_ag_0_5_15_18_99 <- distinct(df_result_primaer_2015_2021_ag_0_5_15_18_99, Klinikum, Diagn, Alter, .keep_all= TRUE)
df_result_primaer_2015_2021_ag_0_5_15_18_99 <- df_result_primaer_2015_2021_ag_0_5_15_18_99 %>% arrange(factor(Alter, levels = c("[0,5]", "[6,15]", "[16,18]", "[19,99]")))
df_result_primaer_2015_2021_ag_0_5_15_18_99 <- df_result_primaer_2015_2021_ag_0_5_15_18_99[order(df_result_primaer_2015_2021_ag_0_5_15_18_99$Diagn), ]

df_result_primaer_2015_2021_ag_0_5_15_18_99 <- mutate(df_result_primaer_2015_2021_ag_0_5_15_18_99, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_primaer_2015_2021_ag_0_5_15_18_99_lt20 <- df_result_primaer_2015_2021_ag_0_5_15_18_99[df_result_primaer_2015_2021_ag_0_5_15_18_99$Alter != "[19,99]", ]
#df_result_primaer_2015_2021_ag_0_5_15_18_99_gt20 <- df_result_primaer_2015_2021_ag_0_5_15_18_99[df_result_primaer_2015_2021_ag_0_5_15_18_99$Alter == "[19,99]", ]

df_m30_3_u10_9 <- rbind(df_conditions_m30_3,df_conditions_u10_9)

#df_result_primaer_m30_3_u10_9 <- as.data.frame(df_m30_3_u10_9 %>% group_by(Klinikum = df_m30_3_u10_9$hospital_id, Jahr = df_m30_3_u10_9$recorded_year, Diagn = df_m30_3_u10_9$diagnosis, Alter = as.character(df_m30_3_u10_9$age_group_ag_0_19_99)) %>% summarise(Anzahl = n()) )
df_result_primaer <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = df_pims$recorded_year, Diagn = df_pims$diagnosis, Alter = as.character(df_pims$age_group_ag_0_19_99)) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_primaer <- rbind(df_result_primaer,df_con_icd10codes_combined_ag_0_19_99)
df_result_primaer <- distinct(df_result_primaer, Klinikum, Jahr, Diagn, Alter, .keep_all= TRUE)
df_result_primaer <- df_result_primaer[order(df_result_primaer$Alter), ]
df_result_primaer <- df_result_primaer[order(df_result_primaer$Diagn), ]
df_result_primaer <- df_result_primaer[order(df_result_primaer$Jahr), ]

df_result_primaer <- mutate(df_result_primaer, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_primaer_lt20 <- df_result_primaer[df_result_primaer$Alter == "[0,18]", ]
#df_result_primaer_gt20 <- df_result_primaer[df_result_primaer$Alter != "[0,18]", ]

#df_result_primaer_m30_3_u10_9_gender <- as.data.frame(df_m30_3_u10_9 %>% group_by(Klinikum = df_m30_3_u10_9$hospital_id, Jahr = df_m30_3_u10_9$recorded_year, Geschlecht = df_m30_3_u10_9$gender, Diagn = df_m30_3_u10_9$diagnosis, Alter = as.character(df_m30_3_u10_9$age_group_ag_0_19_99)) %>% summarise(Anzahl = n()) )
df_result_primaer_gender <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = df_pims$recorded_year, Diagn = df_pims$diagnosis, Alter = as.character(df_pims$age_group_ag_0_19_99), Geschlecht = df_pims$gender) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_primaer_gender <- rbind(df_result_primaer_gender,df_con_icd10codes_combined_ag_0_19_99_gender)
df_result_primaer_gender <- distinct(df_result_primaer_gender, Klinikum, Jahr, Geschlecht, Diagn, Alter, .keep_all= TRUE)
df_result_primaer_gender <- df_result_primaer_gender[order(df_result_primaer_gender$Geschlecht), ]
df_result_primaer_gender <- df_result_primaer_gender[order(df_result_primaer_gender$Alter), ]
df_result_primaer_gender <- df_result_primaer_gender[order(df_result_primaer_gender$Diagn), ]
df_result_primaer_gender <- df_result_primaer_gender[order(df_result_primaer_gender$Jahr), ]

df_result_primaer_gender <- mutate(df_result_primaer_gender, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_primaer_gender_lt20 <- df_result_primaer_gender[df_result_primaer_gender$Alter == "[0,18]", ]
#df_result_primaer_gender_gt20 <- df_result_primaer_gender[df_result_primaer_gender$Alter != "[0,18]", ]

#df_result_primaer_m30_3_u10_9_ag_0_5_15_18_99 <- as.data.frame(df_m30_3_u10_9 %>% group_by(Klinikum = df_m30_3_u10_9$hospital_id, Jahr = df_m30_3_u10_9$recorded_year, Diagn = df_m30_3_u10_9$diagnosis, Alter = as.character(df_m30_3_u10_9$age_group_ag_0_5_15_18_99)) %>% summarise(Anzahl = n()) )
df_result_primaer_ag_0_5_15_18_99 <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = df_pims$recorded_year, Diagn = df_pims$diagnosis, Alter = as.character(df_pims$age_group_ag_0_5_15_18_99)) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_primaer_ag_0_5_15_18_99 <- rbind(df_result_primaer_ag_0_5_15_18_99,df_con_icd10codes_combined_ag_0_5_15_18_99)
df_result_primaer_ag_0_5_15_18_99 <- distinct(df_result_primaer_ag_0_5_15_18_99, Klinikum, Jahr, Diagn, Alter, .keep_all= TRUE)
df_result_primaer_ag_0_5_15_18_99 <- df_result_primaer_ag_0_5_15_18_99 %>% arrange(factor(Alter, levels = c("[0,5]", "[6,15]", "[16,18]", "[19,99]")))
df_result_primaer_ag_0_5_15_18_99 <- df_result_primaer_ag_0_5_15_18_99[order(df_result_primaer_ag_0_5_15_18_99$Diagn), ]
df_result_primaer_ag_0_5_15_18_99 <- df_result_primaer_ag_0_5_15_18_99[order(df_result_primaer_ag_0_5_15_18_99$Jahr), ]

df_result_primaer_ag_0_5_15_18_99 <- mutate(df_result_primaer_ag_0_5_15_18_99, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_primaer_ag_0_5_15_18_99_lt20 <- df_result_primaer_ag_0_5_15_18_99[df_result_primaer_ag_0_5_15_18_99$Alter != "[19,99]", ]
#df_result_primaer_ag_0_5_15_18_99_gt20 <- df_result_primaer_ag_0_5_15_18_99[df_result_primaer_ag_0_5_15_18_99$Alter == "[19,99]", ]


#Sekundäre Fragestellungen:
#[A] Wie häufig wird das Kawasaki-Syndrom bzw. PIMS in Kombination mit einem positiven COVID-19 Befund dokumentiert?
#Es sollen die jeweiligen Häufigkeiten der Diagnosekodierung 
#M30.3 und D76.1-4, A48.3, R57.8, R65.0-9, D89.8/9 und einer 
#Diagnosekodierung U07.1, U07.2, U10.9 oder Hinweis auf COVID-19 (Tabelle 6) erfasst werden.

# get komorbidities
df_conditions_u07_1 <- subset(df_conditions_patients, grepl("^U07.1", diagnosis))
df_a48_r57_8_r65_u07_1 <- base::merge(df_conditions_u07_1, df_conditions_a48_r57_8_r65, by = "patient_id")
df_a48_r57_8_r65_u07_1 <- df_a48_r57_8_r65_u07_1[!duplicated(df_a48_r57_8_r65_u07_1$patient_id), ]
df_a48_r57_8_r65_u07_1 <- df_a48_r57_8_r65_u07_1 %>% select(-contains("resource_identifier"))
df_d76_u07_1 <- base::merge(df_conditions_u07_1, df_conditions_d76, by = "patient_id")
df_d76_u07_1 <- df_d76_u07_1[!duplicated(df_d76_u07_1$patient_id), ]
df_d76_u07_1 <- df_d76_u07_1 %>% select(-contains("resource_identifier"))
df_m30_3_u07_1 <- base::merge(df_conditions_u07_1, df_conditions_m30_3, by = "patient_id")
df_m30_3_u07_1 <- df_m30_3_u07_1[!duplicated(df_m30_3_u07_1$patient_id), ]
df_m30_3_u07_1 <- df_m30_3_u07_1 %>% select(-contains("resource_identifier"))
df_u10_9_u07_1 <- base::merge(df_conditions_u07_1, df_conditions_u10_9, by = "patient_id")
df_u10_9_u07_1 <- df_u10_9_u07_1[!duplicated(df_u10_9_u07_1$patient_id), ]
df_u10_9_u07_1 <- df_u10_9_u07_1 %>% select(-contains("resource_identifier"))

df_conditions_u07_2 <- subset(df_conditions_patients, grepl("^U07.2", diagnosis))
df_a48_r57_8_r65_u07_2 <- base::merge(df_conditions_u07_2, df_conditions_a48_r57_8_r65, by = "patient_id")
df_a48_r57_8_r65_u07_2 <- df_a48_r57_8_r65_u07_2[!duplicated(df_a48_r57_8_r65_u07_2$patient_id), ]
df_a48_r57_8_r65_u07_2 <- df_a48_r57_8_r65_u07_2 %>% select(-contains("resource_identifier"))
df_d76_u07_2 <- base::merge(df_conditions_u07_2, df_conditions_d76, by = "patient_id")
df_d76_u07_2 <- df_d76_u07_2[!duplicated(df_d76_u07_2$patient_id), ]
df_d76_u07_2 <- df_d76_u07_2 %>% select(-contains("resource_identifier"))
df_m30_3_u07_2 <- base::merge(df_conditions_u07_2, df_conditions_m30_3, by = "patient_id")
df_m30_3_u07_2 <- df_m30_3_u07_2[!duplicated(df_m30_3_u07_2$patient_id), ]
df_m30_3_u07_2 <- df_m30_3_u07_2 %>% select(-contains("resource_identifier"))
df_u10_9_u07_2 <- base::merge(df_conditions_u07_2, df_conditions_u10_9, by = "patient_id")
df_u10_9_u07_2 <- df_u10_9_u07_2[!duplicated(df_u10_9_u07_2$patient_id), ]
df_u10_9_u07_2 <- df_u10_9_u07_2 %>% select(-contains("resource_identifier"))

df_conditions_u07_3 <- subset(df_conditions_patients, grepl("^U07.3", diagnosis))
df_a48_r57_8_r65_u07_3 <- base::merge(df_conditions_u07_3, df_conditions_a48_r57_8_r65, by = "patient_id")
df_a48_r57_8_r65_u07_3 <- df_a48_r57_8_r65_u07_3[!duplicated(df_a48_r57_8_r65_u07_3$patient_id), ]
df_a48_r57_8_r65_u07_3 <- df_a48_r57_8_r65_u07_3 %>% select(-contains("resource_identifier"))
df_d76_u07_3 <- base::merge(df_conditions_u07_3, df_conditions_d76, by = "patient_id")
df_d76_u07_3 <- df_d76_u07_3[!duplicated(df_d76_u07_3$patient_id), ]
df_d76_u07_3 <- df_d76_u07_3 %>% select(-contains("resource_identifier"))
df_m30_3_u07_3 <- base::merge(df_conditions_u07_3, df_conditions_m30_3, by = "patient_id")
df_m30_3_u07_3 <- df_m30_3_u07_3[!duplicated(df_m30_3_u07_3$patient_id), ]
df_m30_3_u07_3 <- df_m30_3_u07_3 %>% select(-contains("resource_identifier"))
df_u10_9_u07_3 <- base::merge(df_conditions_u07_3, df_conditions_u10_9, by = "patient_id")
df_u10_9_u07_3 <- df_u10_9_u07_3[!duplicated(df_u10_9_u07_3$patient_id), ]
df_u10_9_u07_3 <- df_u10_9_u07_3 %>% select(-contains("resource_identifier"))

df_conditions_u07_4 <- subset(df_conditions_patients, grepl("^U07.4", diagnosis))
df_a48_r57_8_r65_u07_4 <- base::merge(df_conditions_u07_4, df_conditions_a48_r57_8_r65, by = "patient_id")
df_a48_r57_8_r65_u07_4 <- df_a48_r57_8_r65_u07_4[!duplicated(df_a48_r57_8_r65_u07_4$patient_id), ]
df_a48_r57_8_r65_u07_4 <- df_a48_r57_8_r65_u07_4 %>% select(-contains("resource_identifier"))
df_d76_u07_4 <- base::merge(df_conditions_u07_4, df_conditions_d76, by = "patient_id")
df_d76_u07_4 <- df_d76_u07_4[!duplicated(df_d76_u07_4$patient_id), ]
df_d76_u07_4 <- df_d76_u07_4 %>% select(-contains("resource_identifier"))
df_m30_3_u07_4 <- base::merge(df_conditions_u07_4, df_conditions_m30_3, by = "patient_id")
df_m30_3_u07_4 <- df_m30_3_u07_4[!duplicated(df_m30_3_u07_4$patient_id), ]
df_m30_3_u07_4 <- df_m30_3_u07_4 %>% select(-contains("resource_identifier"))
df_u10_9_u07_4 <- base::merge(df_conditions_u07_4, df_conditions_u10_9, by = "patient_id")
df_u10_9_u07_4 <- df_u10_9_u07_4[!duplicated(df_u10_9_u07_4$patient_id), ]
df_u10_9_u07_4 <- df_u10_9_u07_4 %>% select(-contains("resource_identifier"))

df_conditions_u07_5 <- subset(df_conditions_patients, grepl("^U07.5", diagnosis))
df_a48_r57_8_r65_u07_5 <- base::merge(df_conditions_u07_5, df_conditions_a48_r57_8_r65, by = "patient_id")
df_a48_r57_8_r65_u07_5 <- df_a48_r57_8_r65_u07_5[!duplicated(df_a48_r57_8_r65_u07_5$patient_id), ]
df_a48_r57_8_r65_u07_5 <- df_a48_r57_8_r65_u07_5 %>% select(-contains("resource_identifier"))
df_d76_u07_5 <- base::merge(df_conditions_u07_5, df_conditions_d76, by = "patient_id")
df_d76_u07_5 <- df_d76_u07_5[!duplicated(df_d76_u07_5$patient_id), ]
df_d76_u07_5 <- df_d76_u07_5 %>% select(-contains("resource_identifier"))
df_m30_3_u07_5 <- base::merge(df_conditions_u07_5, df_conditions_m30_3, by = "patient_id")
df_m30_3_u07_5 <- df_m30_3_u07_5[!duplicated(df_m30_3_u07_5$patient_id), ]
df_m30_3_u07_5 <- df_m30_3_u07_5 %>% select(-contains("resource_identifier"))
df_u10_9_u07_5 <- base::merge(df_conditions_u07_5, df_conditions_u10_9, by = "patient_id")
df_u10_9_u07_5 <- df_u10_9_u07_5[!duplicated(df_u10_9_u07_5$patient_id), ]
df_u10_9_u07_5 <- df_u10_9_u07_5 %>% select(-contains("resource_identifier"))

df_conditions_u08 <- subset(df_conditions_patients, grepl("^U08", diagnosis))
df_a48_r57_8_r65_u08 <- base::merge(df_conditions_u08, df_conditions_a48_r57_8_r65, by = "patient_id")
df_a48_r57_8_r65_u08 <- df_a48_r57_8_r65_u08[!duplicated(df_a48_r57_8_r65_u08$patient_id), ]
df_a48_r57_8_r65_u08 <- df_a48_r57_8_r65_u08 %>% select(-contains("resource_identifier"))
df_d76_u08 <- base::merge(df_conditions_u08, df_conditions_d76, by = "patient_id")
df_d76_u08 <- df_d76_u08[!duplicated(df_d76_u08$patient_id), ]
df_d76_u08 <- df_d76_u08 %>% select(-contains("resource_identifier"))
df_m30_3_u08 <- base::merge(df_conditions_u08, df_conditions_m30_3, by = "patient_id")
df_m30_3_u08 <- df_m30_3_u08[!duplicated(df_m30_3_u08$patient_id), ]
df_m30_3_u08 <- df_m30_3_u08 %>% select(-contains("resource_identifier"))
df_u10_9_u08 <- base::merge(df_conditions_u08, df_conditions_u10_9, by = "patient_id")
df_u10_9_u08 <- df_u10_9_u08[!duplicated(df_u10_9_u08$patient_id), ]
df_u10_9_u08 <- df_u10_9_u08 %>% select(-contains("resource_identifier"))

df_conditions_u09 <- subset(df_conditions_patients, grepl("^U09", diagnosis))
df_a48_r57_8_r65_u09 <- base::merge(df_conditions_u09, df_conditions_a48_r57_8_r65, by = "patient_id")
df_a48_r57_8_r65_u09 <- df_a48_r57_8_r65_u09[!duplicated(df_a48_r57_8_r65_u09$patient_id), ]
df_a48_r57_8_r65_u09 <- df_a48_r57_8_r65_u09 %>% select(-contains("resource_identifier"))
df_d76_u09 <- base::merge(df_conditions_u09, df_conditions_d76, by = "patient_id")
df_d76_u09 <- df_d76_u09[!duplicated(df_d76_u09$patient_id), ]
df_d76_u09 <- df_d76_u09 %>% select(-contains("resource_identifier"))
df_m30_3_u09 <- base::merge(df_conditions_u09, df_conditions_m30_3, by = "patient_id")
df_m30_3_u09 <- df_m30_3_u09[!duplicated(df_m30_3_u09$patient_id), ]
df_m30_3_u09 <- df_m30_3_u09 %>% select(-contains("resource_identifier"))
df_u10_9_u09 <- base::merge(df_conditions_u09, df_conditions_u10_9, by = "patient_id")
df_u10_9_u09 <- df_u10_9_u09[!duplicated(df_u10_9_u09$patient_id), ]
df_u10_9_u09 <- df_u10_9_u09 %>% select(-contains("resource_identifier"))

df_a48_r57_8_r65_u10_9 <- base::merge(df_conditions_u10_9, df_conditions_a48_r57_8_r65, by = "patient_id")
df_a48_r57_8_r65_u10_9 <- df_a48_r57_8_r65_u10_9[!duplicated(df_a48_r57_8_r65_u10_9$patient_id), ]
df_a48_r57_8_r65_u10_9 <- df_a48_r57_8_r65_u10_9 %>% select(-contains("resource_identifier"))
df_d76_u10_9 <- base::merge(df_conditions_u10_9, df_conditions_d76, by = "patient_id")
df_d76_u10_9 <- df_d76_u10_9[!duplicated(df_d76_u10_9$patient_id), ]
df_d76_u10_9 <- df_d76_u10_9 %>% select(-contains("resource_identifier"))
df_m30_3_u10_9 <- base::merge(df_conditions_u10_9, df_conditions_m30_3, by = "patient_id")
df_m30_3_u10_9 <- df_m30_3_u10_9[!duplicated(df_m30_3_u10_9$patient_id), ]
df_m30_3_u10_9 <- df_m30_3_u10_9 %>% select(-contains("resource_identifier"))

df_u07_1_komorb <- rbind(df_a48_r57_8_r65_u07_1,df_d76_u07_1,df_m30_3_u07_1,df_u10_9_u07_1)
df_u07_2_komorb <- rbind(df_a48_r57_8_r65_u07_2,df_d76_u07_2,df_m30_3_u07_2,df_u10_9_u07_2)
df_u07_3_komorb <- rbind(df_a48_r57_8_r65_u07_3,df_d76_u07_3,df_m30_3_u07_3,df_u10_9_u07_3)
df_u07_4_komorb <- rbind(df_a48_r57_8_r65_u07_4,df_d76_u07_4,df_m30_3_u07_4,df_u10_9_u07_4)
df_u07_5_komorb <- rbind(df_a48_r57_8_r65_u07_5,df_d76_u07_5,df_m30_3_u07_5,df_u10_9_u07_5)
df_u08_komorb <- rbind(df_a48_r57_8_r65_u08,df_d76_u08,df_m30_3_u08,df_u10_9_u08)
df_u09_komorb <- rbind(df_a48_r57_8_r65_u09,df_d76_u09,df_m30_3_u09,df_u10_9_u09)
df_u10_9_komorb <- rbind(df_a48_r57_8_r65_u10_9,df_d76_u10_9,df_m30_3_u10_9)

df_covid_komorb <- rbind(df_a48_r57_8_r65_u07_1,
                         df_a48_r57_8_r65_u07_2,
                         df_a48_r57_8_r65_u07_3,
                         df_a48_r57_8_r65_u07_4,
                         df_a48_r57_8_r65_u07_5,
                         df_a48_r57_8_r65_u08,
                         df_a48_r57_8_r65_u09,
                         df_a48_r57_8_r65_u10_9,
                         df_d76_u07_1,
                         df_d76_u07_2,
                         df_d76_u07_3,
                         df_d76_u07_4,
                         df_d76_u07_5,
                         df_d76_u08,
                         df_d76_u09,
                         df_d76_u10_9,
                         df_m30_3_u07_1,
                         df_m30_3_u07_2,
                         df_m30_3_u07_3,
                         df_m30_3_u07_4,
                         df_m30_3_u07_5,
                         df_m30_3_u08,
                         df_m30_3_u09,
                         df_m30_3_u10_9,
                         df_u10_9_u07_1,
                         df_u10_9_u07_2,
                         df_u10_9_u07_3,
                         df_u10_9_u07_4,
                         df_u10_9_u07_5,
                         df_u10_9_u08,
                         df_u10_9_u09)

df_result_sekundaer_2015_2021 <- as.data.frame(df_covid_komorb %>% group_by(Klinikum = df_covid_komorb$hospital_id.x, Jahr = "2015-2021", Diagn1 = df_covid_komorb$diagnosis.y, Diagn2 = df_covid_komorb$diagnosis.x, Alter = as.character(df_covid_komorb$age_group_ag_0_19_99.x)) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_sekundaer_2015_2021 <- rbind(df_result_sekundaer_2015_2021,df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2)
df_result_sekundaer_2015_2021 <- distinct(df_result_sekundaer_2015_2021, Klinikum, Diagn1, Diagn2, Alter, .keep_all= TRUE)
df_result_sekundaer_2015_2021 <- df_result_sekundaer_2015_2021[order(df_result_sekundaer_2015_2021$Alter), ]
df_result_sekundaer_2015_2021 <- df_result_sekundaer_2015_2021[order(df_result_sekundaer_2015_2021$Diagn2), ]
df_result_sekundaer_2015_2021 <- df_result_sekundaer_2015_2021[order(df_result_sekundaer_2015_2021$Diagn1), ]

df_result_sekundaer_2015_2021 <- mutate(df_result_sekundaer_2015_2021, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_sekundaer_2015_2021_lt20 <- df_result_sekundaer_2015_2021[df_result_sekundaer_2015_2021$Alter == "[0,18]", ]
#df_result_sekundaer_2015_2021_gt20 <- df_result_sekundaer_2015_2021[df_result_sekundaer_2015_2021$Alter != "[0,18]", ]

df_result_sekundaer_2015_2021_gender <- as.data.frame(df_covid_komorb %>% group_by(Klinikum = df_covid_komorb$hospital_id.x, Jahr = "2015-2021", Diagn1 = df_covid_komorb$diagnosis.y, Diagn2 = df_covid_komorb$diagnosis.x, Alter = as.character(df_covid_komorb$age_group_ag_0_19_99.x), Geschlecht = df_covid_komorb$gender.x) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_sekundaer_2015_2021_gender <- rbind(df_result_sekundaer_2015_2021_gender,df_con_icd10codes_combined_2015_2021_ag_0_19_99_diagn2_gender)
df_result_sekundaer_2015_2021_gender <- distinct(df_result_sekundaer_2015_2021_gender, Klinikum, Diagn1, Diagn2, Geschlecht, Alter, .keep_all= TRUE)
df_result_sekundaer_2015_2021_gender <- df_result_sekundaer_2015_2021_gender[order(df_result_sekundaer_2015_2021_gender$Geschlecht), ]
df_result_sekundaer_2015_2021_gender <- df_result_sekundaer_2015_2021_gender[order(df_result_sekundaer_2015_2021_gender$Alter), ]
df_result_sekundaer_2015_2021_gender <- df_result_sekundaer_2015_2021_gender[order(df_result_sekundaer_2015_2021_gender$Diagn2), ]
df_result_sekundaer_2015_2021_gender <- df_result_sekundaer_2015_2021_gender[order(df_result_sekundaer_2015_2021_gender$Diagn1), ]

df_result_sekundaer_2015_2021_gender <- mutate(df_result_sekundaer_2015_2021_gender, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_sekundaer_2015_2021_gender_lt20 <- df_result_sekundaer_2015_2021_gender[df_result_sekundaer_2015_2021_gender$Alter == "[0,18]", ]
#df_result_sekundaer_2015_2021_gender_gt20 <- df_result_sekundaer_2015_2021_gender[df_result_sekundaer_2015_2021_gender$Alter != "[0,18]", ]

df_result_sekundaer_2015_2021_ag_0_5_15_18_99 <- as.data.frame(df_covid_komorb %>% group_by(Klinikum = df_covid_komorb$hospital_id.x, Jahr = "2015-2021", Diagn1 = df_covid_komorb$diagnosis.y, Diagn2 = df_covid_komorb$diagnosis.x, Alter = as.character(df_covid_komorb$age_group_ag_0_5_15_18_99.x)) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_sekundaer_2015_2021_ag_0_5_15_18_99 <- rbind(df_result_sekundaer_2015_2021_ag_0_5_15_18_99,df_con_icd10codes_combined_2015_2021_ag_0_5_15_18_99_diagn2)
df_result_sekundaer_2015_2021_ag_0_5_15_18_99 <- distinct(df_result_sekundaer_2015_2021_ag_0_5_15_18_99, Klinikum, Diagn1, Diagn2, Alter, .keep_all= TRUE)
df_result_sekundaer_2015_2021_ag_0_5_15_18_99 <- df_result_sekundaer_2015_2021_ag_0_5_15_18_99 %>% arrange(factor(Alter, levels = c("[0,5]", "[6,15]", "[16,18]", "[19,99]")))
df_result_sekundaer_2015_2021_ag_0_5_15_18_99 <- df_result_sekundaer_2015_2021_ag_0_5_15_18_99[order(df_result_sekundaer_2015_2021_ag_0_5_15_18_99$Diagn2), ]
df_result_sekundaer_2015_2021_ag_0_5_15_18_99 <- df_result_sekundaer_2015_2021_ag_0_5_15_18_99[order(df_result_sekundaer_2015_2021_ag_0_5_15_18_99$Diagn1), ]

df_result_sekundaer_2015_2021_ag_0_5_15_18_99 <- mutate(df_result_sekundaer_2015_2021_ag_0_5_15_18_99, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_sekundaer_2015_2021_ag_0_5_15_18_99_lt20 <- df_result_sekundaer_2015_2021_ag_0_5_15_18_99[df_result_sekundaer_2015_2021_ag_0_5_15_18_99$Alter != "[19,99]", ]
#df_result_sekundaer_2015_2021_ag_0_5_15_18_99_gt20 <- df_result_sekundaer_2015_2021_ag_0_5_15_18_99[df_result_sekundaer_2015_2021_ag_0_5_15_18_99$Alter == "[19,99]", ]

df_result_sekundaer_2020_2021 <- as.data.frame(df_covid_komorb %>% group_by(Klinikum = df_covid_komorb$hospital_id.x, Jahr = df_covid_komorb$recorded_year.x, Diagn1 = df_covid_komorb$diagnosis.y, Diagn2 = df_covid_komorb$diagnosis.x, Alter = as.character(df_covid_komorb$age_group_ag_0_19_99.x)) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_sekundaer_2020_2021 <- rbind(df_result_sekundaer_2020_2021,df_con_icd10codes_combined_ag_0_19_99_diagn2)
df_result_sekundaer_2020_2021 <- distinct(df_result_sekundaer_2020_2021, Klinikum, Jahr, Diagn1, Diagn2, Alter, .keep_all= TRUE)
df_result_sekundaer_2020_2021 <- df_result_sekundaer_2020_2021[order(df_result_sekundaer_2020_2021$Alter), ]
df_result_sekundaer_2020_2021 <- df_result_sekundaer_2020_2021[order(df_result_sekundaer_2020_2021$Diagn2), ]
df_result_sekundaer_2020_2021 <- df_result_sekundaer_2020_2021[order(df_result_sekundaer_2020_2021$Diagn1), ]
df_result_sekundaer_2020_2021 <- df_result_sekundaer_2020_2021[order(df_result_sekundaer_2020_2021$Jahr), ]

df_result_sekundaer_2020_2021 <- mutate(df_result_sekundaer_2020_2021, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_sekundaer_2020_2021_lt20 <- df_result_sekundaer_2020_2021[df_result_sekundaer_2020_2021$Alter == "[0,18]", ]
#df_result_sekundaer_2020_2021_gt20 <- df_result_sekundaer_2020_2021[df_result_sekundaer_2020_2021$Alter != "[0,18]", ]

df_result_sekundaer_2020_2021_gender <- as.data.frame(df_covid_komorb %>% group_by(Klinikum = df_covid_komorb$hospital_id.x, Jahr = df_covid_komorb$recorded_year.x, Diagn1 = df_covid_komorb$diagnosis.y, Diagn2 = df_covid_komorb$diagnosis.x, Alter = as.character(df_covid_komorb$age_group_ag_0_19_99.x), Geschlecht = df_covid_komorb$gender.x) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_sekundaer_2020_2021_gender <- rbind(df_result_sekundaer_2020_2021_gender,df_con_icd10codes_combined_ag_0_19_99_diagn2_gender)
df_result_sekundaer_2020_2021_gender <- distinct(df_result_sekundaer_2020_2021_gender, Klinikum, Jahr, Geschlecht, Diagn1, Diagn2, Alter, .keep_all= TRUE)
df_result_sekundaer_2020_2021_gender <- df_result_sekundaer_2020_2021_gender[order(df_result_sekundaer_2020_2021_gender$Geschlecht), ]
df_result_sekundaer_2020_2021_gender <- df_result_sekundaer_2020_2021_gender[order(df_result_sekundaer_2020_2021_gender$Alter), ]
df_result_sekundaer_2020_2021_gender <- df_result_sekundaer_2020_2021_gender[order(df_result_sekundaer_2020_2021_gender$Diagn2), ]
df_result_sekundaer_2020_2021_gender <- df_result_sekundaer_2020_2021_gender[order(df_result_sekundaer_2020_2021_gender$Diagn1), ]
df_result_sekundaer_2020_2021_gender <- df_result_sekundaer_2020_2021_gender[order(df_result_sekundaer_2020_2021_gender$Jahr), ]

df_result_sekundaer_2020_2021_gender <- mutate(df_result_sekundaer_2020_2021_gender, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_sekundaer_2020_2021_gender_lt20 <- df_result_sekundaer_2020_2021_gender[df_result_sekundaer_2020_2021_gender$Alter == "[0,18]", ]
#df_result_sekundaer_2020_2021_gender_gt20 <- df_result_sekundaer_2020_2021_gender[df_result_sekundaer_2020_2021_gender$Alter != "[0,18]", ]

df_result_sekundaer_2020_2021_ag_0_5_15_18_99 <- as.data.frame(df_covid_komorb %>% group_by(Klinikum = df_covid_komorb$hospital_id.x, Jahr = df_covid_komorb$recorded_year.x, Diagn1 = df_covid_komorb$diagnosis.y, Diagn2 = df_covid_komorb$diagnosis.x, Alter = as.character(df_covid_komorb$age_group_ag_0_5_15_18_99.x)) %>% summarise(Anzahl = n()) )
# create final df with komorbidities ans 0-count
df_result_sekundaer_2020_2021_ag_0_5_15_18_99 <- rbind(df_result_sekundaer_2020_2021_ag_0_5_15_18_99,df_con_icd10codes_combined_ag_0_5_15_18_99_diagn2)
df_result_sekundaer_2020_2021_ag_0_5_15_18_99 <- distinct(df_result_sekundaer_2020_2021_ag_0_5_15_18_99, Klinikum, Jahr, Diagn1, Diagn2, Alter, .keep_all= TRUE)
df_result_sekundaer_2020_2021_ag_0_5_15_18_99 <- df_result_sekundaer_2020_2021_ag_0_5_15_18_99 %>% arrange(factor(Alter, levels = c("[0,5]", "[6,15]", "[16,18]", "[19,99]")))
df_result_sekundaer_2020_2021_ag_0_5_15_18_99 <- df_result_sekundaer_2020_2021_ag_0_5_15_18_99[order(df_result_sekundaer_2020_2021_ag_0_5_15_18_99$Diagn2), ]
df_result_sekundaer_2020_2021_ag_0_5_15_18_99 <- df_result_sekundaer_2020_2021_ag_0_5_15_18_99[order(df_result_sekundaer_2020_2021_ag_0_5_15_18_99$Diagn1), ]
df_result_sekundaer_2020_2021_ag_0_5_15_18_99 <- df_result_sekundaer_2020_2021_ag_0_5_15_18_99[order(df_result_sekundaer_2020_2021_ag_0_5_15_18_99$Jahr), ]

df_result_sekundaer_2020_2021_ag_0_5_15_18_99 <- mutate(df_result_sekundaer_2020_2021_ag_0_5_15_18_99, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))

#df_result_sekundaer_2020_2021_ag_0_5_15_18_99_lt20 <- df_result_sekundaer_2020_2021_ag_0_5_15_18_99[df_result_sekundaer_2020_2021_ag_0_5_15_18_99$Alter != "[19,99]", ]
#df_result_sekundaer_2020_2021_ag_0_5_15_18_99_gt20 <- df_result_sekundaer_2020_2021_ag_0_5_15_18_99[df_result_sekundaer_2020_2021_ag_0_5_15_18_99$Alter == "[19,99]", ]

if (length(na.omit(df_covid_komorb$community.x)) != 0) {
  # create table with all possible komorbidities for 0-count in result df
  df_con_icd10codes_combined_ag_0_19_99_diagn2_community <- data.frame()
  for ( year in c("2020", "2021")){
    for ( community in as.character(sort(unique(df_covid_komorb$community.x)))){
      for ( icdcode in sort(con_icd10codes_list)){
        for ( komorbcode in sort(c(komorb_icd10codes_list,"U10.9"))){
          for ( agegroup in as.character(sort(unique(df_covid_komorb$age_group_ag_0_19_99.x)))){
            row <- c(conf$hospital_name,year,community,icdcode,komorbcode,agegroup,as.integer(0))
            df_con_icd10codes_combined_ag_0_19_99_diagn2_community <- rbind(df_con_icd10codes_combined_ag_0_19_99_diagn2_community, row)
          }
        }
      }
    }
  }
  colnames(df_con_icd10codes_combined_ag_0_19_99_diagn2_community) <- c("Klinikum", "Jahr", "Landkreis", "Diagn1", "Diagn2", "Alter", "Anzahl")
  df_con_icd10codes_combined_ag_0_19_99_diagn2_community$Anzahl <- as.integer(df_con_icd10codes_combined_ag_0_19_99_diagn2_community$Anzahl)

  df_result_sekundaer_2020_2021_community <- as.data.frame(df_covid_komorb %>% group_by(Klinikum = df_covid_komorb$hospital_id.x, Jahr = df_covid_komorb$recorded_year.x, Landkreis = df_covid_komorb$community.x, Diagn1 = df_covid_komorb$diagnosis.y, Diagn2 = df_covid_komorb$diagnosis.x, Alter = as.character(df_covid_komorb$age_group_ag_0_19_99.x)) %>% summarise(Anzahl = n()) )
  # create final df with komorbidities ans 0-count
  df_result_sekundaer_2020_2021_community <- rbind(df_result_sekundaer_2020_2021_community,df_con_icd10codes_combined_ag_0_19_99_diagn2_community)
  df_result_sekundaer_2020_2021_community <- na.omit(df_result_sekundaer_2020_2021_community)
  df_result_sekundaer_2020_2021_community <- distinct(df_result_sekundaer_2020_2021_community, Klinikum, Diagn1, Diagn2, Landkreis, Alter, .keep_all= TRUE)
  df_result_sekundaer_2020_2021_community <- df_result_sekundaer_2020_2021_community[order(df_result_sekundaer_2020_2021_community$Jahr), ]
  df_result_sekundaer_2020_2021_community <- df_result_sekundaer_2020_2021_community[order(df_result_sekundaer_2020_2021_community$Alter), ]
  df_result_sekundaer_2020_2021_community <- df_result_sekundaer_2020_2021_community[order(df_result_sekundaer_2020_2021_community$Diagn2), ]
  df_result_sekundaer_2020_2021_community <- df_result_sekundaer_2020_2021_community[order(df_result_sekundaer_2020_2021_community$Diagn1), ]
  df_result_sekundaer_2020_2021_community <- df_result_sekundaer_2020_2021_community[order(df_result_sekundaer_2020_2021_community$Landkreis), ]

  df_result_sekundaer_2020_2021_community <- mutate(df_result_sekundaer_2020_2021_community, Anzahl = ifelse(Anzahl > 0 & Anzahl < 5, "<5", Anzahl))
  #df_result_sekundaer_2020_2021_community_lt20 <- df_result_sekundaer_2020_2021_community[df_result_sekundaer_2020_2021_community$Alter == "[0,18]", ]
  #df_result_sekundaer_2020_2021_community_gt20 <- df_result_sekundaer_2020_2021_community[df_result_sekundaer_2020_2021_community$Alter != "[0,18]", ]
}

now <- format(Sys.time(), "%Y%m%d_%H%M%S")

write.csv(df_result_primaer_2015_2021, file = paste0("results/",now,"_result_primaer_2015_2021.csv"), row.names = FALSE)
write.csv(df_result_primaer_2015_2021_gender, file = paste0("results/",now,"_result_primaer_2015_2021_gender.csv"), row.names = FALSE)
write.csv(df_result_primaer_2015_2021_ag_0_5_15_18_99, file = paste0("results/",now,"_result_primaer_2015_2021_agegroups.csv"), row.names = FALSE)
write.csv(df_result_primaer, file = paste0("results/",now,"_result_primaer.csv"), row.names = FALSE)
write.csv(df_result_primaer_gender, file = paste0("results/",now,"_result_primaer_gender.csv"), row.names = FALSE)
write.csv(df_result_primaer_ag_0_5_15_18_99, file = paste0("results/",now,"_result_primaer_agegroups.csv"), row.names = FALSE)

write.csv(df_result_sekundaer_2015_2021, file = paste0("results/",now,"_result_sekundaer_2015_2021.csv"), row.names = FALSE)
write.csv(df_result_sekundaer_2015_2021_gender, file = paste0("results/",now,"_result_sekundaer_2015_2021_gender.csv"), row.names = FALSE)
write.csv(df_result_sekundaer_2015_2021_ag_0_5_15_18_99, file = paste0("results/",now,"_result_sekundaer_2015_2021_agegroups.csv"), row.names = FALSE)
write.csv(df_result_sekundaer_2020_2021, file = paste0("results/",now,"_result_sekundaer_2020_2021.csv"), row.names = FALSE)
write.csv(df_result_sekundaer_2020_2021_gender, file = paste0("results/",now,"_result_sekundaer_2020_2021_gender.csv"), row.names = FALSE)
write.csv(df_result_sekundaer_2020_2021_ag_0_5_15_18_99, file = paste0("results/",now,"_result_sekundaer_2020_2021_agegroups.csv"), row.names = FALSE)
if (length(na.omit(df_covid_komorb$community.x)) != 0) {
  write.csv(df_result_sekundaer_2020_2021_community, file = paste0("results/",now,"_result_sekundaer_2020_2021_community.csv"), row.names = FALSE)
}

end_time <- Sys.time()
run_time <- end_time - start_time

print(run_time)
