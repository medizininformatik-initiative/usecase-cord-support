if (!require('fhircrackr')) install.packages('fhircrackr')# In order to flatten the FHIR resources from XML objects; requires R (>= 4.0.0)
if (!require('config')) install.packages('config')
if (!require('stringr')) install.packages('stringr')#In order to add leading zeros to make zip codes five digits
if (!require('dplyr')) install.packages('dplyr')# In order to remove duplicates and summarise


library(fhircrackr) # to flatten the Resources 
library(config)# to read variables from a config file
library(dplyr) # to remove duplicates and group by patient id and summarise 
brackets = c("[", "]")
sep = " || "

##################################################################################################################################################################################################################
# Neu Tracer diagnosis
##################################################################################################################################################################################################################
conf <- config::get(file = paste(getwd(),"/config/conf.yml",sep=""))


if (exists("max_bundles", where = conf) && nchar(conf$max_bundles) >= 1) {
  max_bundles_custom <- conf$max_bundles
} else {
  max_bundles_custom <- Inf
}

if (exists("count", where = conf) && nchar(conf$count) >= 1) {
  customise_count <- c("_count" = conf$count)
} else {
  customise_count <- c("_count" = 100)
}


####check for department id if it exits and defined in conf file 
if (exists("department_identifier", where = conf) && nchar(conf$department_identifier) >= 1) {
  Condition_department <- fhir_url(url = conf$serverbase,
                                    resource = "Condition",
                                    parameters = c("code" = "D86.0,D86.1,D86.2,D86.3,D86.8,D86.9,D45,E03.0,E03.1,M93.2,D47.3,G70.0,K74.3,G61.0,G23.2,G23.3,L63.0,E84.0,E84.1,E84.80,E84.87,E84.88,E84.9,M31.3,M34.1,Q82.2,H35.1,Q96.0,Q96.1,Q96.2,Q96.3,Q96.4,Q96.8,Q96.9,L13.0,G10,I78.0,G54.5,I73.1,Q21.3,D83.0,D83.1,D83.2,D83.8,D83.9,Q87.4,M33.2,K62.7,D18.10,D18.11,D18.12,D18.13,D18.18,D18.19,D57.0,D57.1,D57.2,M33.0,M33.1,L63.1,G21.0,M35.2,M08.3,Q20.3,L93.1,L10.0,M30.0,Q78.0,Q43.1,E24.0,Q85.1,E83.0,P27.1,Q05.0,Q05.1,Q05.2,Q05.3,Q05.4,Q05.5,Q05.6,Q05.7,Q05.8,Q05.9,M908.2,E80.1,M09.00,M09.01,M09.02,M09.03,M09.04,M09.05,M09.06,M09.07,M09.08,M09.09,E70.0,L56.3,E83.3,Q78.2,G23.1,G71.2,Q79.6,K76.5,G11.4,Q79.0,Q30.0,Q22.5,Q77.4,Q68.8,Q23.4,F84.2,E83.5,D82.1,Q79.2,Q22.4,I42.8,Q17.2,E85.3,Q71.6,Q72.7,Q91.4,Q91.5,Q91.6,Q91.7,Q04.2,E71.0,D58.1,Q80.1,Q97.0,Q28.21,Q91.0,Q91.1,Q91.2,Q77.1,Q00.1,M30.3,D76.1,D76.2,D76.3,D76.4,A48.3,R65.0%21,R65.1%21,R65.2%21,R65.3%21,R65.9%21,R57.8,I40.0,I40.1,I40.8,I40.9,I41.1%2A,I41.8%2A,I25.4,I30.1,I30.8,I30.9,I32.1,D89.8,D89.9,U07.1%21,U07.2%21,U07.3,U07.4%21,U07.5,U08.9,U09.9%21,U10.9,E66.89,E74.0,E75.0,E75.2,G12.0,G12.1,G35.0,G35.10,G35.11,G35.20,G35.21,G35.30,G35.31,G35.9,G36.0,G36.1,G36.8,G36.9,G71.0,Q75.0,729,3318,567,1572,797,442,586,94093,102,2901,90050,36258,774,70475,704,1656,97230,700,701,85414,85436,900,117,70589,63260,83463,2248,46724,2440,2140,805,3380,3378,3375,C49.9,C56,C71.9,D12.6,D57.2,D81.8,D84.1,D84.8,E16.1,E70.0,E70.1,E70.3,E71.0,E71.1,E71.3,E72.0,E72.1,E72.2,E72.8,E74.0,E74.4,E74.8,E75.0,E75.1,E75.2,E75.4,E76.2,E77.1,E77.8,E78.6,E79.8,E83.0,E83.30,E83.31,E83.38,E83.39,E83.50,E83.58,E83.59,E85.3,F84.2,G10,G11.1,G11.2,G11.4,G11.8,G12.2,G23.1,G23.2,G24.1,G31.8,G40.3,G60.0,G60.8,G61.0,G70.0,G71.0,G71.1,G71.2,G71.8,H18.5,H35.5,I42.80,I42.88,M30.0,M33.0,M33.1,M33.2,M34.1,M35.8,M93.2,Q04.2,Q04.3,Q05.0,Q05.1,Q05.2,Q05.3,Q05.4,Q05.5,Q05.6,Q05.7,Q05.8,Q05.9,Q20.3,Q21.1,Q21.3,Q22.4,Q22.5,Q30.0,Q43.1,Q68.8,Q73.8,Q74.0,Q75.0,Q77.1,Q77.3,Q77.4,Q77.7,Q78.0,Q78.2,Q78.8,Q79.2,Q79.6,Q80.1,Q82.2,Q82.8,Q85.8,Q87.0,Q87.1,Q87.2,Q87.3,Q87.4,Q87.5,Q87.8,Q92.3,Q93.2,Q93.5,",
                                                  "encounter.class" = conf$inpatient,
                                                  "encounter.location:identifier" = conf$department_identifier,
                                                  "_include" = "Condition:subject",
                                                  customise_count
                                    )) 
} else {
  Condition_department <- fhir_url(url = conf$serverbase,
                                    resource = "Condition",
                                    parameters = c("code"="D86.0,D86.1,D86.2,D86.3,D86.8,D86.9,D45,E03.0,E03.1,M93.2,D47.3,G70.0,K74.3,G61.0,G23.2,G23.3,L63.0,E84.0,E84.1,E84.80,E84.87,E84.88,E84.9,M31.3,M34.1,Q82.2,H35.1,Q96.0,Q96.1,Q96.2,Q96.3,Q96.4,Q96.8,Q96.9,L13.0,G10,I78.0,G54.5,I73.1,Q21.3,D83.0,D83.1,D83.2,D83.8,D83.9,Q87.4,M33.2,K62.7,D18.10,D18.11,D18.12,D18.13,D18.18,D18.19,D57.0,D57.1,D57.2,M33.0,M33.1,L63.1,G21.0,M35.2,M08.3,Q20.3,L93.1,L10.0,M30.0,Q78.0,Q43.1,E24.0,Q85.1,E83.0,P27.1,Q05.0,Q05.1,Q05.2,Q05.3,Q05.4,Q05.5,Q05.6,Q05.7,Q05.8,Q05.9,M908.2,E80.1,M09.00,M09.01,M09.02,M09.03,M09.04,M09.05,M09.06,M09.07,M09.08,M09.09,E70.0,L56.3,E83.3,Q78.2,G23.1,G71.2,Q79.6,K76.5,G11.4,Q79.0,Q30.0,Q22.5,Q77.4,Q68.8,Q23.4,F84.2,E83.5,D82.1,Q79.2,Q22.4,I42.8,Q17.2,E85.3,Q71.6,Q72.7,Q91.4,Q91.5,Q91.6,Q91.7,Q04.2,E71.0,D58.1,Q80.1,Q97.0,Q28.21,Q91.0,Q91.1,Q91.2,Q77.1,Q00.1,M30.3,D76.1,D76.2,D76.3,D76.4,A48.3,R65.0%21,R65.1%21,R65.2%21,R65.3%21,R65.9%21,R57.8,I40.0,I40.1,I40.8,I40.9,I41.1%2A,I41.8%2A,I25.4,I30.1,I30.8,I30.9,I32.1,D89.8,D89.9,U07.1%21,U07.2%21,U07.3,U07.4%21,U07.5,U08.9,U09.9%21,U10.9,E66.89,E74.0,E75.0,E75.2,G12.0,G12.1,G35.0,G35.10,G35.11,G35.20,G35.21,G35.30,G35.31,G35.9,G36.0,G36.1,G36.8,G36.9,G71.0,Q75.0,729,3318,567,1572,797,442,586,94093,102,2901,90050,36258,774,70475,704,1656,97230,700,701,85414,85436,900,117,70589,63260,83463,2248,46724,2440,2140,805,3380,3378,3375,C49.9,C56,C71.9,D12.6,D57.2,D81.8,D84.1,D84.8,E16.1,E70.0,E70.1,E70.3,E71.0,E71.1,E71.3,E72.0,E72.1,E72.2,E72.8,E74.0,E74.4,E74.8,E75.0,E75.1,E75.2,E75.4,E76.2,E77.1,E77.8,E78.6,E79.8,E83.0,E83.30,E83.31,E83.38,E83.39,E83.50,E83.58,E83.59,E85.3,F84.2,G10,G11.1,G11.2,G11.4,G11.8,G12.2,G23.1,G23.2,G24.1,G31.8,G40.3,G60.0,G60.8,G61.0,G70.0,G71.0,G71.1,G71.2,G71.8,H18.5,H35.5,I42.80,I42.88,M30.0,M33.0,M33.1,M33.2,M34.1,M35.8,M93.2,Q04.2,Q04.3,Q05.0,Q05.1,Q05.2,Q05.3,Q05.4,Q05.5,Q05.6,Q05.7,Q05.8,Q05.9,Q20.3,Q21.1,Q21.3,Q22.4,Q22.5,Q30.0,Q43.1,Q68.8,Q73.8,Q74.0,Q75.0,Q77.1,Q77.3,Q77.4,Q77.7,Q78.0,Q78.2,Q78.8,Q79.2,Q79.6,Q80.1,Q82.2,Q82.8,Q85.8,Q87.0,Q87.1,Q87.2,Q87.3,Q87.4,Q87.5,Q87.8,Q92.3,Q93.2,Q93.5",
                                                   "encounter.class" = conf$inpatient, 
                                                   "_include" = "Condition:subject",
                                                   customise_count
                                    )) 
}

