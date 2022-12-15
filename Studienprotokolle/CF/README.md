# Script to calculate the aggregate of patients corresponding to Mukoviszidose/CF Cystic Fibrosis and Birth


### 1. clone repository

```
git clone https://github.com/medizininformatik-initiative/usecase-cord-support.git

cd usecase-cord-support/Studienprotokolle/CF/
```

### 2. create your custom config
```
cp conf.yml.sample conf.yml
```

### 3. edit your custom config
```
  serverbase:                 'https://mii-agiop-cord.life.uni-leipzig.de/fhir/'

  # set the name for your location
  hospital_name:              'YourCenter'

  # set custom reference prefix, default = "Patient/" & "Encounter/"
  subject_reference_prefix:   ''
  encounter_reference_prefix: ''

  # custom parameters for conditions resources on local fhir server
  # use 'http://fhir.de/CodeSystem/dimdi/icd-10-gm' or 'http://fhir.de/CodeSystem/bfarm/icd-10-gm' or custom
  icd_code_system:            'http://fhir.de/CodeSystem/dimdi/icd-10-gm'

  # uncomment, to load patients until 2021-12-31 (default 2019-12-31)
  #enddate:                   2021-12-31
```


### 4. start calculation
```
Rscript script_cf.r
```