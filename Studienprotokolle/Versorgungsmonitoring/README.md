<a name="readme-top"></a>
<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
         <a href="#a. to understand rcode behind versorgungsmonitoring usecase"> To understand RCode behind Versorgungsmonitoring usecase</a>
       <ul>
        <li><a href="#Clone">Clone respository</a></li>
        <li><a href="#Create">Create config.yml</a></li>
        <li><a href="#Start">Start Calculation</a></li>
      </ul>
    </li>
    <li>
      <a href="#Stich Probe">To carry out spot test for docker</a>
      <ul>
        <li><a href="#prerequisites">Pre-requisite</a></li>
        <li><a href="#unzip">Unzip the stichprobe file</a></li>
         <li><a href="#execute">Navigate to stichprobe folder and execute docker compose </a></li>
      </ul>
    </li>
     <li>
      <a href="#Aggregate">To calculate the aggregate of Versorgungsmonitoring </a>
      <ul>
        <li><a href="#prerequisites2">Pre-requisite</a></li>
        <li><a href="#cloneagg">Clone respository</a></li>
        <li><a href="#Createagg">Create config.yml</a></li>
         <li><a href="#Startagg">start calculation</a></li>
      </ul>
    </li> 
     <li><a href="#changelog">Changelog</a></li>
     <li><a href="#know-how">Know-how</a></li>
     <li><a href="#roadmap">Roadmap</a></li>
     <li><a href="#contact">Contact</a></li>
     <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>


# Script to calculate the aggregate of patients corresponding to Versorgungsmonitoring based on new tracer diagnosis list

# Table of Contents 