#############################################################################################################################################################################################################################################################################################################################################################################################################################
# Design parameter for Condition and Patient resources
# provide style parameter for Patient resource similar to Condition Resource if fhir_crack function demands
######################################################################################################################################################################################################################################################################################################################################################################################################################
patients <- fhir_table_description(resource = "Patient",
                                   cols = c(patient_id = "id",
                                            gender        = "gender",
                                            birthdate     = "birthDate",
                                            patient_zip   = "address/postalCode",
                                            countrycode   = "address/country"
                                   ),
                                   style = fhir_style(sep=sep,
                                                      brackets = brackets,
                                                      rm_empty_cols = FALSE)
)



encounters <- fhir_table_description(resource = "Encounter",
                                     cols = c(encounter_id = "id",
                                              admission_date= "period/start",
                                              discharge_date= "period/end",
                                              condition_id ="diagnosis/condition/reference",
                                              patient_id = "subject/reference",
                                              patient_type_fhir_class ="class/code",
                                              diagnosis_use = "diagnosis/use/coding/code"
                                     ),
                                     style = fhir_style(sep=sep,
                                                        brackets = brackets,
                                                        rm_empty_cols = FALSE)
)


conditions <- fhir_table_description(resource = "Condition",
                                     cols = c(condition_id = "id",
                                              recorded_date= "recordedDate",
                                              diagnosis = "code/coding/code",
                                              system         = "code/coding/system",
                                              encounter_id = "encounter/reference",
                                              patient_id     = "subject/reference"),
                                     style = fhir_style(sep=sep,
                                                        brackets = brackets,
                                                        rm_empty_cols = FALSE)
)

