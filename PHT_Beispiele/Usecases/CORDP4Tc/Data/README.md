## Prepare Local HAPI FHIR Server
### Run HAPI FHIR Server in Docker
```bash
   docker run -d -p [PORT]:8080 -v hapi-data:/data/hapi --name hapi hapiproject/hapi:latest
```
### Download Data from Leipzig FHIR Server (https://mii-agiop-cord.life.uni-leipzig.de)
`download.py` reads data from Leipzig's FHIR and stores data in JSON files. It gets one variable as an input argument (`ORG_NAME`).
`ORG_NAME` specifies which dataset should be download (python code filters data based on ORG_NAME). `ORG_NAME` can be one of these values, `Airolo`, or `Bapu`, or `Cynthia`.
```bash
   python3 download.py [ORG_NAME] 

   # Exapmle
   python3 download.py Airolo
```
### Upload Data into a Target FHIR Server
Once the data download is complete, use `upload.py` to upload the data into a target FHIR server.
`upload.py` reads JSON files from the output directory and saves them in the target FHIR server. It gets three variables as input arguments (including `IP`, `PORT`, and `ORG_NAME`).
`IP` address and `PORT` number define the target FHIR server endpoint where the data is to be imported. The `IP` address should be set based on your machine settings, and the `PORT` number is the number that is specified in the previous step.
`ORG_NAME` specifies which dataset should be imported (python code filters data based on ORG_NAME). Like the previous step, `ORG_NAME` can be one of these values, `Airolo`, or `Bapu`, or `Cynthia`.
```bash
   python3 upload.py [IP] [PORT] [ORG_NAME] 

   # Example
   python3 upload.py 127.0.0.1 8080 Airolo
```
### NOTE
[fhirpy](https://github.com/beda-software/fhir-py) library needs to be installed.
```bash
   pip install fhirpy
```


