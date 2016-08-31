import numpy as np

from skimage import measure, io

def find_contours(image):
    r = img[:,:,0]
    contours = measure.find_contours(r,0.5,  fully_connected='high', positive_orientation='high')
    return contours

#def filter_contours(contours, filter):
#    return contours

if __name__ == "__main__":
    img = io.imread('test.png')
    contours = find_contours(img)
    res = np.zeros(r.shape, dtype=np.int)
    for n, contour in enumerate(contours):
        for x,y in contour:
            res[int(x+0.5),int(y+0.5)] = 255

    io.imsave('test.res.png', res)


