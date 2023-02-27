import os
import sys
import json
import uuid
from fhirpy import SyncFHIRClient

def get_resource_model(resource_type, id):
    resource_model = {
        "fullUrl": str(uuid.uuid4()),
        "request": {
            "method": "PUT",
            "url": "{}/{}".format(resource_type, id)
        },
        "resource": {}
    }
    return resource_model

# FHIR server api
fhir_addr_source = 'http://mii-agiop-cord.life.uni-leipzig.de/fhir'

# Organizaition Name: 'Airolo' or 'Bapu' or 'Cynthia'
org_name = sys.argv[1]

print(org_name)

# Create an instance
fhir_client_source = SyncFHIRClient(fhir_addr_source)
        
path_to_json = "./output/{}".format(org_name)
if not os.path.exists(path_to_json):
    os.makedirs(path_to_json)

transaction_json = []
counter = 1

# Organization
organizations = fhir_client_source.resources('Organization')
for organization in organizations:
    if(org_name in organization.id):
        print(organization.id)
        organization_data = organization.serialize()
        resource_model = get_resource_model('Organization', organization.id)
        resource_model['resource'] = organization_data
        transaction_json.append(resource_model)
        outputPath = '{}/transaction_{}.json'.format(path_to_json, counter)
        with open(outputPath, 'w') as fp:
            json.dump(transaction_json, fp)

# Patients
transaction_json = []
counter = counter+1
patients = fhir_client_source.resources('Patient').limit(500)
for patient in patients:
    if(org_name in patient.id):
        print(patient)
        patient_data = patient.serialize()  
        resource_model = get_resource_model('Patient', patient.id)
        resource_model['resource'] = patient_data
        transaction_json.append(resource_model)
        if(len(transaction_json) == 500):
            outputPath = '{}/transaction_{}.json'.format(path_to_json, counter)
            with open(outputPath, 'w') as fp:
                json.dump(transaction_json, fp)
            transaction_json = []
            counter = counter+1

outputPath = '{}/transaction_{}.json'.format(path_to_json, counter)
with open(outputPath, 'w') as fp:
    json.dump(transaction_json, fp)
transaction_json = []  

# Observation
transaction_json = []
counter = counter+1
print(counter)
resources = fhir_client_source.resources('Observation').limit(500)
for resource in resources:
    if(org_name in resource.subject.reference):
        print(resource)
        resource_data = resource.serialize()  
        resource_data.id = '{}-{}'.format(resource_data.id,org_name)
        resource_model = get_resource_model(resource.resourceType, resource_data.id)
        resource_model['resource'] = resource_data
        transaction_json.append(resource_model)
        if(len(transaction_json) == 500):
            outputPath = '{}/transaction_{}.json'.format(path_to_json, counter)
            with open(outputPath, 'w') as fp:
                json.dump(transaction_json, fp)
            transaction_json = []
            counter = counter+1

outputPath = '{}/transaction_{}.json'.format(path_to_json, counter)
with open(outputPath, 'w') as fp:
    json.dump(transaction_json, fp)
transaction_json = []  

# Encounter
transaction_json = []
counter = counter+1
print(counter)
resources = fhir_client_source.resources('Encounter').limit(500)
for resource in resources:
    if(org_name in resource.id):
        print(resource)
        resource_data = resource.serialize()  
        resource_model = get_resource_model(resource.resourceType, resource_data.id)
        resource_model['resource'] = resource_data
        transaction_json.append(resource_model)
        if(len(transaction_json) == 500):
            outputPath = '{}/transaction_{}.json'.format(path_to_json, counter)
            with open(outputPath, 'w') as fp:
                json.dump(transaction_json, fp)
            transaction_json = []
            counter = counter+1

outputPath = '{}/transaction_{}.json'.format(path_to_json, counter)
with open(outputPath, 'w') as fp:
    json.dump(transaction_json, fp)
transaction_json = []  

# Condition
transaction_json = []
counter = counter+1
print(counter)
resources = fhir_client_source.resources('Condition').limit(500)
for resource in resources:
    if(org_name in resource.subject.reference or org_name in resource.encounter.reference):
        print(resource)
        resource_data = resource.serialize()  
        resource_data.id = '{}-{}'.format(resource_data.id,org_name)
        resource_model = get_resource_model(resource.resourceType, resource_data.id)
        resource_model['resource'] = resource_data
        transaction_json.append(resource_model)
        if(len(transaction_json) == 500):
            outputPath = '{}/transaction_{}.json'.format(path_to_json, counter)
            with open(outputPath, 'w') as fp:
                json.dump(transaction_json, fp)
            transaction_json = []
            counter = counter+1

outputPath = '{}/transaction_{}.json'.format(path_to_json, counter)
with open(outputPath, 'w') as fp:
    json.dump(transaction_json, fp)
transaction_json = []  
 
print("Done")