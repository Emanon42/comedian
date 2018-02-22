import cv2


def show_webcam():
    cam = cv2.VideoCapture(0)

    while True:
        ret_val, img = cam.read()
        #res = img[0:640,0:640]
        cv2.imshow('my webcam', img)
        if cv2.waitKey(1) == 27:
            break
    cv2.destroyAllWindows()

def main():
    show_webcam()

main()