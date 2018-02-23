from celery import Celery
import celery
from .detect import SmileDetector

app = Celery("tasks", broker="pyamqp://guest@localhost//")

detector = SmileDetector("lib/weights/detection_weights.pth","lib/weights/classification_weights.pth")

@app.tasks
def detectTask(image):
    return detector.call(image)