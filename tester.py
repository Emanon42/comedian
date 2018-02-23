import cv2
from lib import detect
from lib.tasks import detectTask

def show_webcam():
    cam = cv2.VideoCapture(0)
    width = int(((cam.get(cv2.CAP_PROP_FRAME_WIDTH))/2)-200)
    height = int(((cam.get(cv2.CAP_PROP_FRAME_HEIGHT))/2)-200)
    face_cascade = cv2.CascadeClassifier('./haarcascade_frontalface_default.xml')
    while True:

        ret_val, img = cam.read()

        #img = img[width:width+400,height:height+400]
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, 1.3, 5)

        #faces_ = detect.SmileDetector("lib/weights/detection_weights.pth","lib/weights/classification_weights.pth")
        #detecteds = faces_.detect_faces(img)
        #print(len(detecteds))
        #print(len(faces))

        async_detec = detectTask.delay(img)
        if async_detec.ready():
            (boxes, preds) = async_detec.get()
            print(boxes)
            print(preds)
            
        for index,(x,y,w,h) in enumerate(faces):

            if cv2.waitKey(1) == 32:
                face = img[y:y+h,x:x+w]
                face = cv2.resize(face,(64,64))
                faceName = "face"+str(index)+".png"
                cv2.imwrite(faceName,face)
            cv2.rectangle(img, (x, y), (x + w, y + h), (0, 255, 0), 2)

        cv2.imshow('my webcam', img)
        if cv2.waitKey(1) == 27:
            break

    cv2.destroyAllWindows()

def main():
    show_webcam()

main()
