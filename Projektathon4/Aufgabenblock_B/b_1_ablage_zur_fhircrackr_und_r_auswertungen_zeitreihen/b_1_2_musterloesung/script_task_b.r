library(fhircrackr)
library(tidyverse)
library(ggplot2)
 
search_request <- paste0(
  'https://mii-agiop-cord.life.uni-leipzig.de/fhir/',
  'Condition?',
  'code=J12.8%20U07.1%21,U08.9%20U09.9%21',
 ',M30.3', #choose, if you want to search for kawasaki
  ''
)
 
# define design
design <- list(
  Conditions = list(
    resource = "//Condition",
    cols = list(
      condition_id = "id",
      code = "code/coding/code",
      display = "code/coding/display",
      system = "code/coding/system",
      patient_id = "subject/reference",
      encounter_id = "encounter/reference",
      recorded_date = "recordedDate"
    ),
    style = list(
      sep="|",
      brackets = c("[", "]"),
      rm_empty_cols = FALSE
    )
  )
)
 
# download fhir bundles
bundles <- fhir_search(request = search_request, max_bundles = 50)
 
# crack fhir bundles
dfs <- fhir_crack(bundles, design)
 
# save raw conditions dataframe
covid_conditions_raw <- dfs$Conditions
 
# unnest raw conditions dataframe columns code/coding/code, code/coding/display, code/coding/system
covid_conditions_tmp <- fhir_melt(covid_conditions_raw,
                                  columns = c('code','display','system'),
                                  brackets = c('[',']'), sep = '|', all_columns = TRUE,)
covid_conditions_tmp <- fhir_melt(covid_conditions_tmp,
                                  columns = c('code','display','system'),
                                  brackets = c('[',']'), sep = '|', all_columns = TRUE,)
 
# remove brackets from cells
covid_conditions_tmp <- fhir_rm_indices(covid_conditions_tmp, brackets = c("[", "]") )
 
# filter conditions by system = icd-10-gm
covid_conditions_tmp <- covid_conditions_tmp[covid_conditions_tmp$system == 'http://fhir.de/CodeSystem/dimdi/icd-10-gm',]
 
# remove duplicate patients
covid_conditions <- covid_conditions_tmp[!duplicated(covid_conditions_tmp$patient_id),]
 
# remove Patient/ from subject/reference and Encounter from encounter/reference
covid_conditions$patient_id <- sub("Patient/", "", covid_conditions[,5])
covid_conditions$encounter_id <- sub("Encounter/", "", covid_conditions[,6])
 
# separate patient_id into Airolo, Bapu, Cynthia institution_id
covid_conditions$institution_id <- unlist(strsplit(covid_conditions$patient_id,'-P-'))[ c(TRUE,FALSE) ]
 
# split code column in pri and sec code
covid_conditions$pri_code <- ifelse(nchar(covid_conditions$code)>6,sapply(strsplit(covid_conditions$code,' '), function(x) x[1]),covid_conditions$code)
covid_conditions$sec_code <- ifelse(nchar(covid_conditions$code)>6,sapply(strsplit(covid_conditions$code,' '), function(x) x[2]),'-')
 
# if necessary or wanted, filter by Airolo, Bapu, Cynthia, default: all data
#covid_conditions <- covid_conditions[grep('Airolo', covid_conditions$institution_id ),]
#covid_conditions <- covid_conditions[grep('Bapu', covid_conditions$institution_id ),]
#covid_conditions <- covid_conditions[grep('Cynthia', covid_conditions$institution_id ),]
  
# create the final data.frame with columns Einrichtungsidentifikator, AngabeDiagn1, AngabeDiagn2, AngabeGeschlecht, AngabeAlter, Anzahl
df_final <- as.data.frame(covid_conditions%>%group_by(Einrichtungsidentifikator=covid_conditions$institution_id,AngabeDiagn1=covid_conditions$pri_code,AngabeDiagn2=covid_conditions$sec_code,AngabeGeschlecht='-',AngabeAlter='-')%>%summarise(count=n()))
names(df_final)[names(df_final)== "count"] <- "Anzahl"
 
#make factors out of grouping variables to stop them from vanishing for zero counts
covid_conditions$code <- factor(covid_conditions$code)
covid_conditions$month <- factor(format(as.Date(covid_conditions$recorded_date), "%m"), levels = formatC(c(1:12), width=2, flag="0"))
 
#count codes per month
monthly_counts <- covid_conditions %>%
  group_by(month, code, .drop=F) %>%
  summarise(count=n())
 
#Plot
g <- ggplot(data=monthly_counts,aes(x=month, y=count))
g +
  geom_line(aes(group=code, color=code)) + #for the two codes
  stat_summary(aes(color="Sum"),fun= sum, geom ='line', group=1) + #for their sum
  scale_color_manual(breaks = c("Sum", "U08.9 U09.9!", "J12.8 U07.1!", "M30.3"), #optional for styling legend
                     values = c("#1B9E77", "#D95F02", "#7570B3", "#F12345")) +
  labs(title = 'Timeseries of Diagnoses',x='Month',y='Count',color ='Condition')
 
###############################################
write.csv(df_final,file= "df_final.csv")
###############################################s