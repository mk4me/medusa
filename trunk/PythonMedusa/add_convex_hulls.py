from find_MST import *
from compute_distances import *
from contour_finder import  *
from skimage.morphology import convex_hull_image

# funkcja pomocnicza dla flood fill
# umieszcza piksel w toCheck o ile nie ma go jeszcze w checked
def push_if(p, checked, toCheck):
    if p not in checked:
        toCheck.append(p)

# funkcja pomocnicza dla flood fill, poczatkowo byla rekurencyjna
# finalnie algorytm realizowany jest za pomoca stosu (nie ma ryzyka stack overflow)
def innerff(img, _x, _y):
    checked = set()
    toCheck = [(_x,_y)]
    while len(toCheck):
        x, y = toCheck.pop()
        # wypelniamy tylko piksele o kolorze 0, odwiedzone zapisujemy jako kolor 5
        if x >=0 and x < img.shape[0] and y >=0 and y < img.shape[1] and img[x,y] == 0:
            # piksel mozna 'wypelnic'!
            img[x,y] = 5
            # jak wypelnilismy to dodajemy do juz sprawdzonych
            checked.add((x,y))
            # badanie sasiadow
            push_if((x, y-1), checked, toCheck)
            push_if((x, y+1), checked, toCheck)
            push_if((x-1, y), checked, toCheck)
            push_if((x+1, y), checked, toCheck)

def flood_fill(contour):
    # liczenie bounding boxa dla konturu
    maxx = int(round(max(contour, key=lambda p:p[0])[0]))
    minx = int(round(min(contour, key=lambda p:p[0])[0]))
    maxy = int(round(max(contour, key=lambda p:p[1])[1]))
    miny = int(round(min(contour, key=lambda p:p[1])[1]))
    # algorytm to 'odwrocony flood fill' tzn nei wypelniamy tego co wewnatrz konturu
    # tylko wszystko co jest na zewnatrz, dzieki temu nie trzeba badac, czy dany punkt lezy w srodku czy na
    # zewnatrz konturu. Dodatkowo jest szansa, ze pikseli na zewnatrz bedzie mniej niz wewnatrz.

    # ramka dla ktorej dziala 'odwrocony flood fill' powinna byc troche wieksza od konturu, aby farba mogla
    # swobodnie sie 'przelewac' i wypelnic caly obszar na zewnatrz konturu
    img = np.zeros((maxx-minx + 3, maxy - miny + 3), dtype=np.int)
    # wyznaczanie przesunietych pikseli konturu
    xs = [int(round(x - minx + 1)) for (x, _) in contour]
    ys = [int(round(y - miny + 1)) for (_, y) in contour]
    # wpisanie konturu w obrazek
    img[xs, ys] = 255
    # wlasciwy flood fill
    innerff(img, 0, 0)
    #io.imsave('convexhulls_ff.png', img)

    #kolorowanie obszaru konturu
    res = [(x + minx - 1, y + miny -1) for x in range(0, img.shape[0]) for y in range(0, img.shape[1]) if img[x,y] == 0 or img[x,y] == 255]
    return res

# przecina kontur dla podanego px
# zwraca tablice z wszystkimi wrtosciami y, ktore zostaly przeciete
def get_points_for_x(contour, px):
    ally = [y for (x, y) in contour if int(x) == px]
    return ally

# przecina kontur dla podanego py
# zwraca tablice z wszystkimi wrtosciami x, ktore zostaly przeciete
def get_points_for_y(contour, py):
    allx = [x for (x, y) in contour if int(y) == py]
    return allx

# przechodzimy kontur horyzontalnie od x = start do end, badajac kolejne cieciwy
# zwracamy punkty, ktore tworza najdluzsza
def traverseX(contour, start, end):
    ranges = []
    for x in range(start[0], end[0]+1):
        ally = get_points_for_x(contour, x)
        if len(ally):
            minY, maxY = min(ally), max(ally)
            ranges.append((x, maxY - minY, minY, maxY))
    max_val = max(ranges, key = lambda x: x[1])
    return max_val

# przechodzimy kontur wertykalnie od y = start do end, badajac kolejne cieciwy
# zwracamy punkty, ktore tworza najdluzsza
def traverseY(contour, start, end):
    ranges = []
    for y in range(start[1], end[1]+1):
        allx = get_points_for_y(contour, y)
        if len(allx):
            minX, maxX = min(allx), max(allx)
            ranges.append((y, maxX - minX, minX, maxX))

    max_val = max(ranges, key = lambda y: y[1])
    return max_val

# umozliwia przechodzenie po tablicy cyklicznie,
# tzn jesli dotrzemy do konca to licznik sie zeruje i vice versa
def clamp(idx, count):
    if idx < 0: return count - 1
    if idx == count: return 0
    return idx

# sprawdza, czy piksele sa takie same
def same_pix(p1, p2):
    return int(round(p1[0])) == int(round(p2[0])) and int(round(p1[1])) == int(round(p2[1]))

