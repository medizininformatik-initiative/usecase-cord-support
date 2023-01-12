####################################################################################################################
# To calculate the aggregate of patients corresponding to
# Kawasaki / PIMS
####################################################################################################################
start_time <- Sys.time()
options(warn = -1)# to suppress warnings
if (!require("fhircrackr")) {install.packages("fhircrackr"); library(fhircrackr)}
if (!require("config")) {install.packages("config"); library(config)}
if (!require("dplyr")) {install.packages("dplyr"); library(dplyr)}

setwd(dirname(rstudioapi::getSourceEditorContext()$path))
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
  enddate_custom <- "2022-12-31"
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

#"M30.3 R65.2!"
#"D76.1 R65.3!"
#"A48.3 R65.0!"
#"R57.8 R65.0!"
#"R57.8 R65.1!"

rare_icd10codes <- "A48.3,D76.1,D76.2,D76.3,D76.4,D89.8,D89.9,I25.4,I30.1,I30.8,I30.9,I32.1,I40.0,I40.1,I40.8,I40.9,I41.1,I41.8,M30.3,R57.8,R65.0,R65.1,R65.2,R65.3,R65.9,R65.0%21,R65.1%21,R65.2%21,R65.3%21,R65.9%21,U10.9"
rare_icd10_combinations_a48 <- ",A48.3%20R65.0%21,A48.3%20R65.1%21,A48.3%20R65.2%21,A48.3%20R65.3%21,A48.3%20R65.4%21,A48.3%20R65.5%21,A48.3%20R65.6%21,A48.3%20R65.7%21,A48.3%20R65.8%21,A48.3%20R65.9%21"
rare_icd10_combinations_d76_1 <- ",D76.1%20R65.0%21,D76.1%20R65.1%21,D76.1%20R65.2%21,D76.1%20R65.3%21,D76.1%20R65.4%21,D76.1%20R65.5%21,D76.1%20R65.6%21,D76.1%20R65.7%21,D76.1%20R65.8%21,D76.1%20R65.9%21"
rare_icd10_combinations_d76_2 <- ",D76.2%20R65.0%21,D76.2%20R65.1%21,D76.2%20R65.2%21,D76.2%20R65.3%21,D76.2%20R65.4%21,D76.2%20R65.5%21,D76.2%20R65.6%21,D76.2%20R65.7%21,D76.2%20R65.8%21,D76.2%20R65.9%21"
rare_icd10_combinations_d76_3 <- ",D76.3%20R65.0%21,D76.3%20R65.1%21,D76.3%20R65.2%21,D76.3%20R65.3%21,D76.3%20R65.4%21,D76.3%20R65.5%21,D76.3%20R65.6%21,D76.3%20R65.7%21,D76.3%20R65.8%21,D76.3%20R65.9%21"
rare_icd10_combinations_d76_4 <- ",D76.4%20R65.0%21,D76.4%20R65.1%21,D76.4%20R65.2%21,D76.4%20R65.3%21,D76.4%20R65.4%21,D76.4%20R65.5%21,D76.4%20R65.6%21,D76.4%20R65.7%21,D76.4%20R65.8%21,D76.4%20R65.9%21"
rare_icd10_combinations_r57 <- ",R57.8%20R65.0%21,R57.8%20R65.1%21,R57.8%20R65.2%21,R57.8%20R65.3%21,R57.8%20R65.4%21,R57.8%20R65.5%21,R57.8%20R65.6%21,R57.8%20R65.7%21,R57.8%20R65.8%21,R57.8%20R65.9%21"
rare_icd10codes <- paste0(rare_icd10codes,rare_icd10_combinations_a48,rare_icd10_combinations_d76_1,rare_icd10_combinations_d76_2,rare_icd10_combinations_d76_3,rare_icd10_combinations_d76_4,rare_icd10_combinations_r57)

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
  ",U07.1%21,U07.2%21,U07.4%21",
  ",U08.9",
  ",U09.9",
  ",U09.9%21"
)

