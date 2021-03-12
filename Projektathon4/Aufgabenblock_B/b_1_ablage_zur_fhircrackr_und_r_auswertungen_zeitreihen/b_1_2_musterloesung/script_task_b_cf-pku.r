library(fhircrackr)
library(tidyverse)
library(ggplot2)

search_request <- paste0(
  'https://mii-agiop-cord.life.uni-leipzig.de/fhir/',
  'Condition?',
  'code=E70.0,E70.1,E84.0,E84.1,E84.8,E84.80,E84.87,E84.88,E84.9',
  '&_include=Condition:subject'
)

# define design 
design <- list(
  Conditions = list(
    resource = "//Condition",
    cols = list(
      condition_id = "id",
      code = "code/coding/code",
      display = "code/coding/display",
      text = "code/text",
      system = "code/coding/system",
      patient_id = "subject/reference",
      encounter_id = "encounter/reference",
      recorded_date = "recordedDate",
      onset_period_start = "onsetPeriod/start",
      onset_period_end = "onsetPeriod/end"
    ),
    style = list(
      sep="|",
      brackets = c("[", "]"),
      rm_empty_cols = FALSE
    )
  ),
  Patients = list(
    resource = "//Patient",
    cols = list(
      patient_id = "identifier/value",
      name_use = "name/use",
      name_family = "name/family",
      name_given = "name/given",
      gender = "gender",
      birthdate = "birthDate"
    ),
    style = list(
      sep="|",
      brackets = c("[", "]"),
      rm_empty_cols = FALSE
    )
  ) 
)

# download fhir bundles
bundles <- fhir_search(request = search_request, max_bundles = 50,verbose =2,log_errors = 2)

# crack fhir bundles
dfs <- fhir_crack(bundles, design)

# save raw patients dataframe
patients_raw <- dfs$Patients

# unnest raw patients dataframe columns name/use and name/family
patients_tmp <- fhir_melt(patients_raw,
                          columns = c('name_use','name_family'),
                          brackets = c('[',']'), sep = '|', all_columns = TRUE,)

# remove brackets from cells
patients_tmp <- fhir_rm_indices(patients_tmp, brackets = c("[", "]") )

# filter by official name/use
patients_tmp <- patients_tmp[patients_tmp$name_use == 'official',]

# calculate age in years by birthdate
patients_tmp$age <- round( as.double( as.Date( Sys.time() ) - as.Date( patients_tmp$birthdate ) ) / 365.25, 2 )

# remove duplicate patients
patients <- patients_tmp[!duplicated(patients_tmp$patient_id),]

# save raw conditions dataframe
conditions_raw <- dfs$Conditions

# unnest raw conditions dataframe columns code/coding/code, code/coding/display, code/coding/system
conditions_tmp <- fhir_melt(conditions_raw,
                            columns = c('code','display','system'),
                            brackets = c('[',']'), sep = '|', all_columns = TRUE,)
conditions_tmp <- fhir_melt(conditions_tmp,
                            columns = c('code','display','system'),
                            brackets = c('[',']'), sep = '|', all_columns = TRUE,)

# remove brackets from cells
conditions_tmp <- fhir_rm_indices(conditions_tmp, brackets = c("[", "]") )

# filter conditions by system = icd-10-gm
conditions_tmp <- conditions_tmp[conditions_tmp$system == 'http://fhir.de/CodeSystem/dimdi/icd-10-gm',]

# remove duplicate patients
conditions <- conditions_tmp[!duplicated(conditions_tmp$patient_id),]

# remove Patient/ from subject/reference and Encounter from encounter/reference
conditions$patient_id <- sub("Patient/", "", conditions[,6])
conditions$encounter_id <- sub("Encounter/", "", conditions[,7])

# separate patient_id into Airolo, Bapu, Cynthia institution_id
conditions$institution_id <- unlist(strsplit(conditions$patient_id,'-P-'))[ c(TRUE,FALSE) ]

