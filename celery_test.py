from lib.tasks import detectTask
import cv2
import numpy as np
import time

img = cv2.imread("selfie1.jpg")
async_detec = detectTask.delay(img)
time.sleep(5)
if async_detec.ready():
    (boxes, preds) = async_detec.get()
    print(boxes)
    print(preds)
    async_detec = detectTask.delay(img)
