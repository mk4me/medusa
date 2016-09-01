from contour_finder import *
from itertools import combinations
import scipy
import skimage.draw

def find_distance(contourA, contourB):
    dst = scipy.spatial.distance.cdist( contourA, contourB )
    (i,j) = np.unravel_index(dst.argmin(), dst.shape)
    return (i, j, dst[i,j])


'''
def test():
  A = [[ 255, 63], [ 255, 64], [ 254, 63], [ 255, 62], [ 255, 63]]
  B = [[ 155, 63], [ 155, 64], [ 154, 63], [ 155, 62], [ 155, 63]]
  dst = find_distance(A,B)
'''

def big_pixel(p, img):
    (x, y) = (int(p[0]), int(p[1]))
    rr,cc = skimage.draw.circle(x, y, 4)
    img[rr, cc] = 255

class ContoursHelper:
    def __init__(self, _contours):
        self.contours = _contours
        self.compute_distances()

    def get(self, i): return self.contours[i]

    def getIdx(self, contour): return self.contours.index(contour)

    def create_graph(self):
        G = {}
        for contour in self.contours:
            ic = self.getIdx(contour)
            distances = {}
            for contour2 in self.contours:
                ic2 = self.getIdx(contour2)
                if ic != ic2:
                    distances[ic2] = self.get_distance(ic, ic2)
            G[ic] = distances
        return G

    def get_distance(self, ia, ib): return self.distances[(ia, ib)][2]

    def get_terminal_pixels(self, ia, ib):
        (i1, i2, _) = self.distances[(ia,ib)]
        p1 = self.get(ia)[i1]
        p2 = self.get(ib)[i2]
        x1 = int(round(p1[0]))
        y1 = int(round(p1[1]))
        x2 = int(round(p2[0]))
        y2 = int(round(p2[1]))
        return ((x1, y1),(x2, y2) )

    def compute_distances(self):
        self.distances = {}
        pairs = combinations(self.contours, 2)
        for p in pairs:
            A, B = p
            dist = find_distance(A, B)
            ia, ib = (self.getIdx(A), self.getIdx(B))
            self.distances[(ia, ib)] = dist
            self.distances[(ib, ia)] = dist

if __name__ == "__main__":
    (contours, size) = find_countours('test.png')

    img = create_image_from_contours(contours, size)
    pairs = combinations(contours, 2)
    for (A, B) in pairs:
        (p1, p2, _) = find_distance(A, B)
        big_pixel(A[p1], img)
        big_pixel(B[p2], img)

    io.imsave('dist_test.png', img)

