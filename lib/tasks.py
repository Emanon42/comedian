import celeryconfig
from celery import Celery
import celery
from .detect import SmileDetector

app = Celery()
app.config_from_object(celeryconfig)
detector = SmileDetector("lib/weights/detection_weights.pth","lib/weights/classification_weights.pth")

@app.task
def detectTask(image):
    return detector.call(image)


