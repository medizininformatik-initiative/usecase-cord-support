####################################################################################################################
# To calculate the aggregate of patients corresponding to
# Phenylketonurie
#####################################################################################################################
start_time <- Sys.time()
options(warn = -1)# to suppress warnings
if (!require("fhircrackr")) install.packages("fhircrackr")
if (!require("config")) install.packages("config")
if (!require("dplyr")) install.packages("dplyr")

conf <- config::get(file = paste(getwd(), "/conf.yml", sep = ""))

#check for proxy configuration
if (exists("http_proxy", where = conf)) {
  if (nchar(conf$http_proxy) >= 1) {
    Sys.setenv(http_proxy = conf$http_proxy)
  }
}

if (exists("https_proxy", where = conf)) {
  if (nchar(conf$https_proxy) >= 1) {
    Sys.setenv(https_proxy = conf$https_proxy)
  }
}

if (exists("count", where = conf)) {
  if (nchar(conf$no_proxy) >= 1) {
    Sys.setenv(no_proxy = conf$no_proxy)
  }
}

# check for custom recordedDate
if (exists("recordedDate_col", where = conf)) {
  if (nchar(conf$recordedDate_col) >= 1) {
    recorded_date_custom <- conf$recordedDate_col
  } else {
    recorded_date_custom <- "recordedDate"
  }
  search_date <- paste0("&", strsplit(recorded_date_custom, "Date")[[1]][1],  "-date=gt2014-12-31")
} else {
  recorded_date_custom <- "recordedDate"
  search_date <- paste0("&", strsplit(recorded_date_custom, "Date")[[1]][1],  "-date=gt2014-12-31")
}

# check for custom subject_reference_prefix
if (exists("subject_reference_prefix", where = conf)) {
  if (nchar(conf$subject_reference_prefix) >= 1) {
    subject_reference_prefix <- conf$subject_reference_prefix
  } else {
    subject_reference_prefix <- "Patient/"
  }
} else {
  subject_reference_prefix <- "Patient/"
}

# check for custom icd_code_system
if (exists("icd_code_system", where = conf)) {
  if (nchar(conf$icd_code_system) >= 1) {
    icd_code_system_custom <- conf$icd_code_system
  } else {
    icd_code_system_custom <- "http://fhir.de/CodeSystem/dimdi/icd-10-gm"
  }
} else {
  icd_code_system_custom <- "http://fhir.de/CodeSystem/dimdi/icd-10-gm"
}

if (exists("ssl_verify_peer", where = conf)) {
  if (!(conf$ssl_verify_peer)) {
    httr::set_config(httr::config(ssl_verifypeer = 0L))
  }
}

if (exists("max_bundles", where = conf)) {
  if (nchar(conf$max_bundles) >= 1) {
    max_bundles_custom <- conf$max_bundles
  } else {
    max_bundles_custom <- 0
  }
} else {
  max_bundles_custom <- 0
}

if (exists("count", where = conf)) {
  if (nchar(conf$count) >= 1) {
    count_custom <- paste0("&_count=", conf$count)
  } else {
    count_custom <- ""
  }
} else {
  count_custom <- ""
}

search_request <- paste0(
  conf$serverbase,
  "Condition?",
  "code=",
  "E70.0,E70.1",
  ",F32.0,F32.1,F32.2,F32.3,F32.8,F32.9",
  ",F33.0,F33.1,F33.2,F33.3,F33.4,F33.8,F33.9",
  ",F34.0,F34.1,F34.8,F34.9",
  ",G31.0,G31.9",
  ",N18.1,N18.2,N18.3,N18.4,N18.5",
  ",O09.0%21,O09.1%21,O09.2%21,O09.3%21,O09.4%21,O09.5%21,O09.6%21,O09.7%21,O09.9%21",
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
  ",J18.0,J18.1,J18.2,J18.8,J18.9",
  ",Z38.0,Z38.1,Z38.2,Z38.3,Z38.4,Z38.5,Z38.6,Z38.7,Z38.8",
  search_date,
  count_custom,
  "&_include=Condition:subject:Patient"
  )

if (exists("token", where = conf)) {
  if (nchar(conf$token) >= 1) {
    condition_patient_bundle <- fhir_search(request = search_request, username = conf$user, password = conf$password, token = conf$token, verbose = 2, max_bundles = max_bundles_custom)
    } else {
    condition_patient_bundle <- fhir_search(request = search_request, username = conf$user, password = conf$password, verbose = 2, max_bundles = max_bundles_custom)
    }
  } else {
    if (exists("username", where = conf)) {
      condition_patient_bundle <- fhir_search(request = search_request, username = conf$user, password = conf$password, verbose = 2, max_bundles = max_bundles_custom)
    } else {
      condition_patient_bundle <- fhir_search(request = search_request, verbose = 2, max_bundles = max_bundles_custom)
    }
}

