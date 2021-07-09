# Aggregation and anonymization for the CORD Schaufenster

The code only preserves up to two tracer diagnoses per patient. According to statistics from Mannheim, this preserves 97.5% of all tracer diagnoses.
Currently, diagnoses are selected based on lexicographic order (ascending order, first two diagnoses will be selected).

Aggregates implemented:

* Aggregatgruppe 1: alle Patienten mit SE-Diagnose, aber ohne Diagnose (nur Betrachtung von Altersgruppen, Geschlecht, Entfernungskategorien)
Aggregat 1.1: Name Zentrum, PLZ Zentrum, Altersgruppe, Anzahl
Aggregat 1.2: Name Zentrum, PLZ Zentrum, Geschlecht, Anzahl
Aggregat 1.3: Name Zentrum, PLZ Zentrum, Entfernungskategorie, Anzahl
Aggregat 1.4: Name Zentrum, PLZ Zentrum, Altersgruppe, Geschlecht, Anzahl

* Aggregatgruppe 2: Fokus auf einzelne Diagnosen
Wie Aggregate 1, aber ergänzt um Diagnose (vergröbert, z.B. 3-Steller oder Gruppe)

* Aggregatgruppe 3: Fokus auf Wohnort & Diagnose
Wie Aggregate 2, aber ergänzt um Bundesland des Wohnorts

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
