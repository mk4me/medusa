from MinimumSpanningTree import *
from compute_distances import *
import skimage.draw


def find_MST(G):
    return MinimumSpanningTree(G)

if __name__ == "__main__":
    (contours, size) = find_countours('test.png')
    ch = ContoursHelper(contours)
    G = ch.create_graph()
    T = find_MST(G)

    img = create_image_from_contours(contours, size)

    #drawing lines between computed pairs of points
    for (ia, ib) in T:
        (p1, p2) = ch.get_terminal_pixels(ia, ib)
        rr, cc = skimage.draw.line(p1[0], p1[1], p2[0], p2[1])
        img[rr, cc] = 255

    for c in ch.centers:
        big_pixel(img, c)

    io.imsave('mst_test.png', img)