conditions <- fhir_table_description(resource = "Condition",
                                     cols = c(diagnosis = "code/coding/code",
                                              display = "code/coding/display",
                                              system = "code/coding/system",
                                              recorded_date = recorded_date_custom,
                                              patient_id = "subject/reference"
                                              )
)

patients <- fhir_table_description(resource = "Patient",
                                   cols = c(patient_id = "id",
                                            hospital_id = "meta/source",
                                            gender = "gender",
                                            birthdate = "birthDate",
                                            patient_zip = "address/postalCode",
                                            countrycode = "address/country"
                                            )
)

design <- fhir_design(conditions, patients)

# flatten the XML object bundles from patients and conditions to a list
if (packageVersion("fhircrackr") >= 2) {
  list_cdn <- fhir_crack(condition_patient_bundle, design, sep = "|", brackets = c("[", "]"), verbose = 2, ncores = 1)
} else {
  list_cdn <- fhir_crack(condition_patient_bundle, design, sep = "|", brackets = c("[", "]"), verbose = 2)
}

# save conditions and patients in separate dataframes
df_conditions_raw <- list_cdn$conditions
df_patients_raw <- list_cdn$patients

# unnest raw conditions dataframe columns diagnosis, system
df_conditions_tmp <- fhir_melt(df_conditions_raw,
                               columns = c("diagnosis", "display", "system"),
                               brackets = c("[", "]"), sep = "|", all_columns = TRUE)

# unnest raw conditions dataframe columns diagnosis, system
df_conditions_tmp <- fhir_melt(df_conditions_tmp,
                               columns = c("diagnosis", "display", "system"),
                               brackets = c("[", "]"), sep = "|", all_columns = TRUE)

df_conditions_tmp <- fhir_rm_indices(df_conditions_tmp, brackets = c("[", "]"))

# filter conditions by system to obtain only icd-10-gm system
df_conditions_tmp <- df_conditions_tmp[df_conditions_tmp$system == icd_code_system_custom, ]

# remove the "Patient/" tag from column patient_id in condition resource
df_conditions_tmp$patient_id <- sub(subject_reference_prefix, "", df_conditions_tmp[, "patient_id"])

df_patients_tmp <- fhir_melt(df_patients_raw,
                             columns = c("patient_zip", "countrycode"),
                             brackets = c("[", "]"), sep = "|", all_columns = TRUE)

df_patients_tmp <- fhir_rm_indices(df_patients_tmp, brackets = c("[", "]"))

# remove all male patients (maybe remove for male children)
#df_patients_tmp <- df_patients_tmp[df_patients_tmp$gender != "male", ]

# remove duplicate entries
df_patients_tmp <- df_patients_tmp[!duplicated(df_patients_tmp$patient_id), ]

x <- c(1, 17, 31, 99)

# merge conditions and patients dataframe
df_conditions_patients <- base::merge(df_conditions_tmp, df_patients_tmp, by = "patient_id")

df_conditions_patients$recorded_date <- as.Date(df_conditions_patients$recorded_date, format = "%Y-%m-%d")
df_conditions_patients <- df_conditions_patients[df_conditions_patients$recorded_date > "2014-12-31", ]
df_conditions_patients <- df_conditions_patients[df_conditions_patients$recorded_date < "2022-12-31", ]

# check for custom hospital_id
if (exists("hospital_name", where = conf)) {
  if (nchar(conf$hospital_name) >= 1) {
    df_conditions_patients$hospital_id <- conf$hospital_name
  }
}

# remove merge identifier column as its not needed and could cause problems
df_conditions_patients <- df_conditions_patients %>% select(-contains("resource_identifier"))

# check if birthdate is in format YYYY-MM-DD, if not append -01-01
df_conditions_patients <- mutate(df_conditions_patients, birthdate = ifelse(nchar(df_conditions_patients$birthdate) >= 10, df_conditions_patients$birthdate, paste0(df_conditions_patients$birthdate, "-01-01")))

# calculate age as of recorded_date - birthdate
df_conditions_patients$age <- round(as.double(as.Date(df_conditions_patients$recorded_date) - as.Date(df_conditions_patients$birthdate)) / 365.25, 0)

# set age groups
df_conditions_patients$age_group <- cut(df_conditions_patients$age, x, breaks = c(0, 17, 30, 99), labels = c("[0,17]", "[18,30]", "[31,99]"))