##################################################################################################################################################################################
# Using fhir_design function from fhircrcakr package 
# the usage of old-style design object will be disallowed in the near future
# so we use the new fhir_design function
##################################################################################################################################################################################
design <- fhir_design(conditions, patients)

# download fhir bundles , setting verbose to 2 to view the actual FHIR search statement
bundles <- fhir_search(request = Condition_department, username = conf$username, password = conf$password, verbose = 2, max_bundles = max_bundles_custom )

# crack fhir bundles
dfs <- fhir_crack(bundles, design)

# save raw fhir_table_descriptions
conditions_raw <- dfs$conditions
patients_raw <- dfs$patients

# unnest raw conditions dataframe columns diagnosis, system
conditions_tmp <- fhir_melt(conditions_raw,
                            columns = c('condition_id','recorded_date','diagnosis','system','encounter_id','patient_id'),
                            brackets = c('[',']'), sep = '|', all_columns = TRUE,)

#conditions_tmp <- fhir_melt(conditions_tmp,
#                            columns = c('condition_id','recorded_date','diagnosis','system','encounter_id','patient_id'),
#                            brackets = c('[',']'), sep = '|', all_columns = TRUE,)

# remove brackets from cells
conditions_tmp <- fhir_rm_indices(conditions_tmp, brackets = c("[", "]") )
patients_tmp <- fhir_rm_indices(patients_raw, brackets = c("[", "]") )