# zwraca piksele, ktore wchodza w czesc konturu miedzy cieciwa a terminalnym
# puntky cieciwy to first i last, middle to punkt terminalny
def get_contour_part(contour, first, middle, last):
    idx = 0
    # wyznaczamy indeks terminalnego
    for i, pix in enumerate(contour):
        if same_pix(pix, middle):
            idx = i
            break

    count = len(contour)
    di = clamp(idx-1, count)
    part = []
    # przechodzimy w lewo i prawo tak dlugo az trafimy na punkt cieciwy
    # kroki zapisujemy do tablicy part
    while not (same_pix(contour[di], first) or same_pix(contour[di], last)):
        part.append(contour[di])
        di = clamp(di-1, count)

    di = clamp(idx+1, count)
    while not (same_pix(contour[di], first) or same_pix(contour[di], last)):
        part.append(contour[di])
        di = clamp(di+1, count)
    return part

#dla konturu o indeksie ia i jego punktu terminalnego p1 i srodka ac
# wyznacza najszersza cieciwe (miedzy mpa1 i mpa2) oraz te piksele czesci konturu
# ktore zawieraja punkt terminalny, punkty cieciwy i wszystkie piksele miedzy nimi
def get_max_points(contour, terminal, center, ratio = 1):
    #wektor od terminalnego do srodka
    dx, dy = (center[0] - terminal[0], center[1] - terminal[1])
    # troche go skracamy...
    dx *= ratio
    dy *= ratio
    # ..i otrzymujemy finalny cel, dla ktorego bedziemy badac kolejne cieciwy
    destination = (int(terminal[0] + dx), int(terminal[1] + dy))
    points = (terminal, destination)
    # czy przechodzimy kontur horyzontalnie czy wertykalnie?
    if abs(dx) > abs(dy):
        # czy mozemy iterowac, czy trzeba odwrocic kolejnosc
        if terminal[0] > destination[0]:
            points = tuple(reversed(points))
        # przechodzimy horyzonalnie, traverse zwraca puntky, ktore tworza najwieksza cieciwe
        (x, _, y1, y2) = traverseX(contour, points[0], points[1])
        # dodatkowo liczymy piksele, ktore wchodza w czesc konturu miedzy cieciwa a terminalnym
        part = get_contour_part(contour, (x,y1), terminal, (x,y2))
        return ((x, y1), (x, y2), part)#res)
    else:
        if terminal[1] > destination[1]:
            points = tuple(reversed(points))
        # przechodzimy wertykalnie, traverse zwraca puntky, ktore tworza najwieksza cieciwe
        (y, _, x1, x2) = traverseY(contour, points[0], points[1])
        # dodatkowo liczymy piksele, ktore wchodza w czesc konturu miedzy cieciwa a terminalnym
        part = get_contour_part(contour, (x1,y), terminal, (x2,y))
        return ((x1, y), (x2, y), part)# res)

# oblicza kontury i laczy je miedzy soba
def create_shape(image, ratio):
    # wykrywa kontury
    (contours, size) = find_countours_for_image(image)
    # helper ulatwia poslugiwanie sie konturami
    ch = ContoursHelper(contours)
    # graf dla MST
    G = ch.create_graph()
    T = find_MST(G)

    # tworzy obrazek z konturami, pozniej domalujemy reszte
    img = create_image_from_contours(contours, size)

    # iterujemy po parach konturow do polaczenia
    for (ia, ib) in T:
        # najblisze puntky...
        (p1, p2) = ch.get_terminal_pixels(ia, ib)
        # srodki konturow...
        ac = ch.get_contour_center(ia)
        bc = ch.get_contour_center(ib)

        # dla konturu o indeksie ia i jego punktu terminalnego p1 i srodka ac
        # wyznacza najszersza cieciwe (miedzy mpa1 i mpa2) oraz te piksele czesci konturu
        # ktore zawieraja punkt terminalny, punkty cieciwy i wszystkie piksele miedzy nimi
        (mpa1, mpa2, pixelsa) = get_max_points(ch.get(ia), p1, ac, ratio)
        #analogicznie dla b
        (mpb1, mpb2, pixelsb) = get_max_points(ch.get(ib), p2, bc, ratio)

        # wstawienie wszystkcih wyliczonych pikseli na tyczasowy obraz dla ktorego wyliczony zostanie convex hull
        convex_image = np.zeros(size, dtype=np.int)
        convex_image[int(mpa1[0]),int(mpa1[1])] = 255
        convex_image[int(mpa2[0]),int(mpa2[1])] = 255
        convex_image[int(mpb1[0]),int(mpb1[1])] = 255
        convex_image[int(mpb2[0]),int(mpb2[1])] = 255
        convex_image[zip(*pixelsa)] = 255
        convex_image[zip(*pixelsb)] = 255
        #io.imsave('convexhulls_test(' + str(ia) + ',' + str(ib) + '.png', convex_image)

        #wylicza convex hull i wstawia go na nasz glowny obraz
        convex = convex_hull_image(convex_image)
        img[convex] = 255

    # wstawia na glowny obraz wypelnienie konturow
    for c in contours:
        p = flood_fill(c)
        img[zip(*p)] = 255

    return img

# laczy kontury ze soba, dodatkowo wczytuje i zapisuje pliki
def create_shape_for_file(infile, outfile, ratio):
    img = io.imread(infile)
    r = img[:, :, 0]
    shape_image = create_shape(r, 0.7)
    io.imsave(outfile, shape_image)

if __name__ == "__main__":
    create_shape_for_file('test.png', 'convexhulls_test.png', 0.5)

