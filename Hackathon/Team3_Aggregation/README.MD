# Aggregation and anonymization for the CORD Schaufenster

The code only preserves up to two tracer diagnoses per patient. According to statistics from Mannheim, this preserves 97.5% of all tracer diagnoses.
Currently, diagnoses are selected based on lexicographic order (ascending order, first two diagnoses will be selected).

Aggregates implemented:

1. hospital_name;hospital_zip;age;gender;count
2. hospital_name;hospital_zip;bird_flight_distance;count
3. hospital_name;hospital_zip;diagnosis_1;diagnosis_2;count
4. hospital_name;hospital_zip;diagnosis_1;diagnosis_2;age;count
5. hospital_name;hospital_zip;diagnosis_1;diagnosis_2;gender;count
6. hospital_name;hospital_zip;diagnosis_1;diagnosis_2;bird_flight_distance;count
7. hospital_name;hospital_zip;diagnosis_1;diagnosis_2;patient_zip;count

The following generalization are applied to achieve k-anonymity with k=5:

1. Diagnosis: 3 digit ICD code
2. Age: age groups
3. Distance: distance interval
4. patient_zip: state level

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
