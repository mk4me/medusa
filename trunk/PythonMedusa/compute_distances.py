from contour_finder import *
from itertools import combinations
import scipy
import skimage.draw


def find_distance(contourA, contourB):
    dst = scipy.spatial.distance.cdist(contourA, contourB)
    (i, j) = np.unravel_index(dst.argmin(), dst.shape)
    return i, j, dst[i, j]


def big_pixel(img, p):
    (x, y) = (int(p[0]), int(p[1]))
    rr, cc = skimage.draw.circle(x, y, 4)
    img[rr, cc] = 255

def my_line(img, p1, p2):
    rr, cc = skimage.draw.line(int(p1[0]), int(p1[1]), int(p2[0]), int(p2[1]))
    img[rr, cc] = 255

class ContoursHelper:
    def __init__(self, _contours):
        self.contours = _contours
        self.distances = self.compute_distances()
        self.centers = self.compute_centers()

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

    def get_contour_center(self, idx):
        return self.convert_pixel(self.centers[idx])

    def convert_pixel(self, p):
        x = int(round(p[0]))
        y = int(round(p[1]))
        return (x, y)

    def get_terminal_pixels(self, ia, ib):
        (i1, i2, _) = self.distances[(ia,ib)]
        p1 = self.get(ia)[i1]
        p2 = self.get(ib)[i2]
        return (self.convert_pixel(p1), self.convert_pixel(p2))

    def compute_distances(self):
        distances = {}
        pairs = combinations(self.contours, 2)
        for A, B in pairs:
            (i, j, dist) = find_distance(A, B)
            ia, ib = (self.getIdx(A), self.getIdx(B))
            distances[(ia, ib)] = (i, j, dist)
            distances[(ib, ia)] = (j, i, dist)
        return distances

    def compute_centers(self):
        centers = []
        for contour in self.contours:
            center = (0,0)
            for p in contour:
                center += p
            centers.append(center/len(contour))
        return centers

#----------------------------------------------------------------------


def main():
    (contours, size) = find_countours('test.png')

    img = create_image_from_contours(contours, size)
    pairs = combinations(contours, 2)
    for (A, B) in pairs:
        (p1, p2, _) = find_distance(A, B)
        big_pixel(img, A[p1])
        big_pixel(img, B[p2])

    io.imsave('dist_test.png', img)

if __name__ == "__main__":
    main()