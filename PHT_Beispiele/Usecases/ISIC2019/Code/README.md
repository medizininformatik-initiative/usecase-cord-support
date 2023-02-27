# ISIC2019 Statistical Analysis and Image Analysis

We use Docker to containerise the analysis tasks.

For statistical analysis, using the following commands to build a Docker image and execute the analysis task.
```bash
cd statistical_analysis
docker build -t pht-stat-train .
docker run --name pht-stat -e FHIR_SERVER=menzel.informatik.rwth-aachen.de -e FHIR_PORT=8080 pht-stat-train
```

For image analysis, using the following commands to build a Docker image and execute the analysis task.
```bash
cd image_classification
docker build -t pht-img-train . 
docker run --name pht-img -e FHIR_SERVER=menzel.informatik.rwth-aachen.de -e FHIR_PORT=8080 pht-img-train
```