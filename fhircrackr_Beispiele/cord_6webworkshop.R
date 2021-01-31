################################################
#Demonstration of fhircrackr for CORD testdata
#6. CORD-MI Web-Workshop
#Author: Julia Palm (ehem. Gantner)
#Date: 04.12.2020
################################################



#load packages (if necessary install beforehand e.g. with install.packages("fhircrackr"))
library(fhircrackr)
library(lubridate)
library(dplyr)
library(tidyr)

#define fhir search request
search_request <- paste0(
  "https://mii-agiop-cord.life.uni-leipzig.de/fhir/Patient?",
  "_revinclude=Condition:patient",
  "&_revinclude=Encounter:patient"
)

#download bundles
bundles <- fhir_search(search_request, max_bundles = 10)


#optional: save bundles
#fhir_save(bundles, directory = "resulting_10bundles")
#bundles<-fhir_load("resulting_10bundles")


#Define structure of data.frames
design <- list(
 
  #Patient resources
   Patients = list(
    resource = "//Patient",
    cols = list(
      resourceId = "id",
      birthdate = "birthDate",
      identifier = "identifier/value",
      id.system = "identifier/system",
      gender = "gender"
    ),
    style = list(
      sep = " % ",
      brackets = c("[", "]")
    )
  ),
  
  #Condition resources
  Conditions = list(
    resource = "//Condition",
    cols = list(
      patId = "subject/reference",
      code = "code/coding/code",
      system = "code/coding/system",
      display = "code/coding/display",
      text = "code/text"
    ),
    style = list(
      sep = " % ",
      brackets = c("[", "]")
    )
  ),
  
  #Encounter resources
  Encounter = list(
    resource = "//Encounter",
    cols = list(
      patId = "subject/reference",
      start = "period/start",
      end = "period/end",
      identifier = "identifier/value"
    )
  )
  
)

#flatten resources
tables <- fhir_crack(bundles, design)


####Prepare for join####

####Patients####
View(head(tables$Patients))

#sort out ids
molten_Patients <- fhir_melt(tables$Patients, 
                             columns = c("identifier", "id.system"), 
                             brackets = c("[", "]"), 
                             sep = " % ",
                             all_columns = T)

View(molten_Patients)

#indices are not needed anymore
Patients <- fhir_rm_indices(molten_Patients, brackets = c("[", "]"))

View(Patients)

#spread
Pat <- pivot_wider(Patients, names_from = "id.system", values_from = "identifier")
View(Pat)

#clean up
Pat$resource_identifier <- NULL
Pat$`http://fhir.de/NamingSystem/gkv/kvid-10` <- NULL

Pat$birthdate <- year(as.Date(Pat$birthdate))

View(Pat)

#set column names
names(Pat) <- c("resourceId", "GebJahr", "Gender", "PatientIdentifikator")
View(Pat)





####Condition####
View(tables$Conditions)

#sort out codes
conditions_molten1 <- fhir_melt(tables$Conditions, 
                                columns = c("code", "system", "display", "text"),
                                brackets = c("[","]"),                             
                                sep = " % ",
                                all_columns = T) 

View(conditions_molten1)

conditions_molten2 <- fhir_melt(conditions_molten1, 
                                columns = c("code", "system", "display"),
                                brackets = c("[","]"),                             
                                sep = " % ",
                                all_columns = T) 
View(conditions_molten2)     

Conditions <- fhir_rm_indices(conditions_molten2, brackets = c("[", "]"))
View(Conditions)

#clean up
Conditions$patId <- sub("Patient/", "", Conditions$patId)
Conditions$resource_identifier <- NULL
Conditions<- distinct(Conditions)

#create one data.frame per code type // Alternative to spread to wide format
icd <- Conditions[Conditions$system=="http://fhir.de/CodeSystem/dimdi/icd-10-gm",]
orpha <- Conditions[Conditions$system=="http://www.orpha.net",]

#clean up sub frames
View(icd)
icd$display <- NULL
icd$system <- NULL
names(icd) <- c("patId", "icd_Primaercode", "Diagnosetext")

View(icd)


View(orpha)
orpha$system <- NULL
orpha$text <- NULL
names(orpha) <- c("patId", "Orpha_Code", "Orpha_Text")

View(orpha)

#join condition data
con <- full_join(icd, orpha, by="patId") 
View(con)




#####Encounter#####
View(head(tables$Encounter))

#clean up
Enc <- tables$Encounter

Enc$patId <- sub("Patient/", "", Enc$patId)
Enc$start <- format(as.Date(Enc$start), "%Y-%m")
Enc$end <- format(as.Date(Enc$end), "%Y-%m")

names(Enc) <- c("patId", "AufnMonat", "EntlMonat", "Aufnahmenummer")

View(Enc)

#merge all
nrow(Pat)
nrow(con)
nrow(Enc)

d1 <- full_join(Enc,con, by="patId")
data <- full_join(Pat, d1, by = c("resourceId"="patId"))

#View final data set
View(data)

write.csv(data, "myData.csv")
