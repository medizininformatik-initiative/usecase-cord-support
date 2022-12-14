####################################################################################################################
# To calculate the aggregate of patients corresponding to
# Phenylketonurie
#####################################################################################################################
start_time <- Sys.time()
options(warn = -1)# to suppress warnings
if (!require("fhircrackr")) {install.packages("fhircrackr"); library(fhircrackr)}
if (!require("config")) {install.packages("config"); library(config)}
if (!require("dplyr")) {install.packages("dplyr"); library(dplyr)}

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
  enddate_custom <- "2019-12-31"
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

rare_icd10codes <- "E70.0,E70.1"

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
                                                   diag_sicherheit_url = "code/coding/extension",
                                                   diag_sicherheit_system = "code/coding/extension/valueCoding/system",
                                                   diag_sicherheit = "code/coding/extension/valueCoding/code",
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

#ftd_patients <- fhir_table_description(resource = "Patient"
#                                       ,cols = NULL
#)

ftd_measurements <- fhir_table_description(resource = "Measure"
                                           ,cols = NULL
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
nchar_for_ids <- 200 #- nchar(search_request_con)
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
  "F32.0,F32.1,F32.2,F32.3,F32.8,F32.9",
  ",F33.0,F33.1,F33.2,F33.3,F33.4,F33.8,F33.9",
  ",F34.0,F34.1,F34.8,F34.9",
  ",G31.0,G31.9",
  ",N18.1,N18.2,N18.3,N18.4,N18.5"
)

