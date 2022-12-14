 ####################################################################################################################
# To calculate the aggregate of patients corresponding to
# Mukoviszidose/CF Cystic Fibrosis and Birth
####################################################################################################################
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

rare_icd10codes <- "E84.0,E84.1,E84.8,E84.80,E84.87,E84.88,E84.9"

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
  "J18.0,J18.1,J18.2,J18.8,J18.9"
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

# filter conditions for ICD-Code E84*
df_conditions_cf <- subset(df_conditions_patients, grepl("^E84", diagnosis))
df_conditions_cf$diagnosis <- "E84*"

if (!any(grepl('diagnosesicherheit', df_conditions_raw$diag_sicherheit_url, ignore.case = TRUE)) ) {
  #message("Diagnosesicherheit not found.")
  diag_sicherheit <- FALSE
} else {
  message("Diagnosesicherheit found. Please check conf.yml.sample for configuration.")
  diag_sicherheit <- TRUE
} 

if ((diag_sicherheit) && (use_diag_sicherheit)) {
  df_conditions_cf <- subset(df_conditions_cf, grepl("G", diag_sicherheit))
  message("Using Diagnosesicherheit for evaluation.")
} else {
  df_conditions_cf <- df_conditions_cf
}

# filter conditions for ICD-Codes for Birth O* and Z37, Z38
df_conditions_birth_all <- subset(df_conditions_patients, grepl("^O|^Z", diagnosis))

# merge CF and Birth dataframes by patient
df_cf_birth_all <- base::merge(df_conditions_cf, df_conditions_birth_all, by = "patient_id")
df_cf_birth_all <- df_cf_birth_all[!duplicated(df_cf_birth_all$encounter_id.y), ]

# filter all "children"
df_cf_birth_all <- subset(df_cf_birth_all, !grepl("^Z38", diagnosis.y))

mother_ids <- unique(df_cf_birth_all$patient_id)

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

result_primaer_count <- ifelse(length(df_cf_birth_all$patient_id) <= 5, "<5", length(df_cf_birth_all$patient_id))

df_result_primaer_count <- as.data.frame(df_cf_birth_all %>% group_by(Einrichtungsindikator = df_cf_birth_all$hospital_id.x, Diagn1 = df_cf_birth_all$diagnosis.x, Diagn2 = "O80 etc.") %>% summarise(Anzahl = n()) )
df_result_primaer_count <- mutate(df_result_primaer_count, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

df_result_primaer <- as.data.frame(df_cf_birth_all %>% group_by(Einrichtungsindikator = df_cf_birth_all$hospital_id.x, Diagn1 = df_cf_birth_all$diagnosis.x, Diagn2 = df_cf_birth_all$diagnosis.y) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer <- mutate(df_result_primaer, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

df_conditions_birth <- subset(df_conditions_patients, grepl("^O09|^O3|^O63|^O8|^Z", diagnosis))
df_conditions_complication <- subset(df_conditions_patients, grepl("^O64|^O75|^O24", diagnosis))
df_cf_complication <- base::merge(df_conditions_cf, df_conditions_birth, by = "patient_id")
df_cf_complication <- base::merge(df_cf_complication, df_conditions_complication, by = "patient_id")
df_cf_complication <- df_cf_complication[!duplicated(df_cf_complication$encounter_id), ]
df_cf_complication <- subset(df_cf_complication, !grepl("^Z38", diagnosis.y))

df_result_sekundaer_b <- as.data.frame(df_cf_complication %>% group_by(Einrichtungsindikator = df_cf_complication$hospital_id.x, Diagn1 = df_cf_complication$diagnosis.x, Diagn2 = df_cf_complication$diagnosis) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_sekundaer_b <- mutate(df_result_sekundaer_b, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

# display the final output
df_result_primaer_count
df_result_primaer
df_result_sekundaer_b
now <- format(Sys.time(), "%Y%m%d_%H%M%S")
########################################################################################################################################################
# write result to a csv file
########################################################################################################################################################
write.csv(df_result_primaer_count, file = paste0("results/",now,"_result_primaer_gesamt.csv"), row.names = FALSE)
write.csv(df_result_primaer, file = paste0("results/",now,"_result_primaer.csv"), row.names = FALSE)
write.csv(df_result_sekundaer_b, file = paste0("results/",now,"_result_sekundaer_b.csv"), row.names = FALSE)
########################################################################################################################################################
end_time <- Sys.time()
run_time <- end_time - start_time
print(run_time)