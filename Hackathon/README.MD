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
    2. in the config folder use conf-example.yml and create a new file and name it 'conf.yml' 
    3. in conf.yml file created from the previous step (2 ii) modify the serverbase to your FHIR store url, hospital_name and hospital_zip
    4. if your FHIR store is secured with credentials then please modify the conf.yml file according to instructions in conf-example.yml file
3. to run dcoker compose file you need docker and docker compose to be installed in your machine
    1. to download and execute docker images use the following command 
        ```
        docker-compose up -d
    2. to shutdown and remove the containers 
        ``` 
        docker-compose down
4. if all the input parameters from conf.yml are available then step 3a might take a while to download the docker images. After succesfull execution of script aggregation csv files from 1 to 7 will be available in data folder.
5. the results from visualization script are made accessible in visualization.pdf file
