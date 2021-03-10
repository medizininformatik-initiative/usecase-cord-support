####################################################################################################################
# To calculate the aggregate of patients corresponding to O80 and Z37.0!
#(Mukoviszidose/CF Cystic Fibrosis and Birth)
#####################################################################################################################
library(fhircrackr)
library(dplyr)
library(tibble)
library(stringr)
library(tidyr)
options(warn=-1)# to suppress warnings
###################################################################################################################################################################################################################################################################
#Condition resource with patient resource in a bundle for ICD-10 GM Diagnoses Code O80, O80 Z37.0! (associated birth)
###############################################################################################################################################################################################################################################################
#O80 und Z37.0!
condition_patient_bundle<- fhir_search("https://mii-agiop-cord.life.uni-leipzig.de/fhir/Condition?code=O80,O80%20Z37.0%21&_include=Condition:subject:Patient")

#############################################################################################################################################################################################
# Specify the columns of interest in design parameter including condition and patient resource
#############################################################################################################################################################################################

design_cond <- list(
	Conditions = list(
		"//Condition",
		#list(
		cols       = list(
			C.CID  = "id",#condition id
			C.PID  = "subject/reference",# patient id
			C.SECODE = "code/coding/code",#attribute to address rare disease codes from tracer diagnose list
			C.DiagText1 ="category/text",# diagnoses text 1
			C.DiagText2 ="code/text" # diagnoses text 2, it is here the description of diagnoses is captured and assigned
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
			P.PID        = "id",# patient id
			P.SOURCE="meta/source",#the  integration center id
			P.GESCHLECHT  = "gender",# patient gender to be replaced later
			P.GEBD   = "birthDate",# birth date to calculate age bins
			P.PLZ = "address/postalCode"# plz

		)
	)
)

# To flatten the O80 and Z37.0! XML object bundles from patients and conditions to a list
list_cdn <- fhir_crack(condition_patient_bundle, design_cond, verbose = 0)
#To remove the "Patient/" tag from patient id in condition resource use string remove all

list_cdn$Conditions$C.PID <- str_remove_all(list_cdn$Conditions$C.PID,"Patient/")#updated because the patient id tag included the house source

# function to calculate age and join the condition resource to patient resource based on Patient id
#merge conditions and patient resources based on patient id similar to join
join_processing <- function( jn ) {
	jn$ALL <-
		merge(
			jn$Conditions,
			jn$Patients,
			by.x = "C.PID",
			by.y = "P.PID",
			all = T
		)
	jn$ALL$AGE <- round( as.double( as.Date( Sys.time() ) - as.Date( jn$ALL$P.GEBD ) ) / 365.25, 2 )
	jn
}

# after joining
list_dfcp <- join_processing(list_cdn)
###############################################################################################################################################################################################################################################################
# from all the O80 and O80 Z37.0! combination select only Cystic fibrosis associated with birth. that is Diagnoses text "CF-Geburt"
###############################################################################################################################################################################################################################################################
list_dfcp$ALL <- list_dfcp$ALL[list_dfcp$ALL$C.DiagText2 == "CF-Geburt",]

#data frame object
# selected columns included
#list with condition and patients are filtered with the selectedcolumns

list_f <- list_dfcp$ALL[,c('P.SOURCE','C.SECODE','C.DiagText1','C.DiagText2','P.GESCHLECHT','AGE')]
######################################################################################################################################################################################################################################################################
# set of formatting
###############################################################################################################################################################################################################################################################
#include the extra slash for gsub to detect back slash and remove them from secondary codes
list_f$C.SECODE <- str_replace_all(list_f$C.SECODE,"/","//")
#remove the codes after decimal
list_f$C.SECODE <- gsub("([/]/.*)","",list_f$C.SECODE)

#replace the decimal with a comma as indicated by Josef in the use case result for e.g., E84,-
list_f$C.SECODE <- gsub("\\..*","\\1,-",list_f$C.SECODE)
#replace male with m and female with f
list_f$P.GESCHLECHT [list_f$P.GESCHLECHT == "female"] <- "f"
list_f$P.GESCHLECHT [list_f$P.GESCHLECHT == "male"] <- "m"
list_f$P.GESCHLECHT [list_f$P.GESCHLECHT == ""] <- "NA"
# remove the contents after hash (#) symbol in source to input content for einrichtungs identifikator
list_f$P.SOURCE <- gsub("#.*","\\1",list_f$P.SOURCE)#

#######################################################################################################################################################################
#define bin intervals for age
########################################################################################################################################################
x <- c(1,10,20,30,40,50,60,70,80,90,999)
list_f$AGE <- cut(list_f$AGE,x,breaks= c(0,10,20,30,40,50,60,70,80,90,999), labels = c("(1,10]","(11,20]", "(21,30]", "(31,40]", "(41,50]", "(51,60]","(61,70]","(71,80]","(81,90]", "(91,999]"))

df_cfa <- as.data.frame(list_f%>%group_by(list_f$P.SOURCE,list_f$C.SECODE,list_f$C.DiagText2,list_f$P.GESCHLECHT,list_f$AGE)%>%summarise(count=n()))

# to get all the O80 related  patients
df_cfa$`list_f$C.SECODE` [df_cfa$`list_f$C.SECODE` == "O80 Z37,-"] <- "O80"

#omit rows with na values
df_cfa <- na.omit(df_cfa)
#### Rename column names ###########################################################################################################################
#'P.SOURCE','C.SECODE','C.DiagText1','C.DiagText2','P.GESCHLECHT','AGE', 'Count'
########################################################################################################################################################

names(df_cfa)[names(df_cfa)== "list_f$P.SOURCE"] <- "Einrichtungsidentifikator"
names(df_cfa)[names(df_cfa)== "list_f$C.SECODE"] <- "AngabeDiagn2"
names(df_cfa)[names(df_cfa)== "list_f$P.GESCHLECHT"] <- "AngabeGeschlecht"
names(df_cfa)[names(df_cfa)== "list_f$AGE"] <- "AngabeAlter"
#names(df_cfa)[names(df_cfa)== "list_f$C.DiagText1"] <- "TextDiagnose1"
names(df_cfa)[names(df_cfa)== "list_f$C.DiagText2"] <- "TextDiagnose2"
names(df_cfa)[names(df_cfa)== "count"] <- "Anzahl"
#########
#select output columns
#filter only selected columns
df_cfa <- df_cfa[,c('Einrichtungsidentifikator','AngabeDiagn2','AngabeGeschlecht','AngabeAlter','Anzahl')]

##################################################################################################################################################################
# The requirement was to provide a column with diagnoses E84,- code  include a column for that
########################################################################################################################################################
df_cfa <- df_cfa %>%
	# Creating a column with diagnose code E84 as stated in requirement :
	add_column(AngabeDiagn1 = "E84,-", .after="Einrichtungsidentifikator")
########################################################################################################################################################
# write result to a csv file
########################################################################################################################################################
write.csv(df_cfa, file = "c:\\users\\username\\Documents\\result.csv" , row.names = F)
########################################################################################################################################################