con_icd10codes <- paste0(
  rare_icd10codes,",",
  komorb_icd10codes,
  "I25.4",
  ",I30.1,I30.8,I30.9",
  ",I32.1",
  ",I40.0,I40.1,I40.8,I40.9",
  ",I41.1,I41.8"
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
x_0_20_99 <- c(0, 20, 99)
x_m <- c(1, 3, 12)
x <- c(1, 3, 5, 10, 15, 18, 20, 99)
df_conditions_patients$age_group_0_20_99 <- cut(df_conditions_patients$age_dec, x_0_20_99, breaks = c(0, 20, 99), labels = c("[0,20a]", "[21,99a]"))
df_conditions_patients$age_group_m <- cut(df_conditions_patients$age_dec*12, x_m, breaks = c(0, 3, 12), labels = c("[0,3m]", "[3,12m]"))
df_conditions_patients$age_group <- cut(df_conditions_patients$age, x, breaks = c(1, 3, 5, 10, 15, 18, 20, 99), labels = c("[1,3a]", "[4,5a]", "[6,10a]", "[11,15a]", "[16,18a]", "[19,20a]", "[21,99a]"))
df_conditions_patients <- df_conditions_patients %>% mutate(age_group = coalesce(age_group_m,age_group))

df_conditions_patients$recorded_year <- format(df_conditions_patients$recorded_date, format="%Y")

#Wie häufig wird das Kawasaki-Syndrom bzw. PIMS im Zeitverlauf dokumentiert?
#Es sollen die jeweiligen Häufigkeiten Diagnosekodierung 
#M30.3 und D76.1-4, A48.3, R57.8, R65.0-9, D89.8/9 sowie U10.9 
#gemäß der Kataloge ICD-10-GM 2015 bis 2022 über einen Zeitraum von 2015 bis 2022 
#erfasst und Unterschiede zwischen dem Pandemiezeitraum/Pandemiezeiträumen 
#inklusive der Häufigkeit von COVID-19-Fällen (RKI-Meldedaten) und den übrigen Zeiträumen dargestellt werden.

# filter conditions for ICD-Code A48.3
df_conditions_a48_3 <- subset(df_conditions_patients, grepl("^A48.3", diagnosis))
# remove diag_sicherheit A
df_conditions_a48_3 <- subset(df_conditions_a48_3, !grepl("A$", diag_sicherheit))
# filter duplicated patient_ids
df_conditions_a48_3 <- df_conditions_a48_3[!duplicated(df_conditions_a48_3$patient_id), ]

df_conditions_d76 <- subset(df_conditions_patients, grepl("^D76", diagnosis))
df_conditions_d76 <- subset(df_conditions_d76, !grepl("A$", diag_sicherheit))
df_conditions_d76 <- df_conditions_d76[!duplicated(df_conditions_d76$patient_id), ]

df_conditions_d89_8_9 <- subset(df_conditions_patients, grepl("^D89.8|^D89.9", diagnosis))
df_conditions_d89_8_9 <- subset(df_conditions_d89_8_9, !grepl("A$", diag_sicherheit))
df_conditions_d89_8_9 <- df_conditions_d89_8_9[!duplicated(df_conditions_d89_8_9$patient_id), ]

df_conditions_m30_3 <- subset(df_conditions_patients, grepl("^M30.3", diagnosis))
df_conditions_m30_3 <- subset(df_conditions_m30_3, !grepl("A$", diag_sicherheit))
df_conditions_m30_3 <- df_conditions_m30_3[!duplicated(df_conditions_m30_3$patient_id), ]

df_conditions_r57_8 <- subset(df_conditions_patients, grepl("^R57.8", diagnosis))
df_conditions_r57_8 <- subset(df_conditions_r57_8, !grepl("A$", diag_sicherheit))
df_conditions_r57_8 <- df_conditions_r57_8[!duplicated(df_conditions_r57_8$patient_id), ]

df_conditions_r65 <- subset(df_conditions_patients, grepl("^R65", diagnosis))
df_conditions_r65 <- subset(df_conditions_r65, !grepl("A$", diag_sicherheit))
df_conditions_r65 <- df_conditions_r65[!duplicated(df_conditions_r65$patient_id), ]

df_conditions_u10_9 <- subset(df_conditions_patients, grepl("^U10.9", diagnosis))
df_conditions_u10_9 <- subset(df_conditions_u10_9, !grepl("A$", diag_sicherheit))
df_conditions_u10_9 <- df_conditions_u10_9[!duplicated(df_conditions_u10_9$patient_id), ]

df_conditions_d76_4 <- subset(df_conditions_patients, grepl("^D76.4", diagnosis))
df_conditions_d76_4 <- subset(df_conditions_d76_4, !grepl("A$", diag_sicherheit))
df_conditions_d76_4 <- df_conditions_d76_4[!duplicated(df_conditions_d76_4$patient_id), ]
#df_conditions_d76_4 <- df_conditions_d76_4[df_conditions_d76_4$age < "20", ]
df_conditions_d76_4

df_conditions_d89_9 <- subset(df_conditions_patients, grepl("^D89.9", diagnosis))
df_conditions_d89_9 <- subset(df_conditions_d89_9, !grepl("A$", diag_sicherheit))
df_conditions_d89_9 <- df_conditions_d89_9[!duplicated(df_conditions_d89_9$patient_id), ]
#df_conditions_d89_9 <- df_conditions_d89_9[df_conditions_d89_9$age < "20", ]
df_conditions_d89_9

df_conditions_i25_4 <- subset(df_conditions_patients, grepl("^I25.4", diagnosis))
df_conditions_i25_4 <- subset(df_conditions_i25_4, !grepl("A$", diag_sicherheit))
df_conditions_i25_4 <- df_conditions_i25_4[!duplicated(df_conditions_i25_4$patient_id), ]
#df_conditions_i25_4 <- df_conditions_i25_4[df_conditions_i25_4$age < "20", ]
df_conditions_i25_4

df_pims <- base::merge(df_conditions_patients, df_conditions_a48_3, by = "patient_id")
df_pims <- base::merge(df_pims, df_conditions_d76, by = "patient_id")
df_pims <- base::merge(df_pims, df_conditions_m30_3, by = "patient_id")
df_pims <- base::merge(df_pims, df_conditions_d89_8_9, by = "patient_id")
df_pims <- base::merge(df_pims, df_conditions_r57_8, by = "patient_id")
df_pims <- base::merge(df_pims, df_conditions_r65, by = "patient_id")

df_pims <- rbind(df_conditions_a48_3,df_conditions_d76,df_conditions_d89_8_9,df_conditions_i25_4,df_conditions_r57_8,df_conditions_r65,df_conditions_u10_9,df_conditions_m30_3)

#----------------
#new
result_primaer_count <- ifelse(length(unique(df_pims$patient_id)) <= 5, "<5", length(unique(df_pims$patient_id)))

rare_icd10codes_list <- as.list(strsplit(rare_icd10codes, ',')[[1]])
komorb_icd10codes_list <- as.list(strsplit(komorb_icd10codes, ",")[[1]])
con_icd10codes_list <- as.list(strsplit(con_icd10codes, ",")[[1]])

rare_icd10codes_list <- sub("%20", " ", rare_icd10codes_list)
rare_icd10codes_list <- sub("%21", "!", rare_icd10codes_list)
komorb_icd10codes_list <- sub("%21", "!", komorb_icd10codes_list)

con_icd10codes_list <- sub("%20", " ", con_icd10codes_list)
con_icd10codes_list <- sub("%21", "!", con_icd10codes_list)

# create table with all possible comorbidities for 0-count in result df
df_con_icd10codes_combined <- data.frame()
for ( a in sort(unique(df_pims$recorded_year))){
  for ( i in sort(con_icd10codes_list)){
    for ( ag in as.character(sort(unique(df_pims$age_group_0_20_99)))){
      row <- c(conf$hospital_name,a,i,ag,as.integer(0))
      df_con_icd10codes_combined <- rbind(df_con_icd10codes_combined, row)
    }
  }
}
colnames(df_con_icd10codes_combined) <- c("Klinikum", "Jahr", "Diagn", "Alter", "Anzahl")
df_con_icd10codes_combined$Anzahl <- as.integer(df_con_icd10codes_combined$Anzahl)

df_result_primaer_final <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = df_pims$recorded_year, Diagn = df_pims$diagnosis, Alter = as.character(df_pims$age_group_0_20_99)) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer_final_lt20 <- df_result_primaer_final[df_result_primaer_final$Alter == "[0,20a]", ]
df_result_primaer_final_gt20 <- df_result_primaer_final[df_result_primaer_final$Alter != "[0,20a]", ]

