import cv2


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
        print(len(faces))
        for index,(x,y,w,h) in enumerate(faces):

            if cv2.waitKey(1) == 32:
                face = img[x:x+w,y:y+h]
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