# Table of Contents 
Im Hackathon, der Ablage Untergliederung Von Aufgaben werden

1. [Cracken der FHIR-Ressourcen zu einer Rechtecktabelle](./Team1_FHIRCrackR/)

2. [Berechnen von Entfernungen zur Klinik](./Team2_Distance/) 

3. [Aggregation der Detaildaten](./Team3_Aggregation/)

4. [Visualisierung der aggregierten Ergebnisse](./Team4_Geoviz/)

## Tracer Diagnose list 
[Tracer Diagnose list mit ICD_10GM Code](https://zmi.uniklinikum-dresden.de/confluence/download/attachments/79997703/Tracerliste_f%C3%BCr_Schaufenster.xlsx?version=1&modificationDate=1610533779949&api=v2)

## To begin 
1. clone the repository using git clone https://github.com/medizininformatik-initiative/usecase-cord.git
2. then navigate to Hackathon directory 
    1. inside the hackathon repository navigate to config folder. 
    2. in the config folder make use of conf-example.yml and create a new file with values corresponding to your location and name it 'conf.yml'. For help contact @rajesh-murali 
    3. in conf.yml file created from the previous step (2 ii) modify the serverbase to your location specific FHIR store url, hospital_name and hospital_zip
    4. if your FHIR store is secured with credentials then please modify the conf.yml file according to instructions in conf-example.yml file
3. to run docker compose file you need docker and docker compose to be installed in your machine
    1. to download and execute docker images use the following command 
        ```
        docker-compose up -d
    2. to shutdown and remove the containers 
        ``` 
        docker-compose down
4. if all the input parameters from conf.yml are available then step 3a might take a while to download the docker images. After succesfull execution of script aggregation csv files from 1 to 7 will be available in data folder.
5. the results from visualization script are made accessible in visualization.pdf file

#### Workaround <br/>
*Pre-requisite: <br/>
Apply the following step if you obtain the data using SQL queries on your datawarehouse and not from FHIR server. In this case you manually create cracked_result.csv file.* <br/>
1. *If you already have the result of FHIRCrackR step in cracked_result.csv file in the desired format with following columns* 
   ```  
   patient_id;age;gender;hospital_name;hospital_zip;patient_zip;diagnosis
   ```
  *then place the file inside the data folder. This is the location of the volume from where the container can read your cracked_result.csv file.* <br/>
2. *after that uncomment the line number 11 in docker-compose.yml file. This action will enable the container to manually read the cracked_result.csv file from data folder and provide it to subsequent steps.*

## Execution on Docker Desktop for Windows <br/>


In order to execute the Scripts in Docker Desktop for windows the following pre-requisites must be fullfilled <br/>

*Pre-requisites for Windows Operatingsystem version 10:* <br/>
1. Docker desktop on windows from version 2.5.3 <br/>

2. Administrator rights on Power shell or command prompt <br/>

3. After docker desktop installation docker desktop for windows must be in running status indicated by the green circle <br/>

4. Git  <br/>

5. If proxy is required, you can provide your appropriate proxy parameter with the Web Server (HTTP) parameter as well as with the Secure Web Server (HTTPS) parameters in the Docker Desktop for Windows settings menu. Access the settings menu by right clicking on the whale icon present in the System Tray and choose settings. In the settings menu set the proxies for HTTP and HTTPS parameter <br/>

#### Steps <br/>

1. Open the command prompt or windows power shell using administrator rights <br/>

2. then clone the Github repository using: <br/>
 ```  
   git clone https://github.com/medizininformatik-initiative/usecase-cord.git
   ```
3. navigate to the config folder inside the downloaded respository. Copy the `conf-example.yml` file and create a new file with values corresponding to your location and name it as `conf.yml`. <br/>

4. in conf.yml file created from the previous step (3) modify the serverbase to your location specific FHIR store url, hospital_name and hospital_zip <br/>

5. if your FHIR store is secured with credentials then please modify the `conf.yml` file with appropriate credentials according to instructions in conf-example.yml file <br/>

6. then in the command prompt or in the power shell navigate to the downloaded folder using the `cd` change directory command. Inside this folder `docker-compose.yml` file must be located<br/>

7. then to start the container type the following command `docker-compose up` <br/>

8. after that you can access the front end from `http://localhost:3838`<br/>
