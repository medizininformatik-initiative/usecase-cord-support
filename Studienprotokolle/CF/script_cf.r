####################################################################################################################
# To calculate the aggregate of patients corresponding to
# Mukoviszidose/CF Cystic Fibrosis and Birth
#####################################################################################################################
options(warn=-1)# to suppress warnings
if (!require('fhircrackr')) install.packages('fhircrackr')# to flatten the FHIR resources from XML objects; requires R (>= 4.0.0)
if (!require('config')) install.packages('config')
if (!require('dplyr')) install.packages('dplyr')# to flatten the FHIR resources from XML objects; requires R (>= 4.0.0)
#if (!require('tibble')) install.packages('tibble')
#if (!require('tidyr')) install.packages('tidyr')
#if (!require('stringr')) install.packages('stringr')

conf <- config::get(file = paste(getwd(),"/conf.yml",sep=""))
#check for proxy configuration
if (nchar(conf$http_proxy) >= 1) {
  Sys.setenv(http_proxy  = conf$http_proxy)
}
if (nchar(conf$https_proxy) >= 1) {
  Sys.setenv(https_proxy  = conf$https_proxy)
}
if (nchar(conf$no_proxy) >= 1) {
  Sys.setenv(no_proxy  = conf$no_proxy)
}

# check for custom recordedDate
if (nchar(conf$recordedDate_col) >=1) {
  recorded_date_custom = conf$recordedDate_col
} else {
  recorded_date_custom = "recordedDate"
}

# check for custom icd_code_system
if (nchar(conf$icd_code_system) >=1) {
  icd_code_system_custom = conf$icd_code_system
} else {
  icd_code_system_custom = "http://fhir.de/CodeSystem/dimdi/icd-10-gm"
}

if(!(conf$ssl_verify_peer)){
  httr::set_config(httr::config(ssl_verifypeer = 0L))
}

search_request <- paste0(
  conf$serverbase,
  'Condition?',
  'code=',
  'O09.0%21,O09.1%21,O09.2%21,O09.3%21,O09.4%21,O09.5%21,O09.6%21,O09.7%21,O09.9%21',
  ',O09.0%20Z37.0%21,O09.0%20Z37.1%21,O09.0%20Z37.2%21,O09.0%20Z37.3%21,O09.0%20Z37.4%21,O09.0%20Z37.5%21,O09.0%20Z37.6%21,O09.0%20Z37.7%21,O09.0%20Z37.9%21',
  ',O09.1%20Z37.0%21,O09.1%20Z37.1%21,O09.1%20Z37.2%21,O09.1%20Z37.3%21,O09.1%20Z37.4%21,O09.1%20Z37.5%21,O09.1%20Z37.6%21,O09.1%20Z37.7%21,O09.1%20Z37.9%21',
  ',O09.2%20Z37.0%21,O09.2%20Z37.1%21,O09.2%20Z37.2%21,O09.2%20Z37.3%21,O09.2%20Z37.4%21,O09.2%20Z37.5%21,O09.2%20Z37.6%21,O09.2%20Z37.7%21,O09.2%20Z37.9%21',
  ',O09.3%20Z37.0%21,O09.3%20Z37.1%21,O09.3%20Z37.2%21,O09.3%20Z37.3%21,O09.3%20Z37.4%21,O09.3%20Z37.5%21,O09.3%20Z37.6%21,O09.3%20Z37.7%21,O09.3%20Z37.9%21',
  ',O09.4%20Z37.0%21,O09.4%20Z37.1%21,O09.4%20Z37.2%21,O09.4%20Z37.3%21,O09.4%20Z37.4%21,O09.4%20Z37.5%21,O09.4%20Z37.6%21,O09.4%20Z37.7%21,O09.4%20Z37.9%21',
  ',O09.5%20Z37.0%21,O09.5%20Z37.1%21,O09.5%20Z37.2%21,O09.5%20Z37.3%21,O09.5%20Z37.4%21,O09.5%20Z37.5%21,O09.5%20Z37.6%21,O09.5%20Z37.7%21,O09.5%20Z37.9%21',
  ',O09.6%20Z37.0%21,O09.6%20Z37.1%21,O09.6%20Z37.2%21,O09.6%20Z37.3%21,O09.6%20Z37.4%21,O09.6%20Z37.5%21,O09.6%20Z37.6%21,O09.6%20Z37.7%21,O09.6%20Z37.9%21',
  ',O09.7%20Z37.0%21,O09.7%20Z37.1%21,O09.7%20Z37.2%21,O09.7%20Z37.3%21,O09.7%20Z37.4%21,O09.7%20Z37.5%21,O09.7%20Z37.6%21,O09.7%20Z37.7%21,O09.7%20Z37.9%21',
  ',O09.9%20Z37.0%21,O09.8%20Z37.1%21,O09.9%20Z37.2%21,O09.9%20Z37.3%21,O09.9%20Z37.4%21,O09.9%20Z37.5%21,O09.9%20Z37.6%21,O09.9%20Z37.7%21,O09.9%20Z37.9%21',
  ',O24.4',
  ',O30.0,O30.1,O30.2,O30.8,O30.9',
  ',O63.0,O63.1,O63.2,O63.9',
  ',O64.0,O64.1,O64.2,O64.3,O64.4,O64.5,O64.8,O64.9',
  ',O75.0,O75.1,O75.2,O75.3,O75.4,O75.5,O75.6,O75.7,O75.8,O75.9',
  ',O80,O81,O82',
  ',O80%20Z37.0%21,O81%20Z37.0%21,O82%20Z37.0%21',
  ',O80%20Z37.1%21,O81%20Z37.1%21,O82%20Z37.1%21',
  ',O80%20Z37.2%21,O81%20Z37.2%21,O82%20Z37.2%21',
  ',O80%20Z37.3%21,O81%20Z37.3%21,O82%20Z37.3%21',
  ',O80%20Z37.4%21,O81%20Z37.4%21,O82%20Z37.4%21',
  ',O80%20Z37.5%21,O81%20Z37.5%21,O82%20Z37.5%21',
  ',O80%20Z37.6%21,O81%20Z37.6%21,O82%20Z37.6%21',
  ',O80%20Z37.7%21,O81%20Z37.7%21,O82%20Z37.7%21',
  ',O80%20Z37.9%21,O81%20Z37.9%21,O82%20Z37.9%21',
  ',E84.0,E84.1,E84.8,E84.80,E84.87,E84.88,E84.9',
  ',J18.0,J18.1,J18.2,J18.8,J18.9',
  ',Z38.0,Z38.1,Z38.2,Z38.3,Z38.4,Z38.5,Z38.6,Z38.7,Z38.8',
  '&_include=Condition:subject:Patient')

