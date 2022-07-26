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
if (nchar(conf$http_proxy) >= 1) {
  Sys.setenv(http_proxy = conf$http_proxy)
}
if (nchar(conf$https_proxy) >= 1) {
  Sys.setenv(https_proxy = conf$https_proxy)
}
if (nchar(conf$no_proxy) >= 1) {
  Sys.setenv(no_proxy = conf$no_proxy)
}

# check for custom recordedDate
if (nchar(conf$recordedDate_col) >= 1) {
  recorded_date_custom <- conf$recordedDate_col
} else {
  recorded_date_custom <- "recordedDate"
}

# check for custom icd_code_system
if (nchar(conf$icd_code_system) >= 1) {
  icd_code_system_custom <- conf$icd_code_system
} else {
  icd_code_system_custom <- "http://fhir.de/CodeSystem/dimdi/icd-10-gm"
}

if (!(conf$ssl_verify_peer)) {
  httr::set_config(httr::config(ssl_verifypeer = 0L))
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
  "&_include=Condition:subject:Patient")

condition_patient_bundle <- fhir_search(request = search_request, username = conf$user, password = conf$password, verbose = 2, max_bundles = 0)

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
                               columns = c("diagnosis", "display", "system", "patient_id"),
                               brackets = c("[", "]"), sep = "|", all_columns = TRUE)

df_conditions_tmp <- fhir_rm_indices(df_conditions_tmp, brackets = c("[", "]"))

# remove the "Patient/" tag from column patient_id in condition resource
df_conditions_tmp$patient_id <- sub("Patient/", "", df_conditions_tmp[, "patient_id"])

df_patients_tmp <- fhir_melt(df_patients_raw,
                             columns = c("patient_zip", "countrycode"),
                             brackets = c("[", "]"), sep = "|", all_columns = TRUE)

df_patients_tmp <- fhir_rm_indices(df_patients_tmp, brackets = c("[", "]"))

# remove all male patients (maybe remove for male children)
#df_patients_tmp <- df_patients_tmp[df_patients_tmp$gender != "male",]

# remove duplicate entries
df_patients_tmp <- df_patients_tmp[!duplicated(df_patients_tmp$patient_id), ]

x <- c(1, 17, 31, 99)

# merge conditions and patients dataframe
df_conditions_patients <- base::merge(df_conditions_tmp, df_patients_tmp, by = "patient_id")

# remove merge identifier column as its not needed and could cause problems
df_conditions_patients <- df_conditions_patients %>% select(-contains("resource_identifier"))

# calculate age as of recorded_date - birthdate
df_conditions_patients$age <- round(as.double(as.Date(df_conditions_patients$recorded_date) - as.Date(df_conditions_patients$birthdate)) / 365.25, 0)

# set age groups
df_conditions_patients$age_group <- cut(df_conditions_patients$age, x, breaks = c(0, 17, 30, 99), labels = c("[0,17]", "[18,30]", "[31,99]"))

# filter conditions for ICD-Code E70*
df_conditions_pku <- subset(df_conditions_patients, grepl("^E70", diagnosis))
df_conditions_pku <- unique(df_conditions_pku[, c(1, 2, 3, 4, 5)])

#----
#df_conditions_pku <- base::merge(df_conditions_pku, df_patients_tmp, by = "patient_id")
#df_conditions_pku$age <- round(as.double(as.Date(df_conditions_pku$recorded_date) - as.Date(df_conditions_pku$birthdate)) / 365.25, 0)
#df_conditions_pku$age_group <- cut(df_conditions_pku$age, x, breaks = c(0, 17, 30, 99), labels = c("[0,17]", "[18,30]", "[31,99]"))

#df_conditions_pku <- df_conditions_pku[!duplicated(df_conditions_pku$patient_id),]
#df_conditions_pku1 <- base::merge(df_conditions_pku, df_patients_tmp, by = "patient_id")
#df_conditions_pku1$age <- round( as.double( as.Date( df_conditions_pku1$recorded_date ) - as.Date( df_conditions_pku1$birthdate ) ) / 365.25, 0 )