# filter conditions for ICD-Code E70*
df_conditions_pku <- subset(df_conditions_patients, grepl("^E70", diagnosis))
#df_conditions_pku <- unique(df_conditions_pku[, c(1, 2, 3, 4, 5)])

df_conditions_pku_0 <- subset(df_conditions_pku, grepl("^E70.0", diagnosis))

df_conditions_pku_1 <- subset(df_conditions_pku, grepl("^E70.1", diagnosis))

df_conditions_n18 <- subset(df_conditions_patients, grepl("^N18", diagnosis))

df_pku_0_n <- base::merge(df_conditions_pku_0, df_conditions_n18, by = "patient_id")
df_pku_0_n <- df_pku_0_n[!duplicated(df_pku_0_n$patient_id), ]
df_pku_0_n <- df_pku_0_n %>% select(-contains("resource_identifier"))

df_pku_1_n <- base::merge(df_conditions_pku_1, df_conditions_n18, by = "patient_id")
df_pku_1_n <- df_pku_1_n[!duplicated(df_pku_1_n$patient_id), ]
df_pku_1_n <- df_pku_1_n %>% select(-contains("resource_identifier"))

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

df_pku_result_primaer <- rbind(df_pku_0_n, df_pku_1_n, df_pku_0_f32, df_pku_1_f32, df_pku_0_f33, df_pku_1_f33, df_pku_0_f34, df_pku_1_f34, df_pku_0_g31, df_pku_1_g31)
df_result_primaer <- as.data.frame(df_pku_result_primaer %>% group_by(Einrichtungsindikator = df_pku_result_primaer$hospital_id.x, Diagn1 = df_pku_result_primaer$diagnosis.x, Diagn2 = df_pku_result_primaer$diagnosis.y, Geschlecht = df_pku_result_primaer$gender.x, Alter = df_pku_result_primaer$age_group.x) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
#df_result_primaer <- mutate(df_result_primaer, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

if (nrow(df_pku_result_primaer) == 0) {
  result_sekundaer_a <- 0
} else {
  result_sekundaer_a <- round(sum(df_result_primaer$Anzahl) / nrow(df_conditions_pku[!duplicated(as.numeric(df_conditions_pku$patient_id)), ]) * 100, 2)
}

df_conditions_birth_all <- subset(df_conditions_patients, grepl("^O|^Z", diagnosis))

df_conditions_birth <- subset(df_conditions_patients, grepl("^O09|^O3|^O63|^O8|^Z", diagnosis))

df_pku_birth <- base::merge(df_conditions_pku, df_conditions_birth, by = "patient_id")
df_pku_birth <- df_pku_birth[!duplicated(df_pku_birth$patient_id), ]
df_pku_birth <- subset(df_pku_birth, !grepl("^Z38", diagnosis.y))
df_pku_birth <- df_pku_birth %>% select(-contains("resource_identifier"))

df_conditions_complication <- subset(df_conditions_patients, grepl("^O64|^O75|^O24", diagnosis))

df_pku_complication <- base::merge(df_conditions_pku, df_conditions_birth, by = "patient_id")
df_pku_complication <- base::merge(df_pku_complication, df_conditions_complication, by = "patient_id")
df_pku_complication <- df_pku_complication[!duplicated(df_pku_complication$patient_id), ]
df_pku_complication <- subset(df_pku_complication, !grepl("^Z38", diagnosis.y))
df_pku_complication <- df_pku_complication %>% select(-contains("resource_identifier"))

df_result_sekundaer_c <- as.data.frame(df_pku_complication %>% group_by(Einrichtungsindikator = df_pku_complication$hospital_id.x, Diagn1 = df_pku_complication$diagnosis.x, Diagn2 = df_pku_complication$diagnosis, Geschlecht = df_pku_complication$gender.x, Alter = df_pku_complication$age_group.x) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
#df_result_sekundaer_c <- mutate(df_result_sekundaer_c, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

# display the final output
df_result_primaer
paste0(result_sekundaer_a, "% aller PKU Patient:innen haben internistische, neurologische und psychiatrische Komorbiditäten.")
df_result_sekundaer_c

########################################################################################################################################################
# write result to a csv file
########################################################################################################################################################
write.csv(df_result_primaer, file = "result_primaer.csv", row.names = FALSE)
write.csv(result_sekundaer_a, file = "result_sekundaer_a.csv", row.names = FALSE)
write.csv(df_result_primaer, file = "result_sekundaer_b.csv", row.names = FALSE)
write.csv(df_result_sekundaer_c, file = "result_sekundaer_b.csv", row.names = FALSE)
########################################################################################################################################################