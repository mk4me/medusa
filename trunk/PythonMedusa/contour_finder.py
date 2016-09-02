import numpy as np
from skimage import measure, io

# returns contours for already loaded image
def find_contours_raw(image):
    # according to documentation 0.5 is best treshold for binary images
    contours = measure.find_contours(image, 0.5,  fully_connected='high', positive_orientation='high')
    return contours
    #return [c.astype(dtype=np.int) for c in contours]

# filters array of contours with given filter
def filter_contours(contours, filter):
    if (filter):
        return [c for c in contours if filter(c)]
    else:
        return contours

# returns function which returns true only for contours with pixelcount greater than treshold
def pixel_filter( treshold):
    def inner(contour):
        return len(contour) > treshold
    return inner

# for given image finds contours and filters them
def find_countours_for_image(img, contour_filter = pixel_filter(50)):
    contours = find_contours_raw(img)
    return (filter_contours(contours, contour_filter), img.shape)

# loads file, finds contours and filters them
def find_countours(filename, contour_filter = pixel_filter(50)):
    img = io.imread(filename)
    r = img[:, :, 0]
    return find_countours_for_image(r, contour_filter)

# creates an image of contours for given size
def create_image_from_contours(contours, size):
    res = np.zeros(size, dtype=np.int)
    for n, contour in enumerate(contours):
        for x, y in contour:
            res[int(round(x)), int(round(y))] = 255
    return res

# writes an image of contours for given size
def write_contours(filename, contours, size):
    res = create_image_from_contours(contours, size)
    io.imsave(filename, res)

if __name__ == "__main__":
    (contours, size) = find_countours('test.png')
    write_contours("test_result.png", contours, size)



