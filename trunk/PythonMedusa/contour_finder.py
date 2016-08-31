import numpy as np

from skimage import measure, io



if __name__ == "__main__":
    img = io.imread('test.png')
    r = img[:,:,0]
    contours = measure.find_contours(r,0.5,  fully_connected='high', positive_orientation='high')
    res = np.zeros(r.shape, dtype=np.int)

    for n, contour in enumerate(contours):
        for x,y in contour:
            res[int(x+0.5),int(y+0.5)] = 255

    io.imsave('test.res.png', res)
