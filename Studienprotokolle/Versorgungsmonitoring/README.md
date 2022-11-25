# Script to calculate the aggregate of patients corresponding to Versorgungsmonitoring based on new tracer diagnosis list


### 1. clone repository and checkout branch cf_script

```
git clone --branch cf_script https://github.com/medizininformatik-initiative/usecase-cord-support.git

cd usecase-cord-support/Studienprotokolle/Versorgungsmonitoring/
```

### 2. create your custom config yaml file by copying from 'conf_yml_sample.yml' to 'conf.yml' file. The following command in the code block will do that for you.
   1. Then edit the conf.yml file with parameters correspoding to your Institution like hospital name, areacode, location identfier system and then save it <br>
  2. If value for a parameter is not available in your FHIR Server for example inpatient parameter does not have a value called 'stationaer', then you can set it to NULL (inpatient: NULL) <br>
  3. If parameter 'department_identifier' is not availble then you can set it to '' like in conf_yml_sample2.yml <br>
```
cp conf_yml_sample.yml conf.yml
```



### 3. start calculation
```
Rscript Versorgungsmonitoring.R
```

## Spot Test

### Pre-requisite
   Docker installed 

### 4. unzip the Stichprobe file
 1. after cloning the repository, inside Versorgungsmonitoring folder you can find a zip file named as 'Stichprobe.zip', unzip the Stichprobe.zip file
 2. then, navigate to the Stichprobe folder using the following command

```
cd usecase-cord-support/Studienprotokolle/Versorgungsmonitoring/Stichprobe
``` 

3. after navigating to the Stichprobe folder, there should be a config folder, docker-compose.yaml file, runscript_1234.sh file and a Versorgungsmonitoring.r file available
 4. from Stichprobe folder execute the following command
```
docker-compose up
``` 
5. Wait for few minutes, then try to access http://localhost:3838/  on a webbrowser. If an interface with title 'CORD Schaufenster Visualisierung' is visible then your setup and parameters from config folders are correctly configured in test. You can make use of these configurations to create your own conf.yml file in Versorgungsmonitoring folder. If not then your Docker installation is not correct please contact your admin team and get docker installed