A. [To understand RCode behind Versorgungsmonitoring usecase](https://github.com/medizininformatik-initiative/usecase-cord-support/tree/cf_script/Studienprotokolle/Versorgungsmonitoring#spot-test)

B. [To Carry out Spot Test for docker (Recommended)](https://github.com/medizininformatik-initiative/usecase-cord-support/tree/cf_script/Studienprotokolle/Versorgungsmonitoring#spot-test)

C. To calculate the aggregate corresponding to Versorgungsmonitoring needed for Data management team 

<p align="right">(<a href="#readme-top">back to top</a>)</p>

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
   1. Then edit the conf.yml file with parameters correspoding to your Institution like FHIR server name, hospital name, areacode, location identfier system, diagnosis from date, diagnosis to date, subject reference prefix etc  and then save it. Please see the [know-how](https://github.com/medizininformatik-initiative/usecase-cord-support/tree/cf_script/Studienprotokolle/Versorgungsmonitoring/README.md#know-how) section on how to set the diagnosis from date and diagnosis to date using the recordedDate_fromcol and recordedDate_tocol parameter for recorded-date    <br>
  2. If value for a parameter is not available in your FHIR Server, for example inpatient parameter does not have a value called 'stationaer', then you can set it to NULL (inpatient: NULL) <br>
  3. If parameter 'department_identifier' is not availble then you can set it to '' like in conf_yml_sample2.yml <br>



### 3. start calculation
```
Rscript Versorgungsmonitoring.R
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

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

<p align="right">(<a href="#readme-top">back to top</a>)</p>

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

<p align="right">(<a href="#readme-top">back to top</a>)</p>

   ## Additional non-mandatory step to build docker image without using docker Compose yaml file
   1.  clone the repository, checkout branch cf_script and then navigate to the clonedrepository using the following command

   ```
    git clone --branch cf_script https://github.com/medizininformatik-initiative/usecase-cord-support.git
  
   cd usecase-cord-support/Studienprotokolle/Versorgungsmonitoring/
   ```

   2. build image using the following command 

   ```
    docker build -t cordversorgungsmonitoring .
   ```

   3. after successful image build step, set the parameters in config.yml file. This step is similar to the description in part B of the task as well as Part C of the task

   4. start the docker container using the following command

   ```
    docker run --name cordversorgungsmonitoring
   ```


   ## Changelog

   ### HTTP Code 503

   If the FHIR search query to your FHIRserver returned a HTTP code 503, then check your environment variables whether no_proxy parameter contains your FHIRserver fully qualified name as well as your FHIRserver IP address. This error is caused due to the network settings that is preventing access to your FHIR Server. In the server machine where you are executing this code, must enable permanent access to your FHIRserver. This is missing. By defining your environment variables from bash terminal, the environment variable setting is not saved permanently. It is only temporary and overridden by your server machine default settings and it will return HTTP Code 503.

   The following is an example of HTTPcode 503 error message

   ```
    Error in check_response(response = response, log_errors = log_errors) :
      Your request generated a server error, HTTP code 503. To print more detailed error information to a file, set argument log_errors to a filename and rerun fhir_search().
    Calls: fhir_search -> get_bundle -> check_response
    Execution halted
   ```
   Check whether you have your proxy server name with fully qualified name as well as IP address  correctly included in 'http_proxy' and 'https_proxy' variables in config.yml file. Check whether you can view the same variable names 'http_proxy', 'https_proxy' with same values from your config.yml file in your system environment variables as well

   ### Solution
   Set no_proxy system environment variable using the following line:

    ```
     Sys.setenv(no_proxy = '<your fully qualified FHIR Server name here>')
    ```
   
   In linux operating system, you can include the above line of code in Versorgungsmonitoring.R file.
   To have consistent environment variable settings, the environment variables must be defined in your bash profile file (.bashrc file)
   ### Changes to support birthdate that contains only year (in YYYY format)

   If the birthdate of a patient is in 'YYYY' format in Patient Resource of FHIR server then birthdate had to be changed to include 'YYYY-MM-DD' format. Otherwise following error will occur while computing the age of the patient 

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
<p align="right">(<a href="#readme-top">back to top</a>)</p>

   ## Know-how
   
   ### How to set the recorded-date parameter
   
   The recorded date parameter will provide a time frame filter for the fhir search. For example if you have data from 2019 till end of 2021 in your FHIR server then you can set the 'recordedDate_fromcol' and 'recordedDate_tocol' parmeter like as follows:
   
   ```  
     recordedDate_fromcol:        'ge2019-01-01' 
   ``` 
   and
   
   ```  
   recordedDate_tocol:          'le2021-12-31'
   ```
   
   ### Check country Code in Patient Resource

   The country code of Patient Resource in Germany is by default coded with two alphabets "DE". If in your FHIR server, in Patient resource if country code is coded differently then that particular code must be included in the Versorgungsmonitoring.R.

   default filter for country-code "DE" in line 162 of Versorgugsmonitoring.R is as follows:

   ``` 
    patients_tmp <- patients_tmp[(patients_tmp$countrycode == "DE")
   ```
    
   If country is coded with alphabet "D" in Patient resource, then the filter to accept country-code "D" as well must be included as follows:
   
   ``` 
   patients_tmp <- patients_tmp[(patients_tmp$countrycode == "DE") | (patients_tmp$countrycode == "D"), ]
   ``` 
   please contact [@rajesh.murali](rajesh.murali@uk-erlangen.de) if country is coded differently other than "DE" for Germany

   ### What actions does the docker container perform?
   
   The docker container at first executes the versorgungsmonitoring.r script then it executes the following scripts in order <br>
    
   [distance.r](https://github.com/medizininformatik-initiative/usecase-cord-support/blob/master/Hackathon/Team2_Distance/distance.r), <br>
   
   [cord-anonymization-v0.0.1.jar](https://github.com/medizininformatik-initiative/usecase-cord-support/blob/master/Hackathon/Team3_Aggregation/jars/cord-anonymization-v0.0.1.jar), <br>
   
   [visualization.Rmd](https://github.com/medizininformatik-initiative/usecase-cord-support/blob/master/Hackathon/Team4_Geoviz/visualization.Rmd)  

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->
## Roadmap

- [x] Add Changelog
- [x] Add dockerfile for building docker image manually
- [x] Add know-how
- [x] Add contact, acknowledgments back to top links


<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- CONTACT -->
## Contact

Your Name - [@rajesh.murali](rajesh.murali@uk-erlangen.de) 

Project Link: [https://forschen-fuer-gesundheit.de/projekt_cord_monitoring.php](https://forschen-fuer-gesundheit.de/projekt_cord_monitoring.php)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

This part of the task is created during the project "Collaboration on Rare Disease" (CORD) from Medical Informatics Initiative(MII). If you are using this code for any task kindly mention this source as well as the Project name CORD