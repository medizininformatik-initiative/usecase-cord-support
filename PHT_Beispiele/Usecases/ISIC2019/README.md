# MIE-2021
This repository provides all instructions and code for conducting experiments presented in the paper accepted in the 31st Medical Informatics Europe Conference (MIE2021). This repository contains three parts: data preparation, code for statistical analysis and image analysis, and the results. 

Recommended citation: Mou Y, Welten S, Jaberansary M, Yediel YU, Kirsten T, Decker S, Beyan O. "Distributed Skin Lesion Analysis Across Decentralised Data Sources." <i>Studies in health technology and informatics</i>. 2021 May 27;281:352-6.

## Data

We used the ISIC Challenge 2019 Dataset. The dataset and basic statistics about the dataset can be found here: https://www.kaggle.com/andrewmvd/isic-2019.

The metadata file for our FHIR server and sample images can be found in the [Data](./Data/README.md) folder.

## Used Components

We containerised our algorithm with Docker (https://www.docker.com). Further, every data provider has a Docker Engine in order to execute the dockerised algorithms.

For image provision, we used MinIO (https://min.io), which stores the ISIC2019 images.

For the patient's metadata, we used a Blaze FHIR Server (https://github.com/samply/blaze).

## FHIR Server Content Example

```javascript
{
	"id": "0001152-isic-image",
	"createdDateTime": "2020-07-01",
	"resourceType": "Media",
	"status": "completed",		
	"subject": {
		"reference": "Patient/0000000"
	},
	"encounter": {
		"reference": "ImagingStudy/isic"
	},
	"content": {
		"contentType": "image/jpeg",
		"url": "http://www.example.com/isic/0000000.jpg"
	},
	"bodySite": {
		"text": "head/neck"
	},
	"note": [
		{"text": "MEL"}
	]
}


{
	"gender": "female",
	"id": "0000000",
	"meta": {
		"profile": ["https://www.medizininformatik-initiative.de/fhir/core/StructureDefinition/Patient"]
	},
	"resourceType": "Patient",
	"birthDate": "1966-07-01"
}

```
