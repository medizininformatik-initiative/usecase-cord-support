import os
import sys
import json
from fhirpy import SyncFHIRClient

def get_transaction_model():
    transaction_model = {
        "resourceType": "Bundle",
        "type": "transaction",
        "entry": []
    }
    return transaction_model

# FHIR server api
fhir_addr_target = 'http://{}:{}/fhir'.format(sys.argv[1], sys.argv[2])

# Organizaition Name: 'Airolo' or 'Bapu' or 'Cynthia'
org_name = sys.argv[3]

print(fhir_addr_target)
print(org_name)

# Create an instance
fhir_client_target = SyncFHIRClient(fhir_addr_target)
        
path_to_json = "./output/{}".format(org_name)

json_files = [pos_json for pos_json in os.listdir(path_to_json) if pos_json.endswith('.json')]
json_files = sorted(json_files, key=lambda x: int(x.split(".")[0].split("_")[-1]))
for json_file in json_files:
    print(json_file)
    with open('{}/{}'.format(path_to_json,json_file)) as f:
        data = json.load(f)
        
    transaction_model = get_transaction_model()
    transaction_model["entry"].append(data)
    p = fhir_client_target.resource("Bundle", **transaction_model)
    p.save()      

print("Done")