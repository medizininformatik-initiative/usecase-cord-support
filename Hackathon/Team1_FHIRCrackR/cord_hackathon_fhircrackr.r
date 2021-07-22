if (!require('fhircrackr')) install.packages('fhircrackr')# to flatten the FHIR resources from XML objects; requires R (>= 4.0.0)
if (!require('config')) install.packages('config')
if (!require('stringr')) install.packages('stringr')#to add leading zeros to make zip codes five digits

library(fhircrackr) # to flatten the Resources 
library(config)# to read variables from a config file

##################################################################################################################################################################################################################
# Tracer diagnose list is available in the following link
# https://zmi.uniklinikum-dresden.de/confluence/download/attachments/79997703/Tracerliste_f%C3%BCr_Schaufenster.xlsx?version=1&modificationDate=1610533779949&api=v2
# When the tracer diagnose list is updated then read the tracer diagnose list with  ICD 10 GM Codes
##################################################################################################################################################################################################################
conf <- config::get(file = paste(getwd(),"/config/conf.yml",sep=""))

# Compose fhir search request for the fhircrackr package
search_request <- paste0(
  conf$serverbase,
  'Condition?',
  'code=',
  'D86.0,D86.1,D86.2,D86.3,D86.8,D86.9,D45,E03.0,E03.1,M93.2,D47.3,G70.0,K74.3,G61.0,G23.2,G23.3,L63.0,E84.0,E84.1,E84.80,E84.87,E84.88,E84.9,M31.3,M34.1,Q82.2,H35.1,Q96.0,Q96.1,Q96.2,Q96.3,Q96.4,Q96.8,Q96.9,L13.0,G10,I78.0,G54.5,I73.1,Q21.3,D83.0,D83.1,D83.2,D83.8,D83.9,Q87.4,M33.2,K62.7,D18.10,D18.11,D18.12,D18.13,D18.18,D18.19,D57.0,D57.1,D57.2,M33.0,M33.1,L63.1,G21.0,M35.2,M08.3,Q20.3,L93.1,L10.0,M30.0,Q78.0,Q43.1,E24.0,Q85.1,E83.0,P27.1,Q05.0,Q05.1,Q05.2,Q05.3,Q05.4,Q05.5,Q05.6,Q05.7,Q05.8,Q05.9,M908.2,E80.1,M09.00,M09.01,M09.02,M09.03,M09.04,M09.05,M09.06,M09.07,M09.08,M09.09,E70.0,L56.3,E83.3,Q78.2,G23.1,G71.2,Q79.6,K76.5,G11.4,Q79.0,Q30.0,Q22.5,Q77.4,Q68.8,Q23.4,F84.2,E83.5,D82.1,Q79.2,Q22.4,I42.8,Q17.2,E85.3,Q71.6,Q72.7,Q91.4,Q91.5,Q91.6,Q91.7,Q04.2,E71.0,D58.1,Q80.1,Q97.0,Q28.21,Q91.0,Q91.1,Q91.2,Q77.1,Q00.1,M30.3,D76.1,D76.2,D76.3,D76.4,A48.3,R65.0%21,R65.1%21,R65.2%21,R65.3%21,R65.9%21,R57.8,I40.0,I40.1,I40.8,I40.9,I41.1%2A,I41.8%2A,I25.4,I30.1,I30.8,I30.9,I32.1,D89.8,D89.9,U07.1%21,U07.2%21,U07.3,U07.4%21,U07.5,U08.9,U09.9%21,U10.9,E66.89,E74.0,E75.0,E75.2,G12.0,G12.1,G35.0,G35.10,G35.11,G35.20,G35.21,G35.30,G35.31,G35.9,G36.0,G36.1,G36.8,G36.9,G71.0,Q75.0,',
  '&_include=Condition:subject'
)

#############################################################################################################################################################################################################################################################################################################################################################################################################################
# Design parameter for Condition and Patient resources
# provide style parameter for Patient resource similar to Condition Resource if fhir_crack function demands
######################################################################################################################################################################################################################################################################################################################################################################################################################
conditions <- fhir_table_description(resource = "Condition",
                                     cols = c(diagnosis = "code/coding/code",
                                              system = "code/coding/system",
                                              patient_id = "subject/reference"),
                                     style = fhir_style(sep="|",
                                                        brackets = c("[", "]"),
                                                        rm_empty_cols = FALSE)
)

patients <- fhir_table_description(resource = "Patient",
                                   cols = c(patient_id = "id",
                                            gender = "gender",
                                            birthdate = "birthDate",
                                            patient_zip = "address/postalCode"),
                                   style = fhir_style(sep="|",
                                                      brackets = c("[", "]"),
                                                      rm_empty_cols = FALSE)
)

##################################################################################################################################################################################
# Using fhir_design function from fhircrcakr package 
# the usage of old-style design object will be disallowed in the near future
# so we use the new fhir_design function
##################################################################################################################################################################################
design <- fhir_design(conditions, patients)

# download fhir bundles
bundles <- fhir_search(request = search_request, username = conf$user, password = conf$password, verbose = 1)

# crack fhir bundles
dfs <- fhir_crack(bundles, design)

# save raw fhir_table_descriptions
conditions_raw <- dfs$conditions
patients_raw <- dfs$patients

# unnest raw conditions dataframe columns diagnosis, system
conditions_tmp <- fhir_melt(conditions_raw,
                            columns = c('diagnosis','system'),
                            brackets = c('[',']'), sep = '|', all_columns = TRUE,)

conditions_tmp <- fhir_melt(conditions_tmp,
                            columns = c('diagnosis','system'),
                            brackets = c('[',']'), sep = '|', all_columns = TRUE,)

# remove brackets from cells
conditions_tmp <- fhir_rm_indices(conditions_tmp, brackets = c("[", "]") )
patients_tmp <- fhir_rm_indices(patients_raw, brackets = c("[", "]") )

# filter conditions by system to obtain only icd-10-gm system
conditions_tmp <- conditions_tmp[conditions_tmp$system == 'http://fhir.de/CodeSystem/dimdi/icd-10-gm',]

# remove duplicate patients
conditions_tmp <- conditions_tmp[!duplicated(conditions_tmp$patient_id,conditions_tmp$diagnosis),]
patients_tmp <- patients_tmp[!duplicated(patients_tmp$patient_id),]

# calculate age in years by birthdate
patients_tmp$age <- round( as.double( as.Date( Sys.time() ) - as.Date( patients_tmp$birthdate ) ) / 365.25, 0 )

# remove the "Patient/" tag from patient id in condition resource
conditions_tmp$patient_id <- sub("Patient/", "", conditions_tmp[,"patient_id"])

# merge all patients and conditions data by patient_id
df_merged <- base::merge(patients_tmp, conditions_tmp, by = "patient_id")

#center infos
df_merged$hospital_name <- conf$hospital_name
df_merged$hospital_zip <- conf$hospital_zip

#leading zeros for zip code
df_merged$patient_zip <- stringr::str_pad(df_merged$patient_zip, 5, side = "left", pad = 0)
df_merged$hospital_zip <- stringr::str_pad(df_merged$hospital_zip, 5, side = "left", pad = 0)

# create prefinal dataframe with only relevant columns
df_result <- df_merged[,c('patient_id','age','gender','hospital_name','hospital_zip','patient_zip','diagnosis')]

# write csv with ";" to file
write.csv2(df_result,file= "cracked_result.csv")

