import torch
import torch.nn as nn
from torchvision.models import resnet

class ISICNet(nn.Module):
    def __init__(self, n_feature=3, n_class=8, backbone='resnet18'):
        super(ISICNet, self).__init__()
        self.n_feature = n_feature
        self.n_class = n_class
        self.backbnone = backbone
        if self.backbnone == 'resnet18':
            base = resnet.resnet18(pretrained=True)
            self.resnet_expansion = 1
        self.in_block = nn.Sequential(
            nn.Conv2d(self.n_feature, 64, kernel_size=(7, 7), stride=(2, 2), padding=(3, 3), bias=False),
            base.bn1,
            base.relu,
            base.maxpool)
        self.encoder1 = base.layer1
        self.encoder2 = base.layer2
        self.encoder3 = base.layer3
        self.encoder4 = base.layer4
        self.avgpool = base.avgpool
        self.flatten = nn.Flatten()
        self.fc = nn.Linear(512*self.resnet_expansion, self.n_class , bias=True)

    def forward(self, x):
        h = self.in_block(x)
        h = self.encoder1(h)
        h = self.encoder2(h)
        h = self.encoder3(h)
        h = self.encoder4(h)
        y = self.fc(self.flatten(self.avgpool(h)))
        return y

if __name__ == "__main__":
    model = ISICNet().cuda()
    x = torch.rand(2, 3, 512, 512).cuda()
    y = model(x)
    print(y)
    print(y.data.max(1)[1])
    # t = torch.tensor([1.0, 0.0, 1.0])
    # y = torch.tensor([0.02, 0.05, 0.99])
    # bce = nn.BCELoss()
    # l = torch.log(torch.tensor(0.02))+ torch.log(torch.tensor(1-0.05)) + torch.log(torch.tensor(0.99))
    # print(bce(y, t))
    # print(l)