# merge all patients and conditions data by patient_id
df_merged <- merge(patients, conditions, by = "patient_id")

# if necessary or wanted, filter by Airolo, Bapu, Cynthia, default: all data
#df_merged <- df_merged[grep('Airolo', df_merged$patient_id),]
#df_merged <- df_merged[grep('Bapu', df_merged$patient_id),]
#df_merged <- df_merged[grep('Cynthia', df_merged$patient_id),]

# prefinal dataframe with relevant columns
df_result <- df_merged[,c('institution_id','code','display','text','gender','age')]

# rename gender values
df_result$gender [df_result$gender == "female"] <- "f"
df_result$gender [df_result$gender == "male"] <- "m"
df_result$gender [df_result$gender == ""] <- "NA"

# split into specific age groups
x <- c(1,10,20,30,40,50,60,70,80,90,999)
df_result$age <- cut(df_result$age,x,breaks= c(0,10,20,30,40,50,60,70,80,90,999), labels = c("(1,10]","(11,20]", "(21,30]", "(31,40]", "(41,50]", "(51,60]","(61,70]","(71,80]","(81,90]", "(91,999]"))

# create the final data.frame with columns Einrichtungsidentifikator, AngabeDiagn1, AngabeDiagn2, AngabeGeschlecht, AngabeAlter, Anzahl
df_final <- as.data.frame(df_result%>%group_by(Einrichtungsidentifikator=df_result$institution_id,AngabeDiagn1=df_result$code,AngabeDiagn2="NA",AngabeGeschlecht=df_result$gender,AngabeAlter=df_result$age)%>%summarise(count=n()))
names(df_final)[names(df_final)== "count"] <- "Anzahl"

# group codes
E84 <- c('E84.0','E84.1','E84.8','E84.80','E84.87','E84.88','E84.9')
E70 <- c('E70.0', 'E70.1')

# extract Patient ID and Month for all patients, patients with E84.x and patients with E70.0 and E70.1 from DataSet
pat_month <- data.frame(PID=df_merged$patient_id,month = format(as.Date(df_merged$recorded_date),'%m'))
pat_month1 <- data.frame(PID=df_merged[df_merged$code %in% E84,]$patient_id,CF = format(as.Date(df_merged[df_merged$code %in% E84,]$recorded_date),'%m'))
pat_month2 <- data.frame(PID=df_merged[df_merged$code %in% E70,]$patient_id,PKU = format(as.Date(df_merged[df_merged$code %in% E70,]$recorded_date),'%m'))

# order data regarding month
pat_month <- pat_month[order(pat_month$month),]
pat_month1 <- pat_month1[order(pat_month1$CF),]
pat_month2 <- pat_month2[order(pat_month2$PKU),]

# counts occurrences of patients per month
tmp_table <- as.data.frame(table(month=pat_month$month))
tmp_table1 <- as.data.frame(table(month=pat_month1$CF))
tmp_table2 <- as.data.frame(table(month=pat_month2$PKU))

# create month vector with 01,02...11,12
month_vec <- data.frame(month=formatC(c(1:12), width=2, flag="0"))

#join month vector with tmp_table, 1 and 2 and set column names
tmp_table <- left_join(month_vec,tmp_table, by='month')
tmp_table <- left_join(tmp_table,tmp_table1, by='month')
tmp_table <- left_join(tmp_table,tmp_table2, by='month')
colnames(tmp_table) = c('month', 'summe', 'CF','PKU')

# fill temp_df with 0s if no occurrence exists in a month 
tmp_table[is.na(tmp_table)] <- 0

# plot time series with one data frame (merged by multiple different data frames) 
i <- ggplot2::ggplot(tmp_table, aes(month,group=1))
i+geom_line(aes(y=CF,color='CF',group=1))+geom_line(aes(y=PKU,color='PKU',group=1))+labs(title = 'Timeseries of Diagnoses',x='Month',y='Count',color ='Condition')

################################################
write.csv(df_final,file= "df_final.csv")
###############################################