# filter conditions by system to obtain only icd-10-gm system
if (exists("orpha_system", where = conf) && nchar(conf$orpha_system) >= 1) {
  conditions_tmp <- conditions_tmp [(conditions_tmp$system == 'http://fhir.de/CodeSystem/bfarm/icd-10-gm') | (conditions_tmp$system == 'http://fhir.de/CodeSystem/dimdi/icd-10-gm') | (conditions_tmp$system == 'http://www.orpha.net'),] 
} else {
  conditions_tmp <- conditions_tmp [(conditions_tmp$system == 'http://fhir.de/CodeSystem/bfarm/icd-10-gm') | (conditions_tmp$system == 'http://fhir.de/CodeSystem/dimdi/icd-10-gm') ,] 
}

# remove duplicate patients
conditions_tmp <- conditions_tmp[!duplicated(conditions_tmp$patient_id,conditions_tmp$diagnosis),]
#conditions_tmp <- conditions_tmp %>% group_by(condition_id, recorded_date, diagnosis, system, encounter_id, patient_id) %>% summarise(patient_id,.groups = "keep")


# check if country code column exists. if yes then filter Patient by country code to obtain only Patients from Germany 
if ("countrycode" %in% colnames(patients_tmp))
{
  patients_tmp <- patients_tmp[patients_tmp$countrycode == "DE", ]
}

# remove the "Patient/" tag from patient id in condition resource
conditions_tmp$patient_id <- sub("Patient/", "", conditions_tmp[,"patient_id"])

# merge conditions and patients dataframe
df_conditions_patients <- base::merge(conditions_tmp, patients_tmp, by = "patient_id")

# calculate age in years by birthdate conditions and patients dataframe must of same length
df_conditions_patients$age <- round( as.double( as.Date( df_conditions_patients$recorded_date ) - as.Date( df_conditions_patients$birthdate ) ) / 365.25, 0 )

# remove duplicate patients, so that the resulting dataframe has maximum age 
df_merged <- df_conditions_patients %>% group_by(patient_id, gender, birthdate, patient_zip, countrycode, condition_id, recorded_date, diagnosis, system, encounter_id) %>% summarise(age=max(age),.groups = "keep")

#center infos
df_merged$hospital_name <- conf$hospital_name
df_merged$hospital_zip <- conf$hospital_zip

#leading zeros for zip code
df_merged$patient_zip <- stringr::str_pad(df_merged$patient_zip, 5, side = "left", pad = 0)
df_merged$hospital_zip <- stringr::str_pad(df_merged$hospital_zip, 5, side = "left", pad = 0)

# create prefinal dataframe with only relevant columns
df_result <- df_merged[,c('patient_id','age','gender','hospital_name', 'patient_zip','diagnosis')]

# write csv with ";" to file
write.csv2(df_result,file=conf$cracked_result,row.names=F,quote=F)