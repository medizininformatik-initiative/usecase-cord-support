from fhirpy import SyncFHIRClient
import requests
from io import BytesIO
import numpy as np
import pandas as pd
from PIL import Image
from torch.utils.data import Dataset
import torchvision.transforms as transforms

class ISICDataset(Dataset):
    classes = {'NV': 0, 'MEL': 1, 'BKL': 2, 'DF': 3, 'SCC': 4, 'BCC': 5, 'VASC': 6, 'AK': 7}

    """ISIC dataset."""
    def __init__(self, fhir_server, fhir_port, split='train', input_size=256):
        """
        Args:
            fhir_server (string): Address of FHIR Server.
            fhir_port (string): Port of FHIR Server.
        """
        self.fhir_server = fhir_server
        self.fhir_port = fhir_port
        self.split = split
        self.input_size = input_size
        # Create an instance
        client = SyncFHIRClient('http://{}:{}/fhir'.format(fhir_server, fhir_port))
        # Search for patients
        patients = client.resources('Patient')  # Return lazy search set
        patients_data = []
        for patient in patients:
            patient_birthDate = None
            try:
                patient_birthDate = patient.birthDate
            except:
                pass
            # patinet_id, gender, birthDate
            patients_data.append([patient.id, patient.gender, patient_birthDate])
        patients_df = pd.DataFrame(patients_data, columns=["patient_id", "gender", "birthDate"])
        # Search for media
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
        self.data_df = pd.merge(patients_df, media_df, on='patient_id', how='outer')
        self.data_df = self.data_df[self.data_df['note'].notna()].reset_index()
        self.trans = transforms.Compose([transforms.RandomHorizontalFlip(),
                                         transforms.RandomVerticalFlip(),
                                         transforms.ColorJitter(brightness=32. / 255., saturation=0.5),
                                         transforms.Resize(self.input_size),
                                         transforms.ToTensor()])

    def __len__(self):
        if self.split == "train":
            return int(len(self.data_df) * 0.8)
        elif self.split == "val":
            return int(len(self.data_df) * 0.2)

    def __getitem__(self, idx):
        val_start_id = int(len(self.data_df) * 0.8)
        if self.split == "train":
            idx = idx
        else:
            idx = idx + val_start_id
        img_url = self.data_df.loc[idx, 'image_url']
        note = self.data_df.loc[idx, 'note']
        y = self.classes[note]
        img_res = requests.get(img_url)
        if img_res.status_code == 200:
            x = Image.open(BytesIO(img_res.content))
            x = self.center_crop(x)
            x = self.trans(x)
            # Transform y
            y = np.int64(y)
            return {"image": x, "label": y}
        else:
            raise RuntimeError("Image url {} is not reachable!".format(img_url))

    def center_crop(self, pil_img):
        img_width, img_height = pil_img.size
        if img_width > img_height:
            crop_size = img_height
        else:
            crop_size = img_width
        return pil_img.crop(((img_width - crop_size) // 2,
                             (img_height - crop_size) // 2,
                             (img_width + crop_size) // 2,
                             (img_height + crop_size) // 2))