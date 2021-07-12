# Aggregation and anonymization for the CORD Schaufenster

The code only preserves up to two tracer diagnoses per patient. According to statistics from Mannheim, this preserves 97.5% of all tracer diagnoses.
Currently, diagnoses are selected based on lexicographic order (ascending order, first two diagnoses will be selected).

Aggregates implemented:

1. aggregation1.csv (breakdown by age group & gender): hospital_name, hospital_zip, age_group, gender, count
2. aggregation2.csv (breakdown by birdflight distance group): hospital_name, hospital_zip, bird_flight_distance_group, count
3. aggregation3.csv (breakdown by 3-digit ICD diagnosis): hospital_name, hospital_zip, diagnosis_icd3, count
4. aggregation4.csv (breakdown by 3-digit ICD diagnosis & age group): hospital_name, hospital_zip, diagnosis_icd3, age_group, count
5. aggregation5.csv (breakdown by 3-digit ICD diagnosis & gender): hospital_name, hospital_zip, diagnosis_icd3, gender, count
6. aggregation6.csv (breakdown by 3-digit ICD diagnosis & birdflight distance group): hospital_name, hospital_zip, diagnosis_icd3, bird_flight_distance_group, count
7. aggregation7.csv (breakdown by state & 3-digit ICD diagnosis): hospital_name, hospital_zip, state, diagnosis_icd3, count

# How to run

Move to the team 4 folder and execute:

java -jar jars/cord-anonymization-v0.0.1.jar config/data.csv

# Input file format

The input file needs to have the following columns (in this order from left to right):

1. patient_id
2. age
3. gender
4. hospital_name
5. hospital_zip
6. patient_zip
7. diagnosis
8. bird_flight_distance
9. route_distance

Gender needs to be encoded as "male", "female", "unknown" or "other" (see FHIR).
For the exact format, please take a look at the example dataset located in config/data.csv