con_icd10codes <- paste0(
  rare_icd10codes,",",
  komorb_icd10codes,
  ",O09.0%21,O09.1%21,O09.2%21,O09.3%21,O09.4%21,O09.5%21,O09.6%21,O09.7%21,O09.9%21",
  ",O09.0,O09.1,O09.2,O09.3,O09.4,O09.5,O09.6,O09.7,O09.9",
  ",O09.0%20Z37.0%21,O09.0%20Z37.1%21,O09.0%20Z37.2%21,O09.0%20Z37.3%21,O09.0%20Z37.4%21,O09.0%20Z37.5%21,O09.0%20Z37.6%21,O09.0%20Z37.7%21,O09.0%20Z37.9%21",
  ",O09.1%20Z37.0%21,O09.1%20Z37.1%21,O09.1%20Z37.2%21,O09.1%20Z37.3%21,O09.1%20Z37.4%21,O09.1%20Z37.5%21,O09.1%20Z37.6%21,O09.1%20Z37.7%21,O09.1%20Z37.9%21",
  ",O09.2%20Z37.0%21,O09.2%20Z37.1%21,O09.2%20Z37.2%21,O09.2%20Z37.3%21,O09.2%20Z37.4%21,O09.2%20Z37.5%21,O09.2%20Z37.6%21,O09.2%20Z37.7%21,O09.2%20Z37.9%21",
  ",O09.3%20Z37.0%21,O09.3%20Z37.1%21,O09.3%20Z37.2%21,O09.3%20Z37.3%21,O09.3%20Z37.4%21,O09.3%20Z37.5%21,O09.3%20Z37.6%21,O09.3%20Z37.7%21,O09.3%20Z37.9%21",
  ",O09.4%20Z37.0%21,O09.4%20Z37.1%21,O09.4%20Z37.2%21,O09.4%20Z37.3%21,O09.4%20Z37.4%21,O09.4%20Z37.5%21,O09.4%20Z37.6%21,O09.4%20Z37.7%21,O09.4%20Z37.9%21",
  ",O09.5%20Z37.0%21,O09.5%20Z37.1%21,O09.5%20Z37.2%21,O09.5%20Z37.3%21,O09.5%20Z37.4%21,O09.5%20Z37.5%21,O09.5%20Z37.6%21,O09.5%20Z37.7%21,O09.5%20Z37.9%21",
  ",O09.6%20Z37.0%21,O09.6%20Z37.1%21,O09.6%20Z37.2%21,O09.6%20Z37.3%21,O09.6%20Z37.4%21,O09.6%20Z37.5%21,O09.6%20Z37.6%21,O09.6%20Z37.7%21,O09.6%20Z37.9%21",
  ",O09.7%20Z37.0%21,O09.7%20Z37.1%21,O09.7%20Z37.2%21,O09.7%20Z37.3%21,O09.7%20Z37.4%21,O09.7%20Z37.5%21,O09.7%20Z37.6%21,O09.7%20Z37.7%21,O09.7%20Z37.9%21",
  ",O09.9%20Z37.0%21,O09.8%20Z37.1%21,O09.9%20Z37.2%21,O09.9%20Z37.3%21,O09.9%20Z37.4%21,O09.9%20Z37.5%21,O09.9%20Z37.6%21,O09.9%20Z37.7%21,O09.9%20Z37.9%21",
  ",O24.4",
  ",O30.0,O30.1,O30.2,O30.8,O30.9",
  ",O63.0,O63.1,O63.2,O63.9",
  ",O64.0,O64.1,O64.2,O64.3,O64.4,O64.5,O64.8,O64.9",
  ",O64.0%20Z37.0%21,O64.0%20Z37.1%21,O64.0%20Z37.2%21,O64.0%20Z37.3%21,O64.0%20Z37.4%21,O64.0%20Z37.5%21,O64.0%20Z37.6%21,O64.0%20Z37.7%21,O64.0%20Z37.9%21",
  ",O64.1%20Z37.0%21,O64.1%20Z37.1%21,O64.1%20Z37.2%21,O64.1%20Z37.3%21,O64.1%20Z37.4%21,O64.1%20Z37.5%21,O64.1%20Z37.6%21,O64.1%20Z37.7%21,O64.1%20Z37.9%21",
  ",O64.2%20Z37.0%21,O64.2%20Z37.1%21,O64.2%20Z37.2%21,O64.2%20Z37.3%21,O64.2%20Z37.4%21,O64.2%20Z37.5%21,O64.2%20Z37.6%21,O64.2%20Z37.7%21,O64.2%20Z37.9%21",
  ",O64.3%20Z37.0%21,O64.3%20Z37.1%21,O64.3%20Z37.2%21,O64.3%20Z37.3%21,O64.3%20Z37.4%21,O64.3%20Z37.5%21,O64.3%20Z37.6%21,O64.3%20Z37.7%21,O64.3%20Z37.9%21",
  ",O64.4%20Z37.0%21,O64.4%20Z37.1%21,O64.4%20Z37.2%21,O64.4%20Z37.3%21,O64.4%20Z37.4%21,O64.4%20Z37.5%21,O64.4%20Z37.6%21,O64.4%20Z37.7%21,O64.4%20Z37.9%21",
  ",O64.5%20Z37.0%21,O64.5%20Z37.1%21,O64.5%20Z37.2%21,O64.5%20Z37.3%21,O64.5%20Z37.4%21,O64.5%20Z37.5%21,O64.5%20Z37.6%21,O64.5%20Z37.7%21,O64.5%20Z37.9%21",
  ",O64.8%20Z37.0%21,O64.8%20Z37.1%21,O64.8%20Z37.2%21,O64.8%20Z37.3%21,O64.8%20Z37.4%21,O64.8%20Z37.5%21,O64.8%20Z37.6%21,O64.8%20Z37.7%21,O64.8%20Z37.9%21",
  ",O64.9%20Z37.0%21,O64.8%20Z37.1%21,O64.9%20Z37.2%21,O64.9%20Z37.3%21,O64.9%20Z37.4%21,O64.9%20Z37.5%21,O64.9%20Z37.6%21,O64.9%20Z37.7%21,O64.9%20Z37.9%21",
  ",O75.0,O75.1,O75.2,O75.3,O75.4,O75.5,O75.6,O75.7,O75.8,O75.9",
  ",O80,O81,O82",
  ",O80%20Z37.0%21,O81%20Z37.0%21,O82%20Z37.0%21",
  ",O80%20Z37.1%21,O81%20Z37.1%21,O82%20Z37.1%21",
  ",O80%20Z37.2%21,O81%20Z37.2%21,O82%20Z37.2%21",
  ",O80%20Z37.3%21,O81%20Z37.3%21,O82%20Z37.3%21",
  ",O80%20Z37.4%21,O81%20Z37.4%21,O82%20Z37.4%21",
  ",O80%20Z37.5%21,O81%20Z37.5%21,O82%20Z37.5%21",
  ",O80%20Z37.6%21,O81%20Z37.6%21,O82%20Z37.6%21",
  ",O80%20Z37.7%21,O81%20Z37.7%21,O82%20Z37.7%21",
  ",O80%20Z37.9%21,O81%20Z37.9%21,O82%20Z37.9%21",
  ",Z37.0,Z37.1,Z37.2,Z37.3,Z37.4,Z37.5,Z37.6,Z37.7,Z37.9",
  ",Z38.0,Z38.1,Z38.2,Z38.3,Z38.4,Z38.5,Z38.6,Z38.7,Z38.8"
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

# remove the reference_prefix from column patient_id & encounter_id in condition resource
df_conditions_tmp$patient_id <- sub(subject_reference_prefix, "", df_conditions_tmp[, "patient_id"])
df_conditions_tmp$encounter_id <- sub(encounter_reference_prefix, "", df_conditions_tmp[, "encounter_id"])

# unnest raw conditions dataframe columns diagnosis, system
melt_columns <- c("diagnosis", "system")
df_conditions_tmp <- fhir_melt(df_conditions_tmp,
                               columns = melt_columns,
                               brackets = c("[", "]"), sep = "|", all_columns = TRUE)

# unnest raw conditions dataframe columns diagnosis, system
df_conditions_tmp <- fhir_melt(df_conditions_tmp,
                               columns = melt_columns,
                               brackets = c("[", "]"), sep = "|", all_columns = TRUE)

df_conditions_tmp <- fhir_rm_indices(df_conditions_tmp, brackets = c("[", "]"))

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

if (!any(grepl('diagnosesicherheit', df_conditions_raw$diag_sicherheit_url, ignore.case = TRUE)) ) {
  #message("Diagnosesicherheit not found.")
  diag_sicherheit <- FALSE
} else {
  message("Diagnosesicherheit found. Please check conf.yml.sample for configuration.")
  diag_sicherheit <- TRUE
}

# set age groups
x <- c(1, 17, 31, 99)
df_conditions_patients$age_group <- cut(df_conditions_patients$age, x, breaks = c(0, 17, 30, 99), labels = c("[0,17]", "[18,30]", "[31,99]"))

# filter conditions for ICD-Code E70*
df_conditions_pku <- subset(df_conditions_patients, grepl("^E70", diagnosis))

# group patients by age
df_pku_agegroup <- df_conditions_pku
df_pku_agegroup_ges <- subset(df_pku_agegroup, grepl("^E70", diagnosis))
df_pku_agegroup_ges <- df_pku_agegroup_ges[!duplicated(df_pku_agegroup_ges$patient_id), ]
df_pku_agegroup_0 <- subset(df_pku_agegroup, grepl("^E70.0", diagnosis))
df_pku_agegroup_0 <- df_pku_agegroup_0[!duplicated(df_pku_agegroup_0$patient_id), ]
df_pku_agegroup_1 <- subset(df_pku_agegroup, grepl("^E70.1", diagnosis))
df_pku_agegroup_1 <- df_pku_agegroup_1[!duplicated(df_pku_agegroup_1$patient_id), ]

df_pku_agegroup_ges <- as.data.frame(df_pku_agegroup_ges %>% group_by(hospital_id = df_pku_agegroup_ges$hospital_id, diagnosis = "E70.*", age_group = df_pku_agegroup_ges$age_group) %>% summarise(gesamt = n()) )
df_pku_agegroup_0 <- as.data.frame(df_pku_agegroup_0 %>% group_by(hospital_id = df_pku_agegroup_0$hospital_id, diagnosis = df_pku_agegroup_0$diagnosis, age_group = df_pku_agegroup_0$age_group) %>% summarise(anzahl = n()) )
df_pku_agegroup_1 <- as.data.frame(df_pku_agegroup_1 %>% group_by(hospital_id = df_pku_agegroup_1$hospital_id, diagnosis = df_pku_agegroup_1$diagnosis, age_group = df_pku_agegroup_1$age_group) %>% summarise(anzahl = n()) )

df_pku_agegroup <- rbind(df_pku_agegroup_0,df_pku_agegroup_1)

# merge agegroups to df pku 
df_conditions_pku <- base::merge(df_conditions_pku, df_pku_agegroup, by = c("diagnosis","age_group","hospital_id"))
df_conditions_pku <- base::merge(df_conditions_pku, df_pku_agegroup_ges, by = c("age_group","hospital_id"))

names(df_conditions_pku)[names(df_conditions_pku) == "diagnosis.y"] <- "diagnosis_e70.*"

df_conditions_pku_0 <- subset(df_conditions_pku, grepl("^E70.0", diagnosis.x))

df_conditions_pku_1 <- subset(df_conditions_pku, grepl("^E70.1", diagnosis.x))

count_patients_e70_ges <- nrow(df_conditions_pku[!base::duplicated(as.character(df_conditions_pku$patient_id)), ])
count_patients_e70_0 <- nrow(df_conditions_pku_0[!base::duplicated(as.character(df_conditions_pku_0$patient_id)), ])
count_patients_e70_1 <- nrow(df_conditions_pku_1[!base::duplicated(as.character(df_conditions_pku_1$patient_id)), ])

# get comorbidties
df_conditions_n18 <- subset(df_conditions_patients, grepl("^N18", diagnosis))

df_pku_0_n18 <- base::merge(df_conditions_pku_0, df_conditions_n18, by = "patient_id")
df_pku_0_n18 <- df_pku_0_n18[!duplicated(df_pku_0_n18$patient_id), ]
df_pku_0_n18 <- df_pku_0_n18 %>% select(-contains("resource_identifier"))

df_pku_1_n18 <- base::merge(df_conditions_pku_1, df_conditions_n18, by = "patient_id")
df_pku_1_n18 <- df_pku_1_n18[!duplicated(df_pku_1_n18$patient_id), ]
df_pku_1_n18 <- df_pku_1_n18 %>% select(-contains("resource_identifier"))

df_conditions_f32 <- subset(df_conditions_patients, grepl("^F32", diagnosis))

df_pku_0_f32 <- base::merge(df_conditions_pku_0, df_conditions_f32, by = "patient_id")
df_pku_0_f32 <- df_pku_0_f32[!duplicated(df_pku_0_f32$patient_id), ]
df_pku_0_f32 <- df_pku_0_f32 %>% select(-contains("resource_identifier"))

df_pku_1_f32 <- base::merge(df_conditions_pku_1, df_conditions_f32, by = "patient_id")
df_pku_1_f32 <- df_pku_1_f32[!duplicated(df_pku_1_f32$patient_id), ]
df_pku_1_f32 <- df_pku_1_f32 %>% select(-contains("resource_identifier"))

df_conditions_f33 <- subset(df_conditions_patients, grepl("^F33", diagnosis))

df_pku_0_f33 <- base::merge(df_conditions_pku_0, df_conditions_f33, by = "patient_id")
df_pku_0_f33 <- df_pku_0_f33[!duplicated(df_pku_0_f33$patient_id), ]
df_pku_0_f33 <- df_pku_0_f33 %>% select(-contains("resource_identifier"))

df_pku_1_f33 <- base::merge(df_conditions_pku_1, df_conditions_f33, by = "patient_id")
df_pku_1_f33 <- df_pku_1_f33[!duplicated(df_pku_1_f33$patient_id), ]
df_pku_1_f33 <- df_pku_1_f33 %>% select(-contains("resource_identifier"))

df_conditions_f34 <- subset(df_conditions_patients, grepl("^F34", diagnosis))

df_pku_0_f34 <- base::merge(df_conditions_pku_0, df_conditions_f34, by = "patient_id")
df_pku_0_f34 <- df_pku_0_f34[!duplicated(df_pku_0_f34$patient_id), ]
df_pku_0_f34 <- df_pku_0_f34 %>% select(-contains("resource_identifier"))

df_pku_1_f34 <- base::merge(df_conditions_pku_1, df_conditions_f34, by = "patient_id")
df_pku_1_f34 <- df_pku_1_f34[!duplicated(df_pku_1_f34$patient_id), ]
df_pku_1_f34 <- df_pku_1_f34 %>% select(-contains("resource_identifier"))

df_conditions_g31 <- subset(df_conditions_patients, grepl("^G31", diagnosis))

df_pku_0_g31 <- base::merge(df_conditions_pku_0, df_conditions_g31, by = "patient_id")
df_pku_0_g31 <- df_pku_0_g31[!duplicated(df_pku_0_g31$patient_id), ]
df_pku_0_g31 <- df_pku_0_g31 %>% select(-contains("resource_identifier"))

df_pku_1_g31 <- base::merge(df_conditions_pku_1, df_conditions_g31, by = "patient_id")
df_pku_1_g31 <- df_pku_1_g31[!duplicated(df_pku_1_g31$patient_id), ]
df_pku_1_g31 <- df_pku_1_g31 %>% select(-contains("resource_identifier"))

# combine all comorbidities into one df
df_pku_result_primaer <- rbind(df_pku_0_n18, df_pku_1_n18, df_pku_0_f32, df_pku_1_f32, df_pku_0_f33, df_pku_1_f33, df_pku_0_f34, df_pku_1_f34, df_pku_0_g31, df_pku_1_g31)
if (nrow(df_pku_result_primaer) == 0) {
  stop('No comorbidities found...exiting')
}

df_pku_result_primaer_0 <- subset(df_pku_result_primaer, grepl("^E70.0", diagnosis.x))
df_pku_result_primaer_1 <- subset(df_pku_result_primaer, grepl("^E70.1", diagnosis.x))

df_result_primaer_0 <- as.data.frame(df_pku_result_primaer_0 %>% group_by(Klinikum = df_pku_result_primaer_0$hospital_id.x, Diagn1 = df_pku_result_primaer_0$diagnosis.x, Diagn2 = df_pku_result_primaer_0$diagnosis) %>% summarise(Anzahl = n()) )
df_result_primaer_1 <- as.data.frame(df_pku_result_primaer_1 %>% group_by(Klinikum = df_pku_result_primaer_1$hospital_id.x, Diagn1 = df_pku_result_primaer_1$diagnosis.x, Diagn2 = df_pku_result_primaer_1$diagnosis) %>% summarise(Anzahl = n()) )

rare_icd10codes_list <- as.list(strsplit(rare_icd10codes, ',')[[1]])
komorb_icd10codes_list <- as.list(strsplit(komorb_icd10codes, ",")[[1]])

# create table with all possible comorbidities for 0-count in result df
df_rare_komorb_icd10codes_combined <- data.frame()
for ( i in rare_icd10codes_list){
  for ( j in komorb_icd10codes_list){
    row <- c(conf$hospital_name,i,j,as.numeric(0))
    df_rare_komorb_icd10codes_combined <- rbind(df_rare_komorb_icd10codes_combined, row)
  }
}
colnames(df_rare_komorb_icd10codes_combined)<-c("Klinikum", "Diagn1", "Diagn2", "Anzahl")

df_result_primaer <- as.data.frame(df_pku_result_primaer %>% group_by(Klinikum = df_pku_result_primaer$hospital_id.x, Diagn1 = df_pku_result_primaer$diagnosis.x, Diagn2 = df_pku_result_primaer$diagnosis) %>% summarise(Anzahl = n()) )

# create final df with comorbidities ans 0-count
df_result_primaer <- rbind(df_result_primaer,df_rare_komorb_icd10codes_combined)

if (nrow(df_pku_result_primaer) == 0) {
  result_sekundaer_a <- 0
} else {
  # sum all pku 
  result_sekundaer_a <- round(sum(as.numeric(df_result_primaer$Anzahl)) / count_patients_e70_ges * 100, 2)
}
result_sekundaer_a <- paste0(result_sekundaer_a, "% aller PKU Patient:innen haben internistische, neurologische und psychiatrische Komorbiditäten.")

df_result_primaer <- mutate(df_result_primaer, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

# rel % agegroups
df_result_sekundaer_b_0 <- as.data.frame(df_pku_result_primaer_0 %>% group_by(Klinikum = df_pku_result_primaer_0$hospital_id.x, Diagn1 = df_pku_result_primaer_0$diagnosis.x, Diagn2 = df_pku_result_primaer_0$diagnosis, Alter = df_pku_result_primaer_0$age_group.x) %>% summarise(Anzahl = n()) %>% mutate("% E70.0 Patienten" = paste0(round(100 * Anzahl / count_patients_e70_0, 2), "%")) %>% mutate("% alle PKU Patienten" = paste0(round(100 * Anzahl / count_patients_e70_ges, 2), "%")))
df_result_sekundaer_b_0 <- df_result_sekundaer_b_0 %>% select(-contains("Anzahl"))
df_result_sekundaer_b_1 <- as.data.frame(df_pku_result_primaer_1 %>% group_by(Klinikum = df_pku_result_primaer_1$hospital_id.x, Diagn1 = df_pku_result_primaer_1$diagnosis.x, Diagn2 = df_pku_result_primaer_1$diagnosis, Alter = df_pku_result_primaer_1$age_group.x) %>% summarise(Anzahl = n()) %>% mutate("% E70.1 Patienten" = paste0(round(100 * Anzahl / count_patients_e70_1, 2), "%")) %>% mutate("% alle PKU Patienten" = paste0(round(100 * Anzahl / count_patients_e70_ges, 2), "%")))
df_result_sekundaer_b_1 <- df_result_sekundaer_b_1 %>% select(-contains("Anzahl"))
df_result_sekundaer_b_ges <- as.data.frame(df_pku_result_primaer %>% group_by(Klinikum = df_pku_result_primaer$hospital_id.x, Diagn1 = df_pku_result_primaer$diagnosis_e70, Diagn2 = df_pku_result_primaer$diagnosis, Alter = df_pku_result_primaer$age_group.x) %>% summarise(Anzahl = n()) %>% mutate("% alle PKU Patienten" = paste0(round(100 * Anzahl / count_patients_e70_ges, 2), "%")) )
df_result_sekundaer_b_ges <- df_result_sekundaer_b_ges %>% select(-contains("Anzahl"))

# get all patients with birth and birth complications codes
df_conditions_birth <- subset(df_conditions_patients, grepl("^O09|^O3|^O63|^O8|^Z", diagnosis))

df_pku_birth <- base::merge(df_conditions_pku, df_conditions_birth, by = "patient_id")
df_pku_birth <- df_pku_birth[!duplicated(df_pku_birth$patient_id), ]
df_pku_birth <- subset(df_pku_birth, !grepl("^Z38", diagnosis.x))
df_pku_birth <- subset(df_pku_birth, !grepl("^Z38", diagnosis))
df_pku_birth <- df_pku_birth %>% select(-contains("resource_identifier"))
names(df_pku_birth)[names(df_pku_birth) == "diagnosis.x"] <- "diagnosis.z"

df_conditions_complication <- subset(df_conditions_patients, grepl("^O64|^O75|^O24", diagnosis))

df_pku_complication <- base::merge(df_conditions_complication, df_pku_birth, by = "patient_id")
df_pku_complication <- df_pku_complication[!duplicated(df_pku_complication$patient_id), ]
df_pku_complication <- subset(df_pku_complication, !grepl("^Z38", diagnosis.y))
df_pku_complication <- df_pku_complication %>% select(-contains("resource_identifier"))

df_result_sekundaer_c <- as.data.frame(df_pku_complication %>% group_by(Klinikum = df_pku_complication$hospital_id.x, Diagn1 = df_pku_complication$diagnosis.z, Diagn2 = df_pku_complication$diagnosis.x) %>% summarise(Anzahl = n()) )
df_result_sekundaer_c <- mutate(df_result_sekundaer_c, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

# filter conditions for ICD-Codes for Birth O* and Z37, Z38
df_conditions_birth_all <- subset(df_conditions_patients, grepl("^O|^Z", diagnosis))

# merge CF and Birth dataframes by patient
df_pku_birth_all <- base::merge(df_conditions_pku, df_conditions_birth_all, by = "patient_id")
df_pku_birth_all <- df_pku_birth_all[!duplicated(df_pku_birth_all$encounter_id.y), ]

# filter all "children"
df_pku_birth_all <- subset(df_pku_birth_all, !grepl("^Z38", diagnosis))

mother_ids <- unique(df_pku_birth_all$patient_id)

search_request_children <- fhir_url(url = conf$serverbase,
                                    resource = "Patient",
                                    parameters = c(
                                    "link" = paste(as.character(mother_ids), collapse=","),
                                    count_custom
                                    )
)

children_bundle <- fhir_search(request = search_request_children,
                               username = conf$username,
                               password = conf$password,
                               token = conf$token,
                               verbose = 2,
                               max_bundles = max_bundles_custom)
  
df_children_raw <- fhir_crack(children_bundle, ftd_patients, sep = "|", brackets = c("[", "]"), verbose = 2)

df_children_tmp <- fhir_melt(df_children_raw,
                             columns = c("patient_zip", "countrycode"),
                             brackets = c("[", "]"), sep = "|", all_columns = TRUE)

df_children_tmp <- fhir_rm_indices(df_children_tmp, brackets = c("[", "]"))

# remove duplicate entries
df_children_tmp <- df_children_tmp[!duplicated(df_children_tmp$patient_id), ]

children_ids <- paste0(subject_reference_prefix,unique(df_children_tmp$patient_id))

search_request_mea <- fhir_url(url = conf$serverbase,
                               resource = "Measure",
                               parameters = c(
                               "subject" = paste(as.character(children_ids), collapse=","),
                               count_custom
                             )
)

children_mea_bundle <- fhir_search(request = search_request_mea,
                                   username = conf$username,
                                   password = conf$password,
                                   token = conf$token,
                                   verbose = 2,
                                   max_bundles = max_bundles_custom)

df_children_mea_raw <- fhir_crack(children_mea_bundle, ftd_measurements, sep = "|", brackets = c("[", "]"), verbose = 2)

now <- format(Sys.time(), "%Y%m%d_%H%M%S")

# display the final output
df_result_primaer
result_sekundaer_a
df_result_sekundaer_b_0
df_result_sekundaer_b_1
df_result_sekundaer_b_ges
df_result_sekundaer_c

write.csv(df_result_primaer, file = paste0("results/",now,"_result_primaer.csv"), row.names = FALSE)
write.csv(result_sekundaer_a, file = paste0("results/",now,"_result_sekundaer_a.csv"), row.names = FALSE)
if (nrow(df_result_sekundaer_b_0) != 0) {
  write.csv(df_result_sekundaer_b_0, file = paste0("results/",now,"_result_sekundaer_b_e70_0.csv"), row.names = FALSE)
}
if (nrow(df_result_sekundaer_b_1) != 0) {
  write.csv(df_result_sekundaer_b_1, file = paste0("results/",now,"_result_sekundaer_b_e70_1.csv"), row.names = FALSE)
}
if (nrow(df_result_sekundaer_b_ges) != 0) {
  write.csv(df_result_sekundaer_b_ges, file = paste0("results/",now,"_result_sekundaer_b_ges.csv"), row.names = FALSE)
}
if (nrow(df_result_sekundaer_c) != 0) {
  write.csv(df_result_sekundaer_c, file = paste0("results/",now,"_result_sekundaer_c.csv"), row.names = FALSE)
}

end_time <- Sys.time()
run_time <- end_time - start_time
print(run_time)
