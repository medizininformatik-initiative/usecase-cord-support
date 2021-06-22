library(fhircrackr)
library(tidyverse)

library(config)# to read fhir server credentials from a config file
library(readxl)# to read excel file

options(warn=-1)# hide warnings
#options(warn=0)

webconn <- config::get(file = paste(getwd(),"/config/conf_fhir.yml",sep=""))
##################################################################################################################################################################################################################
## When tracer diagnose list is updated then read the tracer diagnose list with  ICD 10 GM Codes
## Tracer diagnose list is available in the following link
## https://zmi.uniklinikum-dresden.de/confluence/download/attachments/79997703/Tracerliste_f%C3%BCr_Schaufenster.xlsx?version=1&modificationDate=1610533779949&api=v2
##################################################################################################################################################################################################################
#uncomment1 the below line *
#tracerlist <- read_excel(path = paste(getwd(),"/input/Tracerliste_für_Schaufenster.xlsx",sep = ""))
##################################################################################################################################################################################################################
#Provide your base url here in the variable urlbase
###################################################
#uncomment the below line *
#icd_10 <- tracerlist$`ICD-10-GM-Kode`
# Separate each ICD-10 gm code with a comma
#uncomment the below line *
#icd10code_tracergroup <- paste(icd_10,collapse=",")
############
serverbase = 'http://10.3.8.72/fhir/'

search_request <- paste0(
	serverbase,
	'Condition?',
	'code=',
	'D86.0,D86.1,D86.2,D86.3,D86.8,D86.9,D45,E03.0,E03.1,M93.2,D47.3,G70.0,K74.3,G61.0,G23.2,G23.3,L63.0,E84.0,E84.1,E84.80,E84.87,E84.88,E84.9,M31.3,M34.1,Q82.2,H35.1,Q96.0,Q96.1,Q96.2,Q96.3,Q96.4,Q96.8,Q96.9,L13.0,G10,I78.0,G54.5,I73.1,Q21.3,D83.0,D83.1,D83.2,D83.8,D83.9,Q87.4,M33.2,K62.7,D18.10,D18.11,D18.12,D18.13,D18.18,D18.19,D57.0,D57.1,D57.2,M33.0,M33.1,L63.1,G21.0,M35.2,M08.3,Q20.3,L93.1,L10.0,M30.0,Q78.0,Q43.1,E24.0,Q85.1,E83.0,P27.1,Q05.0,Q05.1,Q05.2,Q05.3,Q05.4,Q05.5,Q05.6,Q05.7,Q05.8,Q05.9,M908.2,E80.1,M09.00,M09.01,M09.02,M09.03,M09.04,M09.05,M09.06,M09.07,M09.08,M09.09,E70.0,L56.3,E83.3,Q78.2,G23.1,G71.2,Q79.6,K76.5,G11.4,Q79.0,Q30.0,Q22.5,Q77.4,Q68.8,Q23.4,F84.2,E83.5,D82.1,Q79.2,Q22.4,I42.8,Q17.2,E85.3,Q71.6,Q72.7,Q91.4,Q91.5,Q91.6,Q91.7,Q04.2,E71.0,D58.1,Q80.1,Q97.0,Q28.21,Q91.0,Q91.1,Q91.2,Q77.1,Q00.1,M30.3,D76.1,D76.2,D76.3,D76.4,A48.3,R65.0%21,R65.1%21,R65.2%21,R65.3%21,R65.9%21,R57.8,I40.0,I40.1,I40.8,I40.9,I41.1%2A,I41.8%2A,I25.4,I30.1,I30.8,I30.9,I32.1,D89.8,D89.9,U07.1%21,U07.2%21,U07.3,U07.4%21,U07.5,U08.9,U09.9%21,U10.9,E66.89,E74.0,E75.0,E75.2,G12.0,G12.1,G35.0,G35.10,G35.11,G35.20,G35.21,G35.30,G35.31,G35.9,G36.0,G36.1,G36.8,G36.9,G71.0,Q75.0,',
	'&_include=Condition:subject'
)
patient_diagn_bundle <- fhir_search(request =search_request,username = webconn$user, password = webconn$password, verbose=1)

#######Design #############################
design_cond <- list(
	Conditions = list(
		"//Condition",
		#list(
		cols       = list(
			C.CID  = "id",    # condition id
			C.PID  = "subject/reference", # reference patient id
			C.SECODE ="code/coding/code" #attribute to address rare disease codes from tracer diagnose list
		),
		style = list(
			sep = "/",
			brackets = NULL,
			rm_empty_cols = FALSE
		)
	),
	Patients = list(
		"//Patient",
		list(
			P.PID        = "id", # Patient pseudonym in mannheim verfügbar
			P.GESCHLECHT  = "gender", # Geschlecht
			P.GEBD   = "birthDate",# Geburtsdatum
			P.PLZ = "address/postalCode"# PLZ
		)
	)
)
# To flatten the XML object bundles to a list conatinng patient and diagnose

list_se_pd <- fhir_crack(patient_diagn_bundle, design_cond, verbose = 0)

##
#To remove the "Patient/" tag from patient id in condition resource use string remove all
list_se_pd$Conditions$C.PID <- str_remove_all(list_se_pd$Conditions$C.PID,"Patient/")


# Output directory folder
output_directory <- "/opt/outputGlobal"

# function to calculate age and join the condition resource to patient resource based on Patient id
post_processing <- function( lot ) {
	lot$ALL <-
		merge(
			lot$Conditions,
			lot$Patients,
			by.x = "C.PID",
			by.y = "P.PID",
			all = T
		)
	lot$ALL$AGE <- round( as.double( as.Date( Sys.time() ) - as.Date( lot$ALL$P.GEBD ) ) / 365.25, 2 )
	#lot <- lot [,-6]
	lot
}
# after joining
list_of_tables <- post_processing(list_se_pd)
#data frame object
# selected columns included
#list with condition and patients are filtered with the selectedcolumns
list_f <- list_of_tables$ALL[,c('C.PID','C.SECODE','P.GESCHLECHT','P.GEBD','P.PLZ','AGE')]

list_f$center_name <- "UMM"
list_f$center_zip <- "68167"

#######################################################################################################################################################################
#define bin intervals for age
########################################################################################################################################################
x <- c(1,10,20,30,40,50,60,70,80,90,999)
list_f$AGE <- cut(list_f$AGE,x,breaks= c(0,10,20,30,40,50,60,70,80,90,999), labels = c("(1,10]","(11,20]", "(21,30]", "(31,40]", "(41,50]", "(51,60]","(61,70]","(71,80]","(81,90]", "(91,999]"))


# prefinal dataframe with relevant columns
#df_result <- df_merged[,c('patient_id','age','gender','zip','center_name','center_zip','icd_code')]
