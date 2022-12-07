# Script to calculate the aggregate of patients corresponding to Versorgungsmonitoring based on new tracer diagnosis list

# Table of Contents 

A. [To understand RCode behind Versorgungsmonitoring usecase](https://github.com/medizininformatik-initiative/usecase-cord-support/tree/cf_script/Studienprotokolle/Versorgungsmonitoring#spot-test)

B. [To Carry out Spot Test for docker (Recommended)](https://github.com/medizininformatik-initiative/usecase-cord-support/tree/cf_script/Studienprotokolle/Versorgungsmonitoring#spot-test)

C. To calculate the aggregate corresponding to Versorgungsmonitoring needed for Data management team 

## A. To understand RCode behind Versorgungsmonitoring usecase
### 1. clone repository and checkout branch cf_script

```
git clone --branch cf_script https://github.com/medizininformatik-initiative/usecase-cord-support.git

cd usecase-cord-support/Studienprotokolle/Versorgungsmonitoring/
```

### 2. create your custom config.yaml file by copying from 'conf_yml_sample.yml' to 'conf.yml' file. The following command in the code block will do that for you.
   ```
cp conf_yml_sample.yml conf.yml
```
   1. Then edit the conf.yml file with parameters correspoding to your Institution like FHIR server name, hospital name, areacode, location identfier system, diagnosis from date, diagnosis to date, subject reference prefix etc  and then save it <br>
  2. If value for a parameter is not available in your FHIR Server, for example inpatient parameter does not have a value called 'stationaer', then you can set it to NULL (inpatient: NULL) <br>
  3. If parameter 'department_identifier' is not availble then you can set it to '' like in conf_yml_sample2.yml <br>



### 3. start calculation
```
Rscript Versorgungsmonitoring.R
```

## B. To Carry out Spot Test for docker (Recommended)

### Pre-requisite
   Docker installed 

### 4. unzip the Stichprobe file
 1. After cloning the repository, inside Versorgungsmonitoring folder you can find a zip file named as 'Stichprobe.zip'. Unzip the Stichprobe.zip file
 2. Then, navigate to the Stichprobe folder using the following command

```
cd usecase-cord-support/Studienprotokolle/Versorgungsmonitoring/Stichprobe
``` 

3. After navigating to the Stichprobe folder, there should be a config folder, docker-compose.yaml file, runscript_1234.sh file and a Versorgungsmonitoring.r file available
 4. from Stichprobe folder execute the following command
```
docker-compose up
``` 
5. Wait for few minutes for the docker  container to start, then try to access http://localhost:3838/  on a webbrowser. If an interface with title 'CORD Schaufenster Visualisierung' is visible then your setup and parameters from config folders are correctly configured in test. You can make use of these configurations to create your own conf.yml file in Versorgungsmonitoring folder. If not then your Docker installation is not correct please contact your admin team and get docker installed

6. after spot test, execute the following command
```
docker-compose down
``` 

## C. To calculate the aggregate corresponding to Versorgungsmonitoring based on new tracer diagnosis list using docker Version and provide result to datamanagement team

### Pre-requisite
   Docker installed  

### 1. clone repository 
1.  clone the repository and checkout branch cf_script

```
git clone --branch cf_script https://github.com/medizininformatik-initiative/usecase-cord-support.git

cd usecase-cord-support/Studienprotokolle/Versorgungsmonitoring/
```

### 2. create a new folder named 'config' inside Versorgungsmonitoring folder and then create a 'conf.yaml' file by copying the 'conf_yml_sample.yml'. The conf.yml file should belocated inside the 'config' folder. The following command in the code block will do that for you.

   ```
     cp conf_yml_sample.yml config/conf.yml
   ```
   
   2. Then edit the conf.yml file with parameters correspoding to your Institution like FHIR server name, hospital name, areacode, location identfier system, diagnosis from date, diagnosis to date, subject reference prefix and then save it <br>


   3. If value for a parameter is not available in your FHIR Server, for example if inpatient parameter does not have a value called 'stationaer', then you can set it to NULL (inpatient: NULL) <br>

   4. For setting the parameter correspoding to your institution/location you can contact @rajesh-murali

   
### 3. start calculation
   
   5. After creating a config folder with conf.yml file, navigate back to Versorgungsmonitoring folder (from config folder that you just created  usecase-cord-support/Studienprotokolle/Versorgungsmonitoring/Config) execute the following command
   ```
      cd ..
   ```

   6.  Now from Versorgungsmonitoring folder run the docker compose using the following command (before this step config/conf.yml file must be available inside folder  usecase-cord-support/Studienprotokolle/Versorgungsmonitoring/)

   ```
      docker-compose up
   ```

   7.  Wait for few minutes for the docker container to start, then try to access http://localhost:3838/  on a webbrowser. An interface with title 'CORD Schaufenster Visualisierung' should be available. 
   On this user interface, there is a button named 'Download data.zip' made available for you. To download the results in a zip file named 'data.zip' click on this 'Download data.zip' button

   8. unzip 'data.zip' file. After successful execution contact @rajesh-murali datamanagement team corresponding to usecase 4 

   ## Changelog

   ### Changes to support birthdate that conatins only year (in YYYY format)

   If the birthdate of a patient is in 'YYYY' format in Patient Resource of FHIR server then it had to changed to 'YYYY-MM-DD' format otherwise following error will occur while computing the age of the pattient 
```
      Error in charToDate(x):
           character string is not in standard unambiguous format
            Calls: as.Date -> as.Date.character -> charToDate
            Execution halted.
   ```
   ### Solution to convert format from 'yyyy' to 'yyyy-mm-dd'
   To convert birthdate from 'yyyy' to 'yyyy-mm-dd' format, use the following command 
     ```
      df_conditions_patients <- df_conditions_patients %>% mutate(birthdate= ifelse(nchar(birthdate) >=10, birthdate, paste0(birthdate, "-01-01")))
   ```

