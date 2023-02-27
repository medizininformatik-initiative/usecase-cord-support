import os
import os.path as osp
import numpy as np

import glob
import tqdm
import shutil
import pytz
import datetime

import torch
import torch.nn as nn
from torch.autograd import Variable

from models.isicnet import ISICNet
from datasets.isicdataset import ISICDataset

## Define evaluation function
def _fast_hist(label_true, label_pred, n_class):
    hist = np.bincount(
        n_class * label_true.astype(int) +
        label_pred.astype(int), minlength=n_class ** 2).reshape(n_class, n_class)
    return hist

def label_accuracy_score(label_trues, label_preds, n_class=8):
    hist = np.zeros((n_class, n_class))
    hist += _fast_hist(label_trues, label_preds, n_class)
    acc = np.diag(hist).sum() / hist.sum()
    with np.errstate(divide='ignore', invalid='ignore'):
        precision = np.diag(hist) / hist.sum(axis=1)
    mean_precision = np.nanmean(precision)
    with np.errstate(divide='ignore', invalid='ignore'):
        recall = np.diag(hist) / hist.sum(axis=0)
    mean_recall = np.nanmean(recall)
    with np.errstate(divide='ignore', invalid='ignore'):
        iou = np.diag(hist) / (hist.sum(axis=1) + hist.sum(axis=0) - np.diag(hist))
    mean_iou = np.nanmean(iou)
    with np.errstate(divide='ignore', invalid='ignore'):
        f1 = (2 * np.diag(hist))/ (hist.sum(axis=1) + hist.sum(axis=0) + 2 * np.diag(hist))
    mean_f1 = np.nanmean(f1)
    return acc, mean_precision, mean_recall, mean_iou, mean_f1

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

## Define (input) variables from Docker Container environment variables
fhir_server = str(os.environ['FHIR_SERVER'])
fhir_port = str(os.environ['FHIR_PORT'])
# num_station = int(os.environ['NUM_STATION'])
# sid = int(os.environ['SID'])
batch_size = int(os.environ['BATCH_SIZE'])
num_epoch = int(os.environ['NUM_EPOCH'])
lr = float(os.environ['LR'])
weight_decay = float(os.environ['WEIGTH_DECAY'])
model_name = str(os.environ['MODEL_NAME'])

## Define (output) file formats
if not osp.exists(osp.join(experiment_dir, 'val_log.csv')):
    with open(osp.join(experiment_dir, 'val_log.csv'), 'w') as f:
        header = ['epoch', 'Loss', 'Acc', 'Precision', 'Recall', 'Iou', 'F1Score', 'train/Loss', 'elapsed_time']
        header = map(str, header)
        f.write(','.join(header) + '\n')
        print("Initial Log file")

cuda = torch.cuda.is_available()
torch.manual_seed(1337)
if cuda:
    torch.cuda.manual_seed(1337)

## Initial Model
print("Initial Model")
model = ISICNet(backbone=model_name)
print("Initial Model {}".format(model_name))
if cuda:
    print("Cuda:", cuda)
    model = model.cuda()

## Initial Datasets of train and val on station 1, 2, 3 and test
kwargs = {'num_workers': 4, 'pin_memory': True} if cuda else {}
print("Initial Training Dataset")
train_dataloader = torch.utils.data.DataLoader(ISICDataset(fhir_server, fhir_port, split='train'), batch_size=batch_size, shuffle=True, **kwargs)
print("Initial Val Dataset")
val_dataloader = torch.utils.data.DataLoader(ISICDataset(fhir_server, fhir_port, split='val'), batch_size=batch_size, shuffle=False, **kwargs)
## Initial criterion (Cross Entropy Loss)
print("Initial Loss function")
criterion = nn.CrossEntropyLoss()
## Initial Optimizers for station
print("Initial Optimizer")
optim = torch.optim.Adam(model.parameters(), lr=lr, weight_decay=weight_decay)