condition_patient_bundle <- fhir_search(request=search_request, username = conf$user, password = conf$password, verbose = 2, max_bundles = 0)

Conditions <- fhir_table_description(resource = "Condition",
                                     cols = c(diagnosis = "code/coding/code",
                                              system = "code/coding/system",
                                              recorded_date = recorded_date_custom,# newly added
                                              patient_id = "subject/reference"
                                              )
)

Patients <- fhir_table_description(resource = "Patient",
                                   cols = c(patient_id = "id",
                                            hospital_id = "meta/source",
                                            gender = "gender",
                                            birthdate = "birthDate",
                                            patient_zip = "address/postalCode",
                                            countrycode = "address/country"
                                            )
)

design <- fhir_design(Conditions, Patients)

# To flatten the XML object bundles from patients and conditions to a list
list_cdn <- fhir_crack(condition_patient_bundle, design, sep = "|", brackets = c("[", "]"), verbose = 2)

df_conditions_raw <- list_cdn$Conditions
df_patients_raw <- list_cdn$Patients

# unnest raw conditions dataframe columns diagnosis, system
df_conditions_tmp <- fhir_melt(df_conditions_raw,
                               columns = c('diagnosis','system'),
                               brackets = c('[',']'), sep = '|', all_columns = TRUE,)

# unnest raw conditions dataframe columns diagnosis, system
df_conditions_tmp <- fhir_melt(df_conditions_tmp,
                               columns = c('diagnosis','system','patient_id'),
                               brackets = c('[',']'), sep = '|', all_columns = TRUE,)

df_conditions_tmp <- fhir_rm_indices(df_conditions_tmp, brackets = c("[", "]") )

#To remove the "Patient/" tag from patient id in condition resource
df_conditions_tmp$patient_id <- sub("Patient/", "", df_conditions_tmp[,"patient_id"])

df_patients_tmp <- fhir_melt(df_patients_raw,
                             columns = c('patient_zip','countrycode'),
                             brackets = c('[',']'), sep = '|', all_columns = TRUE,)

df_patients_tmp <- fhir_rm_indices(list_cdn$Patients, brackets = c("[", "]") )

df_patients_tmp <- df_patients_tmp[df_patients_tmp$gender != 'male',]
df_patients_tmp <- df_patients_tmp[!duplicated(df_patients_tmp$patient_id),]
df_patients_tmp$age <- round( as.double( as.Date( Sys.time() ) - as.Date( df_patients_tmp$birthdate ) ) / 365.25, 0 )
df_patients_tmp <- df_patients_tmp[df_patients_tmp$age > 14,]

