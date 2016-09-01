from find_MST import *
from compute_distances import *
from contour_finder import  *
from skimage.morphology import convex_hull_image
import sys

def push_if(p, checked, toCheck):
    if p not in checked:
        toCheck.append(p)

def innerff(img, _x, _y):
    checked = set()
    toCheck = [(_x,_y)]
    while len(toCheck):
        x, y = toCheck.pop()
        if x >=0 and x < img.shape[0] and y >=0 and y < img.shape[1] and img[x,y] == 0:
            img[x,y] = 5
            checked.add((x,y))
            push_if((x, y-1), checked, toCheck)
            push_if((x, y+1), checked, toCheck)
            push_if((x-1, y), checked, toCheck)
            push_if((x+1, y), checked, toCheck)

def flood_fill(contour):
    maxx = int(round(max(contour, key=lambda p:p[0])[0]))
    minx = int(round(min(contour, key=lambda p:p[0])[0]))
    maxy = int(round(max(contour, key=lambda p:p[1])[1]))
    miny = int(round(min(contour, key=lambda p:p[1])[1]))

    img = np.zeros((maxx-minx + 3, maxy - miny + 3), dtype=np.int)
    xs = [int(round(x - minx + 1)) for (x, _) in contour]
    ys = [int(round(y - miny + 1)) for (_, y) in contour]

    img[xs, ys] = 255

    innerff(img, 0, 0)
    io.imsave('convexhulls_ff.png', img)

    res = [(x + minx - 1, y + miny -1) for x in range(0, img.shape[0]) for y in range(0, img.shape[1]) if img[x,y] == 0 or img[x,y] == 255]
    return res

def get_points_for_x(contour, px):
    ally = [y for (x, y) in contour if int(x) == px]
    return min(ally), max(ally)

def get_points_for_y(contour, py):
    allx = [x for (x, y) in contour if int(y) == py]
    return min(allx), max(allx)

def traverseX(contour, start, end):
    ranges = []
    for x in range(start[0], end[0]):
        minY, maxY = get_points_for_x(contour, x)
        ranges.append((x, maxY - minY, minY, maxY))
    max_val = max(ranges, key = lambda x: x[1])
    return (max_val, convert_to_pixels(ranges[0: ranges.index(max_val)], 1))

def traverseY(contour, start, end):
    ranges = []
    for y in range(start[1], end[1]):
        minX, maxX = get_points_for_y(contour, y)
        ranges.append((y, maxX - minX, minX, maxX))

    max_val = max(ranges, key = lambda y: y[1])
    return (max_val, convert_to_pixels(ranges[0:ranges.index(max_val)], 0))


def convert_to_pixels(range_part, is_x):
    xtab = []
    ytab = []
    if is_x:
        for (x, _, y1, y2) in range_part:
            xtab.append(int(x))
            xtab.append(int(x))
            ytab.append(int(y1))
            ytab.append(int(y2))
    else:
        for (y, _, x1, x2) in range_part:
            xtab.append(int(x1))
            xtab.append(int(x2))
            ytab.append(int(y))
            ytab.append(int(y))

    return xtab, ytab


def get_max_points(contour, terminal, center):
    points = (terminal, center)
    dx, dy = (terminal[0] - center[0], terminal[1] - center[1])
    if abs(dx) > abs(dy):
        if terminal[0] > center[0]:
            points = tuple(reversed(points))
        ((x, _, y1, y2), pixels)  = traverseX(contour, points[0], points[1])
        return ((x, y1), (x, y2), pixels)
    else:
        if terminal[1] > center[1]:
            points = tuple(reversed(points))
        ((y, _, x1, x2), pixels) = traverseY(contour, points[0], points[1])
        return ((x1, y), (x2, y), pixels)

def create_shape(image):
    (contours, size) = find_countours('test.png')
    ch = ContoursHelper(contours)
    G = ch.create_graph()
    T = find_MST(G)

    img = create_image_from_contours(contours, size)

    #drawing lines between computed pairs of points
    for (ia, ib) in T:
        (p1, p2) = ch.get_terminal_pixels(ia, ib)

        ac = ch.get_contour_center(ia)
        bc = ch.get_contour_center(ib)

        (mpa1, mpa2, pixelsa) = get_max_points(ch.get(ia), p1, ac)

        (mpb1, mpb2, pixelsb) = get_max_points(ch.get(ib), p2, bc)

        convex_image = np.zeros(size, dtype=np.int)
        convex_image[mpa1] = 255
        convex_image[mpa2] = 255
        convex_image[mpb1] = 255
        convex_image[mpb2] = 255
        convex_image[pixelsa] = 255
        convex_image[pixelsb] = 255
        #io.imsave('convexhulls_test(' + str(ia) + ',' + str(ib) + '.png', convex_image)
        convex = convex_hull_image(convex_image)
        img[convex] = 255


    for c in contours:
        p = flood_fill(c)
        img[zip(*p)] = 255

    return img

if __name__ == "__main__":
    img = io.imread('test.png')
    r = img[:, :, 0]
    shape_image = create_shape(r)
    io.imsave('convexhulls_test.png', shape_image)