## Load model from previous train
if run_id > 0:
    prev_experiment_dir = osp.join(out_dir, 'run_{}'.format(str(run_id - 1)))
    if osp.exists(osp.join(prev_experiment_dir, 'best_model.pth.tar')):
        prev_best_model = torch.load(osp.join(prev_experiment_dir, 'best_model.pth.tar'))
        model.load_state_dict(prev_best_model['model_state_dict'])
        optim.load_state_dict(prev_best_model['optim_state_dict'])
        shutil.copy(osp.join(prev_experiment_dir, 'best_model.pth.tar'),
                    osp.join(experiment_dir, 'best_model.pth.tar'))
        print("Model loaded from previous train.")
    else:
        print("No previous best model found!")
else:
    torch.save({
        'epoch': 0,
        'optim_state_dict': optim.state_dict(),
        'model_state_dict': model.state_dict(),
        'best_acc': 0.0,
    }, osp.join(experiment_dir, 'best_model.pth.tar'))

timestamp_start = datetime.datetime.now(pytz.timezone('Asia/Tokyo'))
best_acc = 0.0
## Run the training processing on the station
for epoch in range(num_epoch):
    model.train()
    train_loss = 0.0
    for batch_idx, sample in tqdm.tqdm(enumerate(train_dataloader), total=len(train_dataloader), desc='Station Train epoch=%d' % epoch, ncols=80, leave=False):
        assert model.training
        img, lbl = sample['image'], sample['label']
        if cuda:
            img, lbl = img.cuda(), lbl.cuda()
        img, lbl = Variable(img), Variable(lbl)
        optim.zero_grad()
        pred = model(img)
        loss = criterion(pred, lbl)
        train_loss = train_loss + loss.data.item()
        loss.backward()
        optim.step()

    train_loss = train_loss / len(train_dataloader)
    print("Train epoch {} finished with average train loss of {}.".format(epoch, train_loss))

    model.eval()
    val_loss = 0.0
    label_trues, label_preds = [], []
    for batch_idx, sample in tqdm.tqdm(enumerate(val_dataloader), total=len(val_dataloader), desc='Station Val epoch=%d' % epoch, ncols=80, leave=False):
        img, lbl = sample['image'], sample['label']
        if cuda:
            img, lbl = img.cuda(), lbl.cuda()
        img, lbl = Variable(img), Variable(lbl)
        with torch.no_grad():
            pred = model(img)
        loss = criterion(pred, lbl)
        val_loss = val_loss + loss.data.item()
        lbl = lbl.data.cpu().numpy()
        pred = pred.data.max(1)[1].cpu().numpy()
        label_trues = np.concatenate((label_trues, lbl), axis=0)
        label_preds = np.concatenate((label_preds, pred), axis=0)
    val_loss = val_loss / len(val_dataloader)
    acc, mean_precision, mean_recall, mean_iou, mean_f1 = label_accuracy_score(label_trues, label_preds)
    with open(osp.join(experiment_dir, 'val_log.csv'), 'a') as f:
        elapsed_time = (datetime.datetime.now(pytz.timezone('Asia/Tokyo')) - timestamp_start).total_seconds()
        log = [epoch, val_loss, acc, mean_precision, mean_recall, mean_iou, mean_f1, train_loss, elapsed_time]
        log = map(str, log)
        f.write(','.join(log) + '\n')

    is_best = acc > best_acc
    if is_best:
        best_acc = acc
    torch.save({
        'epoch': epoch,
        'optim_state_dict': optim.state_dict(),
        'model_state_dict': model.state_dict(),
        'best_acc': best_acc,
    }, osp.join(experiment_dir, 'checkpoint.pth.tar'))
    if is_best:
        shutil.copy(osp.join(experiment_dir, 'checkpoint.pth.tar'), osp.join(experiment_dir, 'best_model.pth.tar'))
    print("Station Val epoch {} finished with loss of {}, acc of {}, precision of {}, recall of {}, iou of {}, f1-score of {}.".format(epoch, val_loss, acc, mean_precision, mean_recall, mean_iou, mean_f1))
print("Finished training process")









