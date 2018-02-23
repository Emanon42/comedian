from celery import Celery
from .detect import SmileDetector

app = Celery("tasks", broker="pyamqp://guest@localhost//")

class Smile(app.Task):
    def __init__(self):
        self.detector = SmileDetector()