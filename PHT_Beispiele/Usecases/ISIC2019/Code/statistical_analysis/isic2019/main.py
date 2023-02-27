import os
import os.path as osp
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import glob

from fhirpy import SyncFHIRClient

## Define directory of output
here = osp.dirname(osp.abspath(__file__))
out_dir = osp.join(here, 'output')
if not os.path.exists(out_dir):
    os.makedirs(out_dir)
runs = sorted(glob.glob(os.path.join(out_dir, 'run_*')))
run_id = int(runs[-1].split('_')[-1]) + 1 if runs else 0
experiment_dir = os.path.join(out_dir, 'run_{}'.format(str(run_id)))
if not os.path.exists(experiment_dir):
    os.makedirs(experiment_dir)

## Define (output) file formats
if not osp.exists(osp.join(experiment_dir, 'report.txt')):
    with open(osp.join(experiment_dir, 'report.txt'), 'w') as f:
        pass

## Define (input) variables from Docker Container environment variables
fhir_server = str(os.environ['FHIR_SERVER'])
fhir_port = str(os.environ['FHIR_PORT'])

## Load aggregated results from previous stations
# if run_id > 0:
#     prev_experiment_dir = osp.join(out_dir, 'run_{}'.format(str(run_id - 1)))
#     if osp.exists(osp.join(prev_experiment_dir, '')):
#         pass
#     else:
#         pass
# else:
#     pass

# Collect Data Statistic
## Create an instance
client = SyncFHIRClient('http://{}:{}/fhir'.format(fhir_server, fhir_port))
## Search for patients
patients = client.resources('Patient')  # Return lazy search set
patients_data = []
for patient in patients:
    patient_birthDate = None
    try:
        patient_birthDate = patient.birthDate
    except:
        pass
    patients_data.append([patient.id, patient.gender, patient_birthDate])
patients_df = pd.DataFrame(patients_data, columns=["patient_id", "gender", "birthDate"])
## Search for media
media_list = client.resources('Media').include('Patient', 'subject')
media_data = []
for media in media_list:
    media_bodySite = None
    media_reasonCode = None
    media_note = None
    try:
        media_bodySite = media.bodySite.text
    except:
        pass
    try:
        media_reasonCode = media.reasonCode[0].text
    except:
        pass
    try:
        media_note = media.note[0].text
    except:
        pass
    media_data.append([media.subject.id, media.id, media_bodySite, media_reasonCode, media_note, media.content.url])
media_df = pd.DataFrame(media_data, columns=["patient_id", "media_id", "bodySite", "reasonCode", "note", "image_url"])
data_df = pd.merge(patients_df, media_df, on='patient_id', how='outer')

## Collect statistical information
import datetime
from datetime import date
def calculateAge(born):
    if born is None:
        return None
    born = datetime.datetime.strptime(born, '%Y-%m-%d').date()
    today = date.today()
    try:
        birthday = born.replace(year=today.year)
    except ValueError:
        birthday = born.replace(year=today.year,
                                month=born.month + 1, day=1)
    if birthday > today:
        return today.year - born.year - 1
    else:
        return today.year - born.year

data_df['age'] = data_df['birthDate'].map(lambda x: calculateAge(x))

with open(osp.join(experiment_dir, 'report.txt'), 'a') as f:
    f.write('Stations have {} instances with complete attributes \n'.format(data_df[(data_df['age'].notna()) & (data_df['note'].notna()) & (data_df['gender'].notna())].shape[0]))
    f.write('Station has {} instances whose attribute \"age\" is missing\n'.format(data_df['age'].isna().sum()))
    f.write('Station has {} instances whose attribute \"gender\" is missing\n'.format(data_df['gender'].isna().sum()))
    f.write('Station has {} instances whose attribute \"bodySite\" is missing\n'.format(data_df['bodySite'].isna().sum()))

data_df['MEL'] = data_df['note'].map(lambda x: 1 if x == 'MEL' else 0)
data_df['NV'] = data_df['note'].map(lambda x: 1 if x == 'NV' else 0)
data_df['BKL'] = data_df['note'].map(lambda x: 1 if x == 'BKL' else 0)
data_df['DF'] = data_df['note'].map(lambda x: 1 if x == 'DF' else 0)
data_df['SCC'] = data_df['note'].map(lambda x: 1 if x == 'SCC' else 0)
data_df['BCC'] = data_df['note'].map(lambda x: 1 if x == 'BCC' else 0)
data_df['VASC'] = data_df['note'].map(lambda x: 1 if x == 'VASC' else 0)
data_df['AK'] = data_df['note'].map(lambda x: 1 if x == 'AK' else 0)

age_df = data_df[['MEL','NV','BCC','AK','BKL','DF','VASC','SCC','age']]
def replace_age(row):
    if row['age'] == np.nan:
        return pd.Series([np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan])
    elif row['MEL'] == 1.0:
        return pd.Series([row['age'], np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan])
    elif row['NV'] == 1.0:
        return pd.Series([np.nan, row['age'], np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan])
    elif row['BCC'] == 1.0:
        return pd.Series([np.nan, np.nan, row['age'], np.nan, np.nan, np.nan, np.nan, np.nan, np.nan])
    elif row['AK'] == 1.0:
        return pd.Series([np.nan, np.nan, np.nan, row['age'], np.nan, np.nan, np.nan, np.nan, np.nan])
    elif row['BKL'] == 1.0:
        return pd.Series([np.nan, np.nan, np.nan, np.nan, row['age'], np.nan, np.nan, np.nan, np.nan])
    elif row['DF'] == 1.0:
        return pd.Series([np.nan, np.nan, np.nan, np.nan, np.nan, row['age'], np.nan, np.nan, np.nan])
    elif row['VASC'] == 1.0:
        return pd.Series([np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, row['age'], np.nan, np.nan])
    elif row['SCC'] == 1.0:
        return pd.Series([np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, row['age'],  np.nan])

age_df = age_df.apply(lambda row: replace_age(row), axis=1).rename(columns={0:'MEL', 1:'NV', 2:'BCC', 3:'AK', 4:'BKL', 5:'DF', 6:'VASC', 7:'SCC', 8:'age'}).drop(['age'], axis=1)
age_df.boxplot()
plt.savefig(osp.join(experiment_dir,'age_dist.jpg'))
age_quantile = pd.DataFrame([age_df.quantile(0.25), age_df.quantile(0.5), age_df.quantile(0.75)], index=['lower quartile',  'median', 'upper quartile'])
age_quantile.to_csv(osp.join(experiment_dir, 'age.csv'), index=True)

sex_df = data_df[['MEL','NV','BCC','AK','BKL','DF','VASC','SCC','gender']]
sex_sum_df = sex_df.groupby('gender').sum()
sex_sum_df.T.plot(kind='bar')
plt.savefig(osp.join(experiment_dir,'gender_mal.jpg'))
sex_sum_df.to_csv(osp.join(experiment_dir, 'gender.csv'), index=True)

anotom_df = data_df[['MEL','NV','BCC','AK','BKL','DF','VASC','SCC','bodySite']]
anotom_sum_df = anotom_df.groupby('bodySite').sum()
anotom_sum_df.T.plot(kind='bar')
plt.savefig(osp.join(experiment_dir,'anotom_mal.jpg'))
anotom_sum_df.to_csv(osp.join(experiment_dir, 'anotom.csv'), index=True)