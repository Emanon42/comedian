import cv2


def show_webcam():
    cam = cv2.VideoCapture(0)
    #cam.set(3, 1280)
    #cam.set(4, 720)
    while True:

        ret_val, img = cam.read()
        img = img[0:400,0:400]

        cv2.imshow('my webcam', img)
        if cv2.waitKey(1) == 27:
            break
    cv2.destroyAllWindows()

def main():
    show_webcam()

main()