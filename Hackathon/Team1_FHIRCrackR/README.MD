# Team 1: FHIRCrackR

## How to use R script

Install 3 Packages

`install.packages('fhircrackr') #requires R (>= 4.0.0)`
`install.packages('digest')`
`install.packages('config')`

Copy example config file

`cp config/conf-example.yml config/conf.yml`

Values that need to be adjusted in conf.yml
- 'serverbase': local fhir server
- 'center_name': name of the local center for rare diseases
- 'center_zip': postal code / zip of the local center for rare diseases
- 'username': Your username for your local fhirserver authentification
- 'password': Your password for your local fhirserver authentification

## Caution: leave last line in conf.yml empty