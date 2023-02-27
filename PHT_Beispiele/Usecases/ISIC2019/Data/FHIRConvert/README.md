# Convert ISIC2019 Patient's metadata to FHIR resources

## Preparing data in suitable format
* input: ISIC patient metadata (Reads CSV files from the input directory)
* output: Transaction json(s) - Ready to upload into the FHIR server
* params: batch size and MinIO server base url

For each patient, will generate two entries. The first one is related to patient details (id, birth date, and gender). The second entry is related to the corresponding image information. 
We are keeping the "anatom_site_general" field in the "bodySite" attribute and "lesion_id" filed in "reasonCode" attribute, that are defined in the FHIR structure. (https://www.hl7.org/fhir/media.html)

The "BATCH_SIZE" as an input parameter defines the number of entries in each transaction. So it will be more practical to upload the data into the FHIR server in several transactions.
There is also another parameter. It is the address of the MINIO server.

## Usage

```
node convert.js 500 "http://menzel.informatik.rwth-aachen.de:8080/isic/"
```