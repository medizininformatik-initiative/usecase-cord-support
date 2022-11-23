# Script to calculate the aggregate of patients corresponding to Versorgungsmonitoring based on new tracer diagnosis list


### 1. clone repository and checkout branch cf_script

```
git clone --branch cf_script https://github.com/medizininformatik-initiative/usecase-cord-support.git

cd usecase-cord-support/Studienprotokolle/Versorgungsmonitoring/
```

### 2. create your custom config yml file by copying from 'conf_yml_sample.yml' to 'conf.yml' file. The following command will do that for you.
#### 2.a Then edit the conf.yml file with parameters correspoding to your Institution like hospital name, areacode, location identfier system and then save it 
#### 2.b If value for a parameter is not available in your FHIR Server for example inpatient parameter does not have a value called 'stationaer', then you can set it to NULL (inpatient: NULL)
#### 2.c if parameter 'department_identifier' is not availble then yu can set it to NULL 
```
cp conf_yml_sample.yml conf.yml
```



### 3. start calculation
```
Rscript Versorgungsmonitoring.R
```