df_result_primaer_final_lt20
df_result_primaer_final_gt20

# create final df with comorbidities ans 0-count
df_result_primaer_final <- rbind(df_result_primaer_final,df_con_icd10codes_combined)
dupes <- df_result_primaer_final[duplicated(df_result_primaer_final)]
dupes <- group_by(df_result_primaer_final, Klinikum, Jahr, Diagn, Alter) %>% filter(n() > 1)
df_result_primaer_final2 <- distinct(df_result_primaer_final, Klinikum, Jahr, Diagn, Alter, .keep_all= TRUE)
dupes2 <- group_by(df_result_primaer_final2, Klinikum, Jahr, Diagn, Alter) %>% filter(n() > 1)

df_result_primaer_final

df_result_primaer <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = df_pims$recorded_year, Diagn = df_pims$diagnosis, Geschlecht = df_pims$gender, Alter = df_pims$age_group) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer
df_result_primaer2 <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = df_pims$recorded_year, Geschlecht = df_pims$gender) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer2
df_result_primaer3 <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = df_pims$recorded_year, Diagn = df_pims$diagnosis) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer3
df_result_primaer4 <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = df_pims$recorded_year, Alter = df_pims$age_group) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer4
df_result_primaer5 <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Jahr = df_pims$recorded_year) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer5
df_result_primaer6 <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Alter = df_pims$age_group) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer6
df_result_primaer7 <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Geschlecht = df_pims$gender) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer7
df_result_primaer8 <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Diagn = df_pims$diagnosis, Geschlecht = df_pims$gender) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer8
df_result_primaer9 <- as.data.frame(df_pims %>% group_by(Klinikum = df_pims$hospital_id, Diagn = df_pims$diagnosis) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer9
#df_result_primaer <- mutate(df_result_primaer, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))




df_pims <- df_pims[df_pims$age < "20", ]
df_pims
#----------------


result_primaer_count <- ifelse(length(df_conditions_patients$patient_id) <= 5, "<5", length(df_conditions_patients$patient_id))

df_result_primaer_count <- as.data.frame(df_cf_birth_all %>% group_by(Einrichtungsindikator = df_cf_birth_all$hospital_id.x, Diagn1 = df_cf_birth_all$diagnosis.x, Diagn2 = "O80 etc.") %>% summarise(Anzahl = n()) )
df_result_primaer_count <- mutate(df_result_primaer_count, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

df_result_primaer <- as.data.frame(df_conditions_patients %>% group_by(Einrichtungsindikator = df_conditions_patients$hospital_id, Year = df_conditions_patients$recorded_year, Diagn2 = df_conditions_patients$diagnosis, Geschlecht = df_conditions_patients$gender, Alter = df_conditions_patients$age_group) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer
df_result_primaer2 <- as.data.frame(df_conditions_patients %>% group_by(Einrichtungsindikator = df_conditions_patients$hospital_id, Year = df_conditions_patients$recorded_year, Geschlecht = df_conditions_patients$gender) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer2
df_result_primaer3 <- as.data.frame(df_conditions_patients %>% group_by(Einrichtungsindikator = df_conditions_patients$hospital_id, Year = df_conditions_patients$recorded_year, Diagn2 = df_conditions_patients$diagnosis) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer3
df_result_primaer4 <- as.data.frame(df_conditions_patients %>% group_by(Einrichtungsindikator = df_conditions_patients$hospital_id, Year = df_conditions_patients$recorded_year, Alter = df_conditions_patients$age_group) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer4
df_result_primaer5 <- as.data.frame(df_conditions_patients %>% group_by(Einrichtungsindikator = df_conditions_patients$hospital_id, Year = df_conditions_patients$recorded_year) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer5
df_result_primaer6 <- as.data.frame(df_conditions_patients %>% group_by(Einrichtungsindikator = df_conditions_patients$hospital_id, Alter = df_conditions_patients$age_group) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer6
df_result_primaer7 <- as.data.frame(df_conditions_patients %>% group_by(Einrichtungsindikator = df_conditions_patients$hospital_id, Geschlecht = df_conditions_patients$gender) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer7
df_result_primaer8 <- as.data.frame(df_conditions_patients %>% group_by(Einrichtungsindikator = df_conditions_patients$hospital_id, Diagn2 = df_conditions_patients$diagnosis) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer8
#df_result_primaer <- mutate(df_result_primaer, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))



#Sekundäre Fragestellungen:
#[A] Wie häufig wird das Kawasaki-Syndrom bzw. PIMS in Kombination mit einem positiven COVID-19 Befund dokumentiert?
#Es sollen die jeweiligen Häufigkeiten der Diagnosekodierung 
#M30.3 und D76.1-4, A48.3, R57.8, R65.0-9, D89.8/9 und einer 
#Diagnosekodierung U07.1, U07.2, U10.9 oder Hinweis auf COVID-19 (Tabelle 6) erfasst werden.

# get comorbidities
df_conditions_u07_1 <- subset(df_conditions_patients, grepl("^U07.1", diagnosis))
df_m30_u07_1 <- base::merge(df_conditions_u07_1, df_conditions_m30_3, by = "patient_id")
df_m30_u07_1 <- df_m30_u07_1[!duplicated(df_m30_u07_1$patient_id), ]
df_m30_u07_1 <- df_m30_u07_1 %>% select(-contains("resource_identifier"))

df_conditions_u07_2 <- subset(df_conditions_patients, grepl("^U07.2", diagnosis))
df_m30_u07_2 <- base::merge(df_conditions_u07_2, df_conditions_m30_3, by = "patient_id")
df_m30_u07_2 <- df_m30_u07_2[!duplicated(df_m30_u07_2$patient_id), ]
df_m30_u07_2 <- df_m30_u07_2 %>% select(-contains("resource_identifier"))

df_conditions_u10_9 <- subset(df_conditions_patients, grepl("^U10.9", diagnosis))
df_m30_u10_9 <- base::merge(df_conditions_u10_9, df_conditions_m30_3, by = "patient_id")
df_m30_u10_9 <- df_m30_u10_9[!duplicated(df_m30_u10_9$patient_id), ]
df_m30_u10_9 <- df_m30_u10_9 %>% select(-contains("resource_identifier"))




df_result_sekundaer_a <- as.data.frame(df_cf_birth %>% group_by(Klinikum = df_cf_birth$hospital_id, Diagn1 = df_cf_birth$diagnosis, Diagn2 = df_cf_birth$diagnosis, Geschlecht = df_cf_birth$gender, Alter = df_cf_birth$age_group) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
#df_result_sekundaer_a <- mutate(df_result_sekundaer_a, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

df_conditions_complication <- subset(df_conditions_patients, grepl("^O64|^O75|^O24", diagnosis))

df_cf_complication <- base::merge(df_conditions_cf, df_conditions_birth, by = "patient_id")
df_cf_complication <- base::merge(df_cf_complication, df_conditions_complication, by = "patient_id")
df_cf_complication <- df_cf_complication[!duplicated(df_cf_complication$patient_id), ]
df_cf_complication <- df_cf_complication[df_cf_complication$age.x > 14, ]
df_cf_complication <- df_cf_complication %>% select(-contains("resource_identifier"))

df_result_sekundaer_b <- as.data.frame(df_cf_complication %>% group_by(Klinikum = df_cf_complication$hospital_id.x, Diagn1 = df_cf_complication$diagnosis.x, Diagn2 = df_cf_complication$diagnosis, Geschlecht = df_cf_complication$gender, Alter = df_cf_complication$age_group) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
#df_result_sekundaer_b <- mutate(df_result_sekundaer_b, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

# display the final output
df_result_primaer
df_result_sekundaer_a
df_result_sekundaer_b

########################################################################################################################################################
# write result to a csv file
########################################################################################################################################################
write.csv(df_result_primaer, file = "result_primaer.csv", row.names = FALSE)
write.csv(df_result_sekundaer_a, file = "result_sekundaer_a.csv", row.names = FALSE)
write.csv(df_result_sekundaer_b, file = "result_sekundaer_b.csv", row.names = FALSE)
########################################################################################################################################################
end_time <- Sys.time()
print(end_time - start_time)