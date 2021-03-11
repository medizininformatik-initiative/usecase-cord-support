############################################################################################################################
##         Zur Alterspyramid zu rechnen
##############################################################################################################################
library(tidyverse)
library(eeptools) # um Alter zu berechnen
library(ggplot2)# für muster age pyramid
options(warn=-1)# warnung ausblenden
#############################################################################################################
# Fügen Sie die Eingabedaten zu Ihrem aktuellen Arbeitsverzeichnis hinzu und geben Sie den Pfad an
###########################################################################################################################################
#Input von andere Team _Condition_code=E84.0,E84.1,E84.80,E84.87,E84.88,E84.9,O80_2021-03-03_15-25-58
#data <- read.csv("r/projectathon/filename.csv")
###############################################################################################################
data <- read.csv("c:\\users\\yourusername\\Downloads\\input_data.csv")# aus projektbereich ordner

# Eleminiere doppelte Patienten
data <- data %>% distinct(PatientIdentifikator, AngabeDiag1, .keep_all = TRUE)
data$PatientIdentifikator <- NULL

# Berechne Alter auf der grund von Geburtsdatum
data$AngabeAlter <- floor(age_calc(as.Date(data$AngabeGeburtsdatum), unit="years"))
data$AngabeGeburtsdatum <- NULL

# Teile in Altersgruppen ein
data$AngabeAlter <- cut(data$AngabeAlter, breaks = c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120))

# Gruppiere
result  <- as.data.frame(data %>%
						 	group_by(Einrichtungsidentifikator, AngabeDiag1, AngabeGeschlecht, AngabeAlter) %>%
						 	summarise(Anzahl = n()))

# Entferne nicht benoetigte Spalten
result$TextDiagnose1 <- NULL
result$TextDiagnose2 <- NULL
result$AngabeDiag2 <- NULL

write.csv(result, "r/projectathon/result.csv")

################## Um der Alterspyramid zu rechnen######################################################################
# Nehmen wir Geschlechht, Alter, Anzahl
############################################################################################################################
stratified <- result[,c('AngabeGeschlecht','AngabeAlter','Anzahl')]
stratified_female <- (data = stratified %>% subset(AngabeGeschlecht=="f"))
stratified_male <- (data = stratified %>% subset(AngabeGeschlecht=="m")) %>% transform(Anzahl = (data = stratified %>% subset(AngabeGeschlecht=="m"))$Anzahl * -1 )
stratified_wide <- rbind(stratified_female,stratified_male)

#Abkuerzung ändern statt "f", "female" und statt "m" "male" verwenden
stratified_wide$AngabeGeschlecht [stratified_wide$AngabeGeschlecht == "f"] <- "female"
stratified_wide$AngabeGeschlecht [stratified_wide$AngabeGeschlecht == "m"] <- "male"

#Labellen name als angabe
names(stratified_wide)[names(stratified_wide)== "AngabeAlter"] <- "ageG"
names(stratified_wide)[names(stratified_wide)== "Anzahl"] <- "Count"
names(stratified_wide)[names(stratified_wide)== "AngabeGeschlecht"] <- "gender"

#Alterspyramid kozipieren
g <- ggplot(stratified_wide,aes(x=Count,y=ageG,fill=gender))
g + geom_bar(stat="identity")