#df_conditions_pku <- unique(df_conditions_pku[, c(1,2,3,4,5)])
#df_b <- base::merge(df_conditions_pku, df_a, by = "patient_id")
#df_b <- df_b %>% select(-contains(".y"))
#----

df_conditions_pku_0 <- subset(df_conditions_pku, grepl("^E70.0", diagnosis))
#df_conditions_pku_0$recorded_date <- as.Date(df_conditions_pku_0$recorded_date, format= "%Y-%m-%d")
#df_conditions_pku_0 <- df_conditions_pku_0[df_conditions_pku_0$recorded_date < "2019-12-31",]

df_conditions_pku_1 <- subset(df_conditions_pku, grepl("^E70.1", diagnosis))
#df_conditions_pku_1$recorded_date <- as.Date(df_conditions_pku_1$recorded_date, format= "%Y-%m-%d")
#df_conditions_pku_1 <- df_conditions_pku_1[df_conditions_pku_1$recorded_date < "2019-12-31",]

df_conditions_n <- subset(df_conditions_patients, grepl("^N18", diagnosis))
#df_conditions_n$recorded_date <- as.Date(df_conditions_n$recorded_date, format= "%Y-%m-%d")
#df_conditions_n <- df_conditions_n[df_conditions_n$recorded_date < "2019-12-31",]

df_conditions_birth_all <- subset(df_conditions_patients, grepl("^O|^Z", diagnosis))
#df_conditions_birth_all$recorded_date <- as.Date(df_conditions_birth_all$recorded_date, format= "%Y-%m-%d")
#df_conditions_birth_all <- df_conditions_birth_all[df_conditions_birth_all$recorded_date < "2019-12-31",]

df_pku_0_N <- base::merge(df_conditions_pku_0, df_conditions_n, by = "patient_id")
#df_pku_0_N <- base::merge(df_pku_0_N, df_patients_tmp, by.x = "patient_id",by.y = "patient_id")
#df_pku_0_N <- df_pku_0_N[!duplicated(df_pku_0_N$patient_id),]
#df_pku_0_N$age <- round( as.double( as.Date( df_pku_0_N$recorded_date.y ) - as.Date( df_pku_0_N$birthdate ) ) / 365.25, 0 )
#df_pku_0_N$age_group <- cut(df_pku_0_N$age,x,breaks= c(0,17,30,99), labels = c("[0,17]","[18,30]","[31,99]"))
df_pku_0_N <- df_pku_0_N %>% select(-contains("resource_identifier"))

df_pku_1_N <- base::merge(df_conditions_pku_1, df_conditions_n, by = "patient_id")
#df_pku_1_N <- base::merge(df_pku_1_N, df_patients_tmp, by.x = "patient_id",by.y = "patient_id")
df_pku_1_N <- df_pku_1_N[!duplicated(df_pku_1_N$patient_id), ]
#df_pku_1_N$age <- round( as.double( as.Date( df_pku_1_N$recorded_date.y ) - as.Date( df_pku_1_N$birthdate ) ) / 365.25, 0 )
#df_pku_1_N$age_group <- cut(df_pku_1_N$age,x,breaks= c(0,17,30,99), labels = c("[0,17]","[18,30]","[31,99]"))
df_pku_1_N <- df_pku_1_N %>% select(-contains("resource_identifier"))

df_pku_N <- rbind(df_pku_0_N, df_pku_1_N)
df_result_primaer <- as.data.frame(df_pku_N %>% group_by(Einrichtungsindikator = df_pku_N$hospital_id, Diagn1 = df_pku_N$diagnosis.x, Diagn2 = df_pku_N$diagnosis.y, Geschlecht = df_pku_N$gender, Alter = df_pku_N$age_group) %>% summarise(Anzahl = n()) %>% mutate(Haeufigkeit = paste0(round(100 * Anzahl / sum(Anzahl), 0), "%")))


if (nrow(df_pku_N) == 0) {
  result_sekundaer_a <- 0
} else {
  result_sekundaer_a <- round(nrow(df_pku_N) / nrow(df_conditions_pku) * 100)
}

df_conditions_birth <- subset(df_conditions_patients, grepl("^O09|^O3|^O63|^O8|^Z", diagnosis))

df_pku_birth <- base::merge(df_conditions_pku, df_conditions_birth, by = "patient_id")
#df_pku_birth <- base::merge(df_pku_birth, df_patients_tmp, by.x = "patient_id",by.y = "patient_id")
df_pku_birth <- df_pku_birth[!duplicated(df_pku_birth$patient_id), ]
#df_pku_birth$age <- round( as.double( as.Date( df_pku_birth$recorded_date.y ) - as.Date( df_pku_birth$birthdate ) ) / 365.25, 0 )
#df_pku_birth$age_group <- cut(df_pku_birth$age,x,breaks= c(0,17,30,99), labels = c("[0,17]","[18,30]","[31,99]"))
df_pku_birth <- df_pku_birth[df_pku_birth$age > 14, ]
df_pku_birth <- df_pku_birth %>% select(-contains("resource_identifier"))

#df_result_sekundaer_c <- as.data.frame(df_pku_birth%>%group_by(Einrichtungsindikator=df_pku_birth$hospital_id,Diagn1=df_pku_birth$diagnosis.x,Diagn2=df_pku_birth$diagnosis.y,Geschlecht=df_pku_birth$gender,Alter=df_pku_birth$age_group)%>%summarise(Anzahl=n()))

df_conditions_complication <- subset(df_conditions_patients, grepl("^O64|^O75|^O24", diagnosis))

df_pku_complication <- base::merge(df_conditions_pku, df_conditions_birth, by = "patient_id")
df_pku_complication <- base::merge(df_pku_complication, df_conditions_complication, by = "patient_id")
#df_pku_complication <- base::merge(df_pku_complication, df_patients_tmp, by.x = "patient_id",by.y = "patient_id")
df_pku_complication <- df_pku_complication[!duplicated(df_pku_complication$patient_id), ]
#df_pku_complication$age <- round( as.double( as.Date( df_pku_complication$recorded_date.y ) - as.Date( df_pku_complication$birthdate ) ) / 365.25, 0 )
#df_pku_complication$age_group <- cut(df_pku_complication$age,x,breaks= c(0,17,30,99), labels = c("[0,17]","[18,30]","[31,99]"))
#df_pku_complication <- df_pku_complication[df_pku_complication$age > 14,]
df_pku_complication <- df_pku_complication %>% select(-contains("resource_identifier"))

df_result_sekundaer_c <- as.data.frame(df_pku_complication %>% group_by(Einrichtungsindikator = df_pku_complication$hospital_id.x, Diagn1 = df_pku_complication$diagnosis.x, Diagn2 = df_pku_complication$diagnosis, Geschlecht = df_pku_complication$gender.x, Alter = df_pku_complication$age_group.x) %>% summarise(Anzahl = n()))

# display the final output
df_result_primaer
paste0(result_sekundaer_a, "%")
df_result_sekundaer_c
########################################################################################################################################################
# write result to a csv file
########################################################################################################################################################
write.csv(df_result_primaer, file = "result_primaer.csv", row.names = FALSE)
write.csv(result_sekundaer_a, file = "result_sekundaer_a.csv", row.names = FALSE)
write.csv(df_result_sekundaer_b, file = "result_sekundaer_b.csv", row.names = FALSE)
write.csv(df_result_sekundaer_c, file = "result_sekundaer_b.csv", row.names = FALSE)
########################################################################################################################################################