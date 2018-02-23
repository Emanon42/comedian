from .ssd import build_ssd
from .resnet import ConvnetBuilder
import torch
import cv2
from torchvision.models import resnet34
import numpy as np
from torch.autograd import Variable
import torchvision

class SmileDetector:

    def __init__(self,ssd_weights_path, resnet_weights_path):
        self.ssd = build_ssd("test",300,2)
        self.ssd.load_state_dict(torch.load(ssd_weights_path, map_location=lambda storage, loc: storage))

        self.conv_net_builder = ConvnetBuilder(resnet34, 2, False, False, ps=0.6)
        self.classifier = self.conv_net_builder.model
        self.classifier.load_state_dict(torch.load(resnet_weights_path, map_location=lambda storage, loc: storage))
        self.classifier.eval()

        self.transform = torchvision.transforms.Normalize(mean=[0.485, 0.456, 0.406],std=[0.229, 0.224, 0.225])


    def detect_faces(self, image):
        # note potentially i need to flip rgb to bgr

        # returns a list of x,y,width, heigth (x,y from the lower left corner)
        x = cv2.resize(image, (300, 300)).astype(np.float32)
        x -= (104.0, 117.0, 123.0)
        x = x.astype(np.float32)
        x = x[:, :, ::-1].copy()
        x = torch.from_numpy(x).permute(2, 0, 1)

        xx = Variable(x.unsqueeze(0), volatile=True)
        y = self.ssd(xx)
        detections = y.data

        scale = torch.Tensor(image.shape[1::-1]).repeat(2)

        boxes = []
        for i in range(detections.size(1)):
            j = 0
            while detections[0, i, j, 0] >= 0.25:
                score = detections[0, i, j, 0]
                pt = (detections[0, i, j, 1:] * scale).cpu().numpy()
                coords = (int(pt[0]), int(pt[1]), int(pt[2]) - int(pt[0]) + 1, int(pt[3]) - int(pt[1]) + 1)
                boxes.append(coords)
                j += 1
        return boxes



    def get_crops(self, image, boxes):
        #boxes are in format lower left corner x,y,width, height
        # does a quadratic center crop for each box
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        crops = []
        for box in boxes:
            center = (int(box[0] + 0.5*box[2]), int(box[1] + 0.5*box[3]))
            longer_side = max(box[2],box[3])
            xmin = max(int(center[0] - 0.5 * longer_side), 0)
            xmax = min(int(center[0] + 0.5 * longer_side), image.shape[1] - 1)
            ymin = max(int(center[1] - 0.5 * longer_side), 0)
            ymax = min(int(center[1] + 0.5 * longer_side), image.shape[0] - 1)
            crop = image[ymin:ymax, xmin:xmax]
            crop = cv2.resize(crop,(64,64))
            #crop = np.transpose(crop, [2,0,1])
            #crop = crop.astype(np.float32)
            crops.append(crop)

        return crops


    def predict_smiles(self, crops):
        crops_tensors = [self.transform(torch.from_numpy(np.transpose(crop, [2,0,1])).float()/255) for crop in crops]
        batch = Variable(torch.stack(crops_tensors, dim=0), volatile=True)
        predictions = self.classifier(batch)
        return np.exp(predictions.data.numpy())



    def call(self,image):
        boxes = self.detect_faces(image)
        crops = self.get_crops(image, boxes)
        preds = self.predict_smiles(crops)
        return (boxes, preds)





