from celery import Celery
from .detect import SmileDetector

app = Celery("tasks", broker="pyamqp://guest@localhost//")

class Smile(app.Task):
    def __init__(self):
        self.detector = SmileDetector("lib/weights/detection_weights.pth","lib/weights/classification_weights.pth")

    def run(self, image):
        return self.detector.call(image)


detectTask = app.tasks[Smile.name]