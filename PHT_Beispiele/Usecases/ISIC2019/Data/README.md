# Data Preparation

Please follow the instructions to set up the environment to conduct the experiments.

## 1. Download ISIC2019 Dataset

The ISIC2019 dataset is available on Kaggle with the url: https://www.kaggle.com/andrewmvd/isic-2019. You could download the dataset manually from the website or use kaggle api. 

The following, we present the instructions of downloading the ISIC2019 dataset using kaggle api. 

1. Create a Kaggle account

2. Using pip (pip3 for python version 3) to install Kaggle API (we assume that python is pre-installed in your computer)

   ```bash
   pip install kaggle
   ```

3. Set up Kaggle     configuration on your computer

   1. Go to the 'Account' tab of your user profile (https://www.kaggle.com/USER_NAME/account) and select 'Create API Token' (Please replace the parameter USER_NAME with your own kaggle user name

   2. A file containing your API credentials will be downloaded (kaggle.json)

   3. Create a folder to store configuration file named “.kaggle”

      ```bash
      mkdir .kaggle
      ```

   4. Move the file to the created folder

      ```bash
      mv kaggle.json .kaggle/
      ```

   5. Grant read access to your credential file

      ```bash
      chmod 600 .kaggle/kaggle.json
      ```

4. Download the dataset

   ```bash
   kaggle datasets download andrewmvd/isic-2019
   ```

   If you run into a kaggle: command not found error, then use the following command

   ```bash
   ~/.local/bin/kaggle datasets download andrewmvd/isic-2019
   ```

## 2. Upload ISIC2019 Metadate to FHIR server

### Install Blaze FHIR server
We use Blaze FHIR server to store patient's metadata. 

Please find the instuctions of installation on the Blaze github repository with the url https://github.com/samply/blaze.

Docker example:
```bash
docker volume create blaze-data
docker run -d -p 8080:8080 -v blaze-data:/app/data -e BASE_URL=http://menzel.informatik.rwth-aachen.de:8080 --name blaze-latest samply/blaze:0.9.0-alpha.14 
```

### Upload FHIR Resources
We use Blazectl to upload FHIR Resources.

Please find the instuctions of installation on the Blazectl github repository with the url https://github.com/samply/blazectl.

```bash
blazectl upload --server http://menzel.informatik.rwth-aachen.de:8080/fhir output
```


## 3. Upload Images to MinIO server


## Useful Links
https://github.com/samply/blaze

https://github.com/samply/blazectl

https://hub.docker.com/r/samply/blaze

https://alexanderkiel.gitbook.io/blaze/deployment/environment-variables