x <- c(1,9,19,29,39,49,59,999)
df_patients_tmp$age_group <- cut(df_patients_tmp$age,x,breaks= c(0,9,19,29,39,49,59,999), labels = c("[1,9]","[10,19]","[20,29]","[30,39]","[40,49]","[50,59]","[60,999]"))

df_conditions_cf <- subset(df_conditions_tmp, grepl("^E84", diagnosis))
#df_conditions_cf$recorded_date <- as.Date(df_conditions_cf$recorded_date, format= "%Y-%m-%d")
#df_conditions_cf <- df_conditions_cf[df_conditions_cf$recorded_date < "2019-12-31",]

df_conditions_birth_all <- subset(df_conditions_tmp, grepl("^O|^Z", diagnosis))
#df_conditions_birth_all$recorded_date <- as.Date(df_conditions_birth_all$recorded_date, format= "%Y-%m-%d")
#df_conditions_birth_all <- df_conditions_birth_all[df_conditions_birth_all$recorded_date < "2019-12-31",]

df_cf_birth_all <- base::merge(df_conditions_cf, df_conditions_birth_all, by = "patient_id")
df_cf_birth_all <- base::merge(df_cf_birth_all, df_patients_tmp, by.x = "patient_id",by.y = "patient_id")
df_cf_birth_all <- df_cf_birth_all[!duplicated(df_cf_birth_all$patient_id),]

df_result_primaer <- as.data.frame(df_cf_birth_all%>%group_by(Einrichtungsindikator=df_cf_birth_all$hospital_id,AngabeDiagn1=df_cf_birth_all$diagnosis.x,AngabeDiagn2=df_cf_birth_all$diagnosis.y,AngabeGeschlecht=df_cf_birth_all$gender,AngabeAlter=df_cf_birth_all$age_group)%>%summarise(count=n()))
names(df_result_primaer)[names(df_result_primaer)== "count"] <- "Anzahl"

df_conditions_birth <- subset(df_conditions_tmp, grepl("^O09|^O3|^O63|^O8|^Z", diagnosis))

df_cf_birth <- base::merge(df_conditions_cf, df_conditions_birth, by = "patient_id")
df_cf_birth <- base::merge(df_cf_birth, df_patients_tmp, by.x = "patient_id",by.y = "patient_id")
df_cf_birth <- df_cf_birth[!duplicated(df_cf_birth$patient_id),]

df_result_sekundaer_a <- as.data.frame(df_cf_birth%>%group_by(Einrichtungsindikator=df_cf_birth$hospital_id,AngabeDiagn1=df_cf_birth$diagnosis.x,AngabeDiagn2=df_cf_birth$diagnosis.y,AngabeGeschlecht=df_cf_birth$gender,AngabeAlter=df_cf_birth$age_group)%>%summarise(count=n()))
names(df_result_sekundaer_a)[names(df_result_sekundaer_a)== "count"] <- "Anzahl"

df_conditions_complication <- subset(df_conditions_tmp, grepl("^O64|^O75|^O24", diagnosis))

df_cf_complication <- base::merge(df_conditions_cf, df_conditions_birth, by = "patient_id")
df_cf_complication <- base::merge(df_cf_complication, df_conditions_complication, by = "patient_id")
df_cf_complication <- base::merge(df_cf_complication, df_patients_tmp, by.x = "patient_id",by.y = "patient_id")
df_cf_complication <- df_cf_complication[!duplicated(df_cf_complication$patient_id),]

df_result_sekundaer_b <- as.data.frame(df_cf_complication%>%group_by(Einrichtungsindikator=df_cf_complication$hospital_id,AngabeDiagn1=df_cf_complication$diagnosis.x,AngabeDiagn2=df_cf_complication$diagnosis,AngabeGeschlecht=df_cf_complication$gender,AngabeAlter=df_cf_complication$age_group)%>%summarise(count=n()))
names(df_result_sekundaer_b)[names(df_result_sekundaer_b)== "count"] <- "Anzahl"

# display the final output
df_result_primaer
df_result_sekundaer_a
df_result_sekundaer_b
########################################################################################################################################################
# write result to a csv file
########################################################################################################################################################
write.csv(df_result_primaer,file= "result_primaer.csv",row.names=F)
write.csv(df_result_sekundaer_a,file= "result_sekundaer_a.csv",row.names=F)
write.csv(df_result_sekundaer_b,file= "result_sekundaer_b.csv",row.names=F)
########################################################################################################################################################