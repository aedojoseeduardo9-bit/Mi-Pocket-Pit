#!/usr/bin/env python3
"""Pocket Pip — genera godot/data/catalogo.json y docs/CATALOGO.md.

Ropa (130+), decoración (30+ por habitación), pociones, bailes, comida, minijuegos y paquetes de la tienda.
Cada prenda tiene una "forma" (cómo se arma en atuendos.gd) y colores; cada decoración, sus parámetros
(casa.gd). Nombres en español e inglés. Uso: python3 godot/tools/generar_catalogo.py
"""
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ---------------- colores con nombre ----------------
C = {
    "rojo": ("#e85d6f", "Red", "rojo"), "azul": ("#3d6dfe", "Blue", "azul"), "verde": ("#4cc38a", "Green", "verde"),
    "amarillo": ("#ffcf4a", "Yellow", "amarillo"), "rosa": ("#ff8fb3", "Pink", "rosa"), "lila": ("#9b7cf6", "Purple", "lila"),
    "negro": ("#2b2633", "Black", "negro"), "blanco": ("#f6f2ee", "White", "blanco"), "menta": ("#7fd8be", "Mint", "menta"),
    "naranjo": ("#ff9f43", "Orange", "naranjo"), "cafe": ("#8d5d32", "Brown", "café"), "celeste": ("#7fc8ff", "Sky", "celeste"),
    "oro": ("#ffcf4a", "Gold", "de oro"), "plata": ("#cfd6e2", "Silver", "de plata"), "turquesa": ("#3cc9c0", "Teal", "turquesa"),
    "gris": ("#9aa0ad", "Gray", "gris"),
}

def col(n):
    return C[n][0]

ropa = []

def prenda(forma, zona, es, en, precio, nivel, colores=None, variantes=None, anim=""):
    """variantes: lista de nombres de color; cada una crea una prenda."""
    vs = variantes or [None]
    for v in vs:
        cs = [col(v)] + [col(x) for x in (colores or [])] if v else [col(x) for x in (colores or [])]
        pid = forma + ("_" + v if v and len(vs) > 1 else "")
        nombre = es + (" " + C[v][2] if v and len(vs) > 1 else "")
        nombre_en = (C[v][1] + " " if v and len(vs) > 1 else "") + en
        ropa.append({"id": pid, "forma": forma, "zona": zona, "nombre": nombre, "en": nombre_en,
                     "precio": precio, "nivel": nivel, "c": cs, "anim": anim})

# ---- cuello ----
prenda("bufanda", "cuello", "Bufanda", "Scarf", 45, 1, ["blanco"], ["menta", "rojo", "lila", "amarillo"])
ropa[0]["id"] = "bufanda_nova"; ropa[0]["nombre"] = "Bufanda Nova"; ropa[0]["en"] = "Nova Scarf"; ropa[0]["precio"] = 0
ropa[0]["c"] = ["#6cc9b2", "#4fae98"]
prenda("mono", "cuello", "Moño", "Bow Tie", 40, 1, None, ["rojo", "negro", "lila"])
prenda("collar_bellotas", "cuello", "Collar de bellotas", "Acorn Necklace", 70, 2, ["cafe"])
prenda("panuelo", "cuello", "Pañuelo", "Bandana", 45, 1, ["blanco"], ["azul", "rojo", "verde"])
prenda("corbata", "cuello", "Corbata", "Necktie", 60, 2, ["blanco"], ["azul", "rojo"])
prenda("collar_perlas", "cuello", "Collar de perlas", "Pearl Necklace", 140, 4, ["blanco"])
prenda("cascabel", "cuello", "Cascabel", "Jingle Bell", 80, 2, ["oro"], ["rojo", "azul"], "balancear")
prenda("medalla", "cuello", "Medalla de campeón", "Champion Medal", 160, 5, ["oro", "azul"])

# ---- cabeza ----
prenda("gorro_lana", "cabeza", "Gorro de lana", "Beanie", 60, 1, ["blanco"], ["rojo", "azul", "verde", "lila"])
prenda("gorra", "cabeza", "Gorra", "Cap", 70, 1, ["blanco"], ["azul", "rojo", "negro", "verde"])
prenda("sombrero_copa", "cabeza", "Sombrero de copa", "Top Hat", 150, 3, ["rojo"], ["negro", "lila"])
prenda("corona", "cabeza", "Corona", "Crown", 320, 5, ["rojo"], ["oro", "plata"], "brillar")
prenda("flor", "cabeza", "Flor", "Flower", 35, 1, ["amarillo"], ["rosa", "blanco", "celeste"])
prenda("audifonos", "cabeza", "Audífonos", "Headphones", 120, 2, ["negro"], ["lila", "rojo", "menta"])
prenda("vaquero", "cabeza", "Sombrero vaquero", "Cowboy Hat", 130, 3, ["cafe"], ["cafe", "negro"])
prenda("chef", "cabeza", "Gorro de chef", "Chef Hat", 90, 2, ["blanco"])
prenda("pirata", "cabeza", "Sombrero pirata", "Pirate Hat", 150, 3, ["negro", "blanco"])
prenda("mago", "cabeza", "Sombrero de mago", "Wizard Hat", 160, 4, ["amarillo"], ["azul", "lila"])
prenda("casco_astronauta", "cabeza", "Casco de astronauta", "Space Helmet", 260, 6, ["blanco", "celeste"])
prenda("corona_flores", "cabeza", "Corona de flores", "Flower Crown", 110, 2, ["verde", "amarillo"], ["rosa", "lila"])
prenda("cuernos", "cabeza", "Cuernitos", "Little Horns", 90, 3, None, ["rojo", "negro"])
prenda("aureola", "cabeza", "Aureola", "Halo", 200, 5, ["oro"], None, "flotar")
prenda("antenas", "cabeza", "Antenas", "Antennae", 70, 2, ["negro", "amarillo"], None, "balancear")
prenda("helice", "cabeza", "Gorro con hélice", "Propeller Cap", 120, 3, ["amarillo", "rojo"], ["azul", "verde"], "girar")
prenda("gorro_navidad", "cabeza", "Gorro navideño", "Holiday Hat", 100, 2, ["rojo", "blanco"])
prenda("orejas_conejo", "cabeza", "Orejas de conejo", "Bunny Ears", 90, 2, ["rosa"], ["blanco", "negro"], "balancear")
prenda("cuerno_unicornio", "cabeza", "Cuerno de unicornio", "Unicorn Horn", 180, 4, ["rosa"], None, "brillar")
prenda("boina", "cabeza", "Boina", "Beret", 70, 1, None, ["rojo", "negro", "azul"])
prenda("casco_bombero", "cabeza", "Casco de bombero", "Firefighter Helmet", 140, 3, ["rojo", "oro"])
prenda("tiara", "cabeza", "Tiara", "Tiara", 190, 4, ["plata", "rosa"], None, "brillar")
prenda("bruja", "cabeza", "Sombrero de bruja", "Witch Hat", 150, 3, ["negro", "lila"])
prenda("vikingo", "cabeza", "Casco vikingo", "Viking Helmet", 170, 4, ["plata", "blanco"])

# ---- ojos ----
prenda("lentes_sol", "ojos", "Lentes de sol", "Sunglasses", 55, 1, ["negro"], ["negro", "rojo", "azul"])
prenda("lentes_corazon", "ojos", "Lentes corazón", "Heart Glasses", 90, 2, ["rosa"], ["rojo", "rosa"])
prenda("lentes_redondos", "ojos", "Lentes redondos", "Round Glasses", 65, 1, None, ["oro", "negro"])
prenda("lentes_estrella", "ojos", "Lentes estrella", "Star Glasses", 95, 2, None, ["amarillo", "lila"])
prenda("monoculo", "ojos", "Monóculo", "Monocle", 120, 3, ["oro"])
prenda("visor", "ojos", "Visor cibernético", "Cyber Visor", 220, 5, ["negro"], ["celeste", "rosa"], "parpadear")
prenda("gafas_buceo", "ojos", "Gafas de buceo", "Diving Goggles", 80, 2, ["amarillo", "celeste"])
prenda("parche", "ojos", "Parche pirata", "Eye Patch", 50, 1, ["negro"])

# ---- cuerpo ----
prenda("poleron", "cuerpo", "Polerón", "Hoodie", 110, 1, None, ["menta", "rosa", "gris", "azul"])
prenda("polera_estrella", "cuerpo", "Polera estrella", "Star Tee", 75, 1, ["oro"], ["amarillo", "celeste"])
prenda("overol", "cuerpo", "Overol", "Overalls", 130, 2, ["amarillo"], ["azul", "rosa"])
prenda("capa", "cuerpo", "Capa", "Cape", 220, 3, ["blanco"], ["rojo", "azul", "lila"], "ondear")
prenda("chaleco", "cuerpo", "Chaleco", "Vest", 90, 2, ["blanco"], ["rojo", "cafe"])
prenda("hawaiana", "cuerpo", "Camisa hawaiana", "Hawaiian Shirt", 120, 2, ["blanco", "amarillo"], ["celeste", "rojo"])
prenda("smoking", "cuerpo", "Esmoquin", "Tuxedo", 260, 5, ["blanco", "rojo"], ["negro"])
prenda("impermeable", "cuerpo", "Impermeable", "Raincoat", 120, 2, ["blanco"], ["amarillo", "rojo"])
prenda("sueter", "cuerpo", "Suéter", "Sweater", 100, 2, ["blanco"], ["rojo", "verde", "azul"])
prenda("futbol", "cuerpo", "Camiseta de fútbol", "Soccer Jersey", 110, 2, ["blanco"], ["azul", "rojo", "amarillo"])
prenda("tutu", "cuerpo", "Tutú", "Tutu", 140, 3, ["blanco"], ["rosa", "lila"])

# ---- espalda ----
prenda("alas_hada", "espalda", "Alas de hada", "Fairy Wings", 260, 4, None, ["celeste", "rosa"], "aletear")
prenda("alas_murcielago", "espalda", "Alas de murciélago", "Bat Wings", 240, 4, ["negro"], None, "aletear")
prenda("mochila", "espalda", "Mochila", "Backpack", 90, 1, ["cafe"], ["rojo", "azul", "verde"])
prenda("jetpack", "espalda", "Mochila cohete", "Jetpack", 380, 6, ["plata", "naranjo"], None, "llama")
prenda("alas_angel", "espalda", "Alas de ángel", "Angel Wings", 300, 5, ["blanco"], None, "aletear")
prenda("caparazon", "espalda", "Caparazón", "Turtle Shell", 150, 3, ["verde", "amarillo"])
prenda("alas_mariposa", "espalda", "Alas de mariposa", "Butterfly Wings", 280, 4, ["negro"], ["naranjo", "lila"], "aletear")

# ---- trajes completos (cubren cuerpo y cabeza) ----
prenda("ninja", "traje", "Traje ninja", "Ninja Suit", 600, 4, ["blanco"], ["negro", "rojo", "azul"], "ondear")
prenda("robot", "traje", "Traje de robot", "Robot Suit", 900, 6, ["celeste", "rojo"], ["plata", "oro"], "parpadear")
prenda("slime", "traje", "Traje de slime", "Slime Suit", 750, 5, None, ["verde", "rosa", "celeste"], "gelatina")
prenda("astronauta", "traje", "Traje de astronauta", "Astronaut Suit", 1100, 8, ["blanco", "naranjo", "celeste"])
prenda("dino", "traje", "Disfraz de dinosaurio", "Dino Costume", 700, 5, ["amarillo"], ["verde", "lila"], "balancear")
prenda("abeja", "traje", "Disfraz de abeja", "Bee Costume", 650, 4, ["amarillo", "negro", "blanco"], None, "aletear")
prenda("caballero", "traje", "Armadura de caballero", "Knight Armor", 1000, 7, ["plata", "rojo"], None, "ondear")
prenda("mago_traje", "traje", "Túnica de mago", "Wizard Robe", 800, 6, ["azul", "amarillo"], None, "brillar")
prenda("pinguino", "traje", "Disfraz de pingüino", "Penguin Costume", 600, 4, ["negro", "blanco", "naranjo"])
prenda("rana", "traje", "Disfraz de rana", "Frog Costume", 550, 3, ["verde", "blanco"])
prenda("unicornio", "traje", "Disfraz de unicornio", "Unicorn Costume", 850, 6, ["blanco", "rosa", "oro"], None, "brillar")
prenda("vampiro", "traje", "Traje de vampiro", "Vampire Suit", 700, 5, ["negro", "rojo"], None, "ondear")
prenda("payaso", "traje", "Traje de payaso", "Clown Suit", 500, 3, ["rojo", "amarillo", "azul"])
prenda("heroe", "traje", "Traje de superhéroe", "Superhero Suit", 900, 6, ["amarillo"], ["azul", "rojo"], "ondear")
prenda("momia", "traje", "Disfraz de momia", "Mummy Costume", 550, 4, ["blanco"])
prenda("calabaza", "traje", "Disfraz de calabaza", "Pumpkin Costume", 500, 3, ["naranjo", "verde"])
prenda("panda", "traje", "Disfraz de panda", "Panda Costume", 650, 4, ["blanco", "negro"])
prenda("tiburon", "traje", "Disfraz de tiburón", "Shark Costume", 700, 5, ["gris", "blanco"])

# ---------------- diseños propios de cada variante ----------------
# El dueño pidió que ninguna compra sea "solo otro color": cada variante de una misma prenda trae piezas distintas
# (atuendos.gd las arma según "v"). Nombre = prenda + diseño (+ color si hace falta para distinguir).
DISENOS = {
    "bufanda": [None, ("con flecos largos", "Fringed"), ("gruesa con pompones", "Chunky Pom-pom"), ("a rayas de lana", "Striped Wool")],
    "mono": [None, ("gigante de lunares", "Giant Polka-dot"), ("de mariposa", "Butterfly")],
    "panuelo": [None, ("de vaquero", "Cowboy"), ("con nudo de lado", "Side-knot")],
    "corbata": [None, ("a rayas ancha", "Wide Striped")],
    "cascabel": [None, ("de tres campanas", "Triple")],
    "gorro_lana": [None, ("con orejeras y trenzas", "Earflap"), ("de gatito", "Kitty"), ("largo de duende", "Long Elf")],
    "gorra": [None, ("al revés", "Backwards"), ("con orejas de oso", "Bear-ear"), ("con cresta de dino", "Dino-spike")],
    "sombrero_copa": [None, ("alto con conejito", "Tall Bunny")],
    "corona": [None, ("de hielo", "Ice")],
    "flor": [None, ("margarita gigante", "Giant Daisy"), ("ramo de tres", "Triple Bouquet")],
    "audifonos": [None, ("con orejas de gato", "Cat-ear"), ("gamer con micrófono", "Gamer Mic")],
    "vaquero": [None, ("de sheriff", "Sheriff")],
    "mago": [None, ("doblado con cascabel", "Bent Bell")],
    "corona_flores": [None, ("con cintas de hada", "Fairy Ribbon")],
    "cuernos": [None, ("de carnero", "Ram")],
    "helice": [None, ("doble", "Twin")],
    "orejas_conejo": [None, ("caídas", "Lop")],
    "boina": [None, ("de pintor", "Painter"), ("con insignia", "Badge")],
    "lentes_sol": [None, ("de aviador", "Aviator"), ("deportivos", "Sport")],
    "lentes_corazon": [None, ("gigantes", "Giant")],
    "lentes_redondos": [None, ("con cadena", "Chain")],
    "lentes_estrella": [None, ("de rockstar con alas", "Rockstar Wing")],
    "visor": [None, ("con antenas", "Antenna")],
    "poleron": [None, ("con orejas de oso", "Bear-ear"), ("universitario", "Varsity"), ("de dragón", "Dragon")],
    "polera_estrella": [None, ("con rayo", "Lightning")],
    "overol": [None, ("con parches de corazón", "Heart-patch")],
    "capa": [None, ("real con armiño", "Royal"), ("con capucha estrellada", "Starry Hood")],
    "chaleco": [None, ("de explorador", "Explorer")],
    "hawaiana": [None, ("con collar de flores", "Lei")],
    "impermeable": [None, ("con capucha de patito", "Duck-hood")],
    "sueter": [None, ("navideño con reno", "Holiday Reindeer"), ("de cuello alto", "Turtleneck")],
    "futbol": [None, ("de arquero con guantes", "Goalkeeper"), ("de capitán", "Captain")],
    "tutu": [None, ("de dos pisos con estrellas", "Starry Two-tier")],
    "alas_hada": [None, ("de cristal largas", "Crystal")],
    "mochila": [None, ("con osito", "Teddy"), ("de explorador", "Explorer")],
    "alas_mariposa": [None, ("con colas largas", "Swallowtail")],
    "ninja": [None, ("con espada", "Sword"), ("con estrellas ninja", "Shuriken")],
    "robot": [None, ("con propulsores", "Rocket")],
    "slime": [None, ("rey con corona", "King"), ("de agua con burbujas", "Bubbly")],
    "dino": [None, ("tricerátops", "Triceratops")],
    "heroe": [None, ("con rayo y botas", "Lightning")],
}
_cuenta = {}
for r in ropa:
    f_ = r["forma"]
    if f_ not in DISENOS:
        continue
    i = _cuenta.get(f_, 0)
    _cuenta[f_] = i + 1
    r["v"] = i
    d = DISENOS[f_][i] if i < len(DISENOS[f_]) else None
    if d:
        base_es = r["nombre"]
        base_en = r["en"]
        # quitar el color del nombre (ya no hace falta: el diseño lo distingue)
        for k, (hx, en_c, es_c) in C.items():
            if base_es.endswith(" " + es_c):
                base_es = base_es[: -len(es_c) - 1]
            if base_en.startswith(en_c + " "):
                base_en = base_en[len(en_c) + 1:]
        r["nombre"] = base_es + " " + d[0]
        r["en"] = d[1] + " " + base_en
assert all(len(set(r["nombre"] for r in ropa if r["forma"] == f_)) == n for f_, n in _cuenta.items()), "nombres repetidos"

# ---------------- decoración: 30+ por habitación ----------------
def v(id_, es, en, precio, **p):
    return {"id": id_, "nombre": es, "en": en, "precio": precio, "p": p}

PATRONES = [("liso", "lisa", "Plain"), ("rayas", "a rayas", "Striped"), ("lunares", "con lunares", "Polka Dot"),
            ("cuadros", "a cuadros", "Checkered"), ("estrellas", "con estrellas", "Starry"),
            ("corazones", "con corazones", "Hearts"), ("ladrillo", "de ladrillo", "Brick"), ("tablas", "de tablas", "Wood Panel"),
            ("ondas", "con ondas", "Wavy"), ("rombos", "con rombos", "Diamond"), ("hojas", "con hojas", "Leafy"),
            ("nubes", "con nubes", "Cloudy")]
PALETAS = {
    "cocina": [("#fff1dc", "#f3d9b6", "crema", "Cream"), ("#cdeee2", "#a9dcc8", "menta", "Mint"), ("#ffe1e8", "#ffc2d1", "cerezo", "Cherry"),
               ("#fff6c2", "#ffe58a", "limón", "Lemon"), ("#dbe9ff", "#b9d2ff", "cielo", "Sky"), ("#efe2ff", "#d8c4ff", "lavanda", "Lavender")],
    "habitacion": [("#dccff5", "#c8b6f0", "lavanda", "Lavender"), ("#2f3170", "#454a9c", "noche", "Night"), ("#ffdcc8", "#ffc6a8", "durazno", "Peach"),
                   ("#d7f2e8", "#b4e3d1", "menta", "Mint"), ("#ffe8f1", "#ffcfe2", "algodón", "Cotton"), ("#fff3d6", "#ffe1a1", "vainilla", "Vanilla")],
    "bano": [("#dff3fb", "#bfe1ee", "azulejo", "Tile"), ("#ffd1c4", "#ffb7a3", "coral", "Coral"), ("#e2f7e1", "#c3ebc0", "pistacho", "Pistachio"),
             ("#f0e6ff", "#dccaff", "uva", "Grape"), ("#fffbe6", "#fff0b3", "arena", "Sand"), ("#e8edf5", "#ccd6e6", "nube", "Cloud")],
}

def paredes(hab, n):
    """Una pared por patrón (los 12) con colores repartidos, más alguna lisa extra."""
    out = []
    pal = PALETAS[hab]
    for i in range(n):
        pat, pes, pen = PATRONES[i % len(PATRONES)]
        c1, c2, ces, cen = pal[(i * 5) % len(pal)] if i else pal[0]
        pid = f"{pat}_{ces.replace('ó', 'o').replace('í', 'i')}"
        es = f"Pared {ces} {pes}" if pat != "liso" else f"Pared {ces}"
        en = f"{pen} {cen} Wall" if pat != "liso" else f"{cen} Wall"
        out.append(v(pid, es, en, 0 if i == 0 else 40 + 15 * (i % 6), patron=pat, c1=c1, c2=c2))
    return out

# Cada estilo tiene FORMA propia (no solo otro color): el dueño quiere que toda compra se note.
pisos = [v("madera", "Tablas de madera", "Wood Planks", 0, tipo="tablas", c1="#d4a373", c2="#b9875a"),
         v("parquet", "Parquet en espiga", "Herringbone Parquet", 90, tipo="espiga", c1="#c58a55", c2="#9c6a3c"),
         v("ajedrez", "Baldosa ajedrez", "Checker Tiles", 60, tipo="ajedrez", c1="#f4f1ec", c2="#3c3f58"),
         v("hexagonos", "Baldosa panal", "Honeycomb Tiles", 90, tipo="hexagonos", c1="#fff6dc", c2="#ffcf6a"),
         v("piedra", "Piso de piedras", "Stone Path Floor", 110, tipo="piedra", c1="#d9d2c6", c2="#a89f92"),
         v("mullida", "Alfombra peluda", "Shaggy Carpet", 120, tipo="mullida", c1="#b9a2f0", c2="#d4c4ff"),
         v("mosaico", "Mosaico de colores", "Color Mosaic", 130, tipo="mosaico", c1="#f2f6fb", c2="#7fc8ff")]

deco = {
    "cocina": {
        "pared": paredes("cocina", 12),
        "piso": pisos,
        "nevera": [v("clasica", "Nevera clásica", "Classic Fridge", 0, forma="clasica", c="#f4f6fa"),
                   v("retro", "Nevera retro", "Retro Fridge", 120, forma="retro", c="#ffb3c1"),
                   v("doble", "Nevera de dos puertas", "Double-Door Fridge", 180, forma="doble", c="#cfd6e2"),
                   v("vintage", "Nevera con pegatinas", "Sticker Fridge", 140, forma="vintage", c="#9fe0c8"),
                   v("robot", "Nevera robot", "Robot Fridge", 260, forma="robot", c="#ffd86a"),
                   v("magica", "Nevera de cristal", "Crystal Fridge", 300, forma="magica", c="#b49cff")],
        "mesa": [v("madera", "Mesa de madera", "Wooden Table", 0, forma="cuadrada", c="#c08552"),
                 v("azul", "Mesa redonda", "Round Table", 90, forma="redonda", c="#7fb8ff"),
                 v("hongo", "Mesa hongo", "Mushroom Table", 150, forma="hongo", c="#ff6b6b"),
                 v("dulces", "Mesa de cumpleaños", "Birthday Table", 220, forma="dulces", c="#ffadc4"),
                 v("picnic", "Mesa de picnic", "Picnic Table", 140, forma="picnic", c="#b0844f"),
                 v("barra", "Barra con taburetes", "Breakfast Bar", 190, forma="barra", c="#f2efe9")],
        "planta": [v("ninguna", "Sin planta", "No Plant", 0, forma="nada"),
                   v("cactus", "Cactus", "Cactus", 40, forma="cactus", c="#5fae4a"),
                   v("helecho", "Helecho", "Fern", 50, forma="helecho", c="#4f9a3e"),
                   v("girasol", "Girasol", "Sunflower", 60, forma="girasol", c="#ffcf4a"),
                   v("flor_magica", "Flor mágica", "Magic Flower", 180, forma="flor_magica", c="#c77dff"),
                   v("bonsai", "Bonsái", "Bonsai", 160, forma="bonsai", c="#4f9a3e"),
                   v("carnivora", "Planta carnívora", "Snappy Plant", 200, forma="carnivora", c="#7cc96a")],
    },
    "habitacion": {
        "pared": paredes("habitacion", 12),
        "piso": pisos[:6],
        "cama": [v("nido", "Nido", "Nest", 0, forma="nido"), v("nube", "Cama nube", "Cloud Bed", 150, forma="nube"),
                 v("cohete", "Cohete Avellana", "Hazel Rocket", 220, forma="cohete"),
                 v("concha", "Cama concha", "Shell Bed", 180, forma="concha", c="#ffc2d6"),
                 v("hoja", "Cama hoja", "Leaf Bed", 140, forma="hoja", c="#7cc96a"),
                 v("castillo", "Cama castillo", "Castle Bed", 300, forma="castillo", c="#c9b8f0"),
                 v("arcoiris", "Cama arcoíris", "Rainbow Bed", 320, forma="arcoiris")],
        "lampara": [v("hongo", "Lámpara hongo", "Mushroom Lamp", 0, forma="hongo", c="#ff6b6b"),
                    v("luna", "Lámpara luna", "Moon Lamp", 90, forma="luna", c="#e9f0ff"),
                    v("estrella", "Lámpara estrella", "Star Lamp", 110, forma="estrella", c="#ffd36e"),
                    v("farol", "Farol de bellota", "Acorn Lantern", 120, forma="farol", c="#ffcf80"),
                    v("lava", "Lámpara de lava", "Lava Lamp", 130, forma="lava", c="#ff7ac0"),
                    v("disco", "Bola disco", "Disco Ball", 280, forma="disco", c="#e8eef7")],
        "alfombra": [v("redonda", "Alfombra redonda", "Round Rug", 0, forma="redonda", c="#ffb3c7"),
                     v("estrella", "Alfombra estrella", "Star Rug", 70, forma="estrella", c="#ffd36e"),
                     v("oso", "Alfombra osito", "Teddy Rug", 110, forma="oso", c="#e2b98a"),
                     v("corazon", "Alfombra corazón", "Heart Rug", 80, forma="corazon", c="#ff8fb3"),
                     v("nube", "Alfombra nube", "Cloud Rug", 80, forma="nube", c="#f4f6ff"),
                     v("arcoiris", "Alfombra arcoíris", "Rainbow Rug", 120, forma="arcoiris", c="#ff6b6b")],
    },
    "patio": {
        "fondo": [v("dia", "Día", "Day", 0, cielo="dia"), v("atardecer", "Atardecer", "Sunset", 80, cielo="atardecer"),
                  v("noche", "Noche", "Night", 100, cielo="noche"), v("galaxia", "Galaxia Nova", "Nova Galaxy", 200, cielo="galaxia"),
                  v("aurora", "Aurora", "Aurora", 180, cielo="aurora"), v("nublado", "Nublado", "Cloudy", 60, cielo="nublado"),
                  v("amanecer", "Amanecer", "Sunrise", 80, cielo="amanecer"), v("dulce", "Cielo de algodón", "Candy Sky", 150, cielo="dulce"),
                  v("lluvia_estrellas", "Lluvia de estrellas", "Star Shower", 260, cielo="lluvia_estrellas")],
        "cerca": [v("blanca", "Cerca blanca", "White Fence", 0, forma="estacas", c="#ffffff"),
                  v("madera", "Cerca de troncos", "Log Fence", 50, forma="troncos", c="#a8743f"),
                  v("caramelo", "Cerca de caramelo", "Candy Cane Fence", 120, forma="caramelo", c="#ff5a6e"),
                  v("seto", "Seto con flores", "Flower Hedge", 90, forma="seto", c="#5fae4a"),
                  v("piedra", "Muro de piedra", "Stone Wall", 90, forma="piedra", c="#b8b2a7")],
        "arbol": [v("roble", "Roble con columpio", "Oak Tree", 0, forma="roble", c="#5fae4a"),
                  v("cerezo", "Cerezo llorón", "Weeping Cherry", 140, forma="cerezo", c="#ffc2d6"),
                  v("pino", "Pino nevado", "Snowy Pine", 100, forma="pino", c="#3f8f4a"),
                  v("palmera", "Palmera con cocos", "Coconut Palm", 130, forma="palmera", c="#5fbf5a"),
                  v("otono", "Arce de otoño", "Autumn Maple", 130, forma="arce", c="#ff8a3d"),
                  v("magico", "Árbol de cristal", "Crystal Tree", 280, forma="cristal", c="#b49cff")],
        "pasto": [v("verde", "Pasto", "Grass", 0, forma="pasto", c="#8fd16a"),
                  v("primavera", "Jardín de tulipanes", "Tulip Garden", 90, forma="tulipanes", c="#a5de7c"),
                  v("otono", "Hojas y hongos", "Leaves & Mushrooms", 90, forma="otono", c="#c9b26a"),
                  v("nieve", "Nieve con muñeco", "Snow & Snowman", 160, forma="nieve", c="#f2f6fb"),
                  v("arena", "Playa", "Beach", 150, forma="playa", c="#f5dfa8")],
        "juguete": [v("ninguno", "Nada", "Nothing", 0, forma="nada"), v("columpio", "Columpio", "Swing", 120, forma="columpio", c="#ff6b6b"),
                    v("tobogan", "Tobogán", "Slide", 150, forma="tobogan", c="#4aa8ff"),
                    v("piscina", "Piscinita", "Kiddie Pool", 130, forma="piscina", c="#7fd8ff"),
                    v("casita", "Casita de perro", "Doghouse", 110, forma="casita", c="#e2574c"),
                    v("telescopio", "Telescopio", "Telescope", 200, forma="telescopio", c="#5b5f8f"),
                    v("fuente", "Fuente", "Fountain", 220, forma="fuente", c="#e9e4dc"),
                    v("fogata", "Fogata", "Campfire", 200, forma="fogata", c="#7a4b2a")],
    },
    "bano": {
        "pared": paredes("bano", 12) + [v("acuario", "Pared acuario", "Aquarium Wall", 300, patron="acuario", c1="#dff3fb", c2="#ffffff")],
        "piso": [pisos[0], pisos[2], pisos[3], pisos[4], pisos[6]],
        "banera": [v("clasica", "Bañera clásica", "Classic Tub", 0, forma="clasica", c="#ffffff"),
                   v("dorada", "Bañera de patas doradas", "Clawfoot Tub", 150, forma="garras", c="#fff4f6"),
                   v("barril", "Tina de barril", "Barrel Tub", 140, forma="barril", c="#b0844f"),
                   v("concha", "Bañera concha", "Seashell Tub", 220, forma="concha", c="#ffc2d6"),
                   v("negra", "Bañera moderna", "Modern Tub", 200, forma="moderna", c="#3a3d4a"),
                   v("jacuzzi", "Jacuzzi de luz", "Glow Jacuzzi", 260, forma="jacuzzi", c="#e8f4ff")],
        "cortina": [v("rayas", "Cortina a rayas", "Striped Curtain", 0, forma="rayas", c1="#7fc8ff", c2="#ffffff"),
                    v("burbujas", "Cortina burbujas", "Bubble Curtain", 60, forma="burbujas", c1="#b8f0ff", c2="#ffffff"),
                    v("estrellas", "Cortina estrellas", "Star Curtain", 90, forma="estrellas", c1="#4b4fa8", c2="#ffd36e"),
                    v("cuentas", "Cortina de cuentas", "Bead Curtain", 110, forma="cuentas", c1="#ff9fb8", c2="#ffe066"),
                    v("patitos", "Cortina patitos", "Duck Curtain", 80, forma="patitos", c1="#fff3b0", c2="#ffd84a"),
                    v("olas", "Cortina de olas", "Wave Curtain", 100, forma="olas", c1="#3cc9c0", c2="#ffffff"),
                    v("bambu", "Persiana de bambú", "Bamboo Blind", 120, forma="bambu", c1="#c9b26a", c2="#9c8648"),
                    v("dosel", "Cortina con lazo", "Tied Drape", 130, forma="dosel", c1="#c3a6ff", c2="#ff8fb3"),
                    v("luces", "Cortina de luces", "Fairy Light Curtain", 160, forma="luces", c1="#fff3f8", c2="#fff3f8")],
    },
}

pociones = [
    {"id": "gigante", "nombre": "Poción gigante", "en": "Giant Potion", "precio": 30, "color": "#ff8a5c", "segundos": 40},
    {"id": "mini", "nombre": "Poción mini", "en": "Mini Potion", "precio": 30, "color": "#6cc9ff", "segundos": 40},
    {"id": "arcoiris", "nombre": "Poción arcoíris", "en": "Rainbow Potion", "precio": 50, "color": "#c77dff", "segundos": 40},
    {"id": "fantasma", "nombre": "Poción fantasma", "en": "Ghost Potion", "precio": 40, "color": "#d9e4ff", "segundos": 40},
    {"id": "brillo", "nombre": "Poción estelar", "en": "Star Potion", "precio": 45, "color": "#ffd36e", "segundos": 40},
    {"id": "capibara", "nombre": "Poción capibara", "en": "Capybara Potion", "precio": 120, "color": "#b07a45", "segundos": 180},
]

bailes = [{"id": "saltitos", "nombre": "Saltitos", "en": "Hops", "precio": 0, "musica": "musica_dia_0"},
          {"id": "robot", "nombre": "Robot Nova", "en": "Nova Robot", "precio": 90, "musica": "musica_prisma_0"},
          {"id": "trompo", "nombre": "Trompo", "en": "Spinning Top", "precio": 140, "musica": "musica_prisma_0"},
          {"id": "aplausos", "nombre": "Aplausos", "en": "Clapping", "precio": 60, "musica": "musica_cuento_0"}]

comida = [{"id": "bellota", "nombre": "Bellota", "en": "Acorn", "precio": 2, "llena": 8, "color": "#c58a4a"},
          {"id": "fresa", "nombre": "Frutilla", "en": "Strawberry", "precio": 6, "llena": 14, "color": "#ff5a6e"},
          {"id": "galleta", "nombre": "Galleta", "en": "Cookie", "precio": 8, "llena": 18, "color": "#e2a95f"},
          {"id": "nuez", "nombre": "Nuez", "en": "Walnut", "precio": 5, "llena": 12, "color": "#a8743f"},
          {"id": "pastel", "nombre": "Pastel", "en": "Cake", "precio": 18, "llena": 35, "color": "#ffc2d6"},
          {"id": "helado", "nombre": "Helado", "en": "Ice Cream", "precio": 12, "llena": 22, "color": "#bff0e4"}]

# ---------------- regalos por nivel (no se venden: llegan al subir de nivel) ----------------
# Trajes y accesorios exclusivos (tema espacial), comidas exóticas con efecto, naves para Cohete Avellana,
# dorsos de cartas para Memoria y nubes para Salto Nova. Del nivel 2 al 25 siempre hay algo nuevo.
EXCLUSIVAS = [  # forma, zona, es, en, nivel, colores, anim
    ("alien", "traje", "Traje de alien", "Alien Suit", 4, ["#7be08a", "#2b2633", "#c3f7ff"], "balancear"),
    ("casco_ovni", "cabeza", "Gorro ovni", "UFO Hat", 7, ["#cfd6e2", "#7fd8ff", "#ff8fe0"], "flotar"),
    ("astronauta_nova", "traje", "Astronauta Nova", "Nova Astronaut", 10, ["#6c4ad6", "#ffcf4a", "#7fd8ff"], "brillar"),
    ("visor_nebulosa", "ojos", "Visor nebulosa", "Nebula Visor", 12, ["#2b2633", "#ff8fe0", "#7fd8ff"], "parpadear"),
    ("anillo_planetas", "cabeza", "Anillo de planetas", "Planet Ring", 15, ["#ffcf4a", "#ff8f6b", "#7fc8ff"], "girar"),
    ("alas_cometa", "espalda", "Alas de cometa", "Comet Wings", 18, ["#7fd8ff", "#ffffff", "#c3a6ff"], "llama"),
    ("capa_galaxia", "cuerpo", "Capa galaxia", "Galaxy Cape", 20, ["#241a5c", "#ff8fe0", "#7fd8ff"], "ondear"),
    ("dragon_estelar", "traje", "Dragón estelar", "Star Dragon", 23, ["#3a2a8c", "#7fd8ff", "#ffcf4a"], "aletear"),
    ("corona_sol", "cabeza", "Corona del sol", "Sun Crown", 25, ["#ffcf4a", "#ff8f3a", "#fff3c4"], "girar"),
]
for fo, zo, es, en, nv, cs, an in EXCLUSIVAS:
    ropa.append({"id": fo, "forma": fo, "zona": zo, "nombre": es, "en": en, "precio": 0, "nivel": nv, "c": cs,
                 "anim": an, "regalo": True})

COMIDA_EXOTICA = [  # id, es, en, nivel, precio, llena, color, efecto
    ("fruta_estelar", "Fruta estelar", "Star Fruit", 3, 30, 20, "#ffcf4a", "brillo"),
    ("chile_fuego", "Chile de fuego", "Fire Pepper", 6, 30, 16, "#ff4d3a", "fuego"),
    ("helado_cosmico", "Helado cósmico", "Cosmic Ice Cream", 10, 35, 24, "#7fd8ff", "frio"),
    ("hongo_gigante", "Hongo gigante", "Giant Mushroom", 13, 40, 30, "#e2574c", "gigante"),
    ("gelatina_fantasma", "Gelatina fantasma", "Ghost Jelly", 17, 40, 22, "#c3f7ff", "fantasma"),
    ("algodon_arcoiris", "Algodón arcoíris", "Rainbow Candy Floss", 21, 45, 22, "#ff8fe0", "arcoiris"),
    ("caramelo_mini", "Caramelo mini", "Tiny Candy", 25, 45, 18, "#b49cff", "mini"),
]
comida_exotica = [{"id": i, "nombre": es, "en": en, "nivel": nv, "precio": pr, "llena": ll, "color": co, "efecto": ef,
                   "regalo": True} for i, es, en, nv, pr, ll, co, ef in COMIDA_EXOTICA]

naves = [  # Cohete Avellana
    {"id": "avellana", "nombre": "Cohete Avellana", "en": "Hazel Rocket", "nivel": 1},
    {"id": "platillo", "nombre": "Platillo volador", "en": "Flying Saucer", "nivel": 5},
    {"id": "dorado", "nombre": "Cohete dorado", "en": "Golden Rocket", "nivel": 9},
    {"id": "ovni_alien", "nombre": "Nave alien", "en": "Alien Ship", "nivel": 14},
    {"id": "cristal", "nombre": "Nave de cristal", "en": "Crystal Ship", "nivel": 19},
    {"id": "estrella_nova", "nombre": "Estrella Nova", "en": "Nova Star", "nivel": 24},
]
cartas = [  # dorso de las cartas de Memoria
    {"id": "bellota", "nombre": "Cartas bellota", "en": "Acorn Cards", "nivel": 1},
    {"id": "estrellas", "nombre": "Cartas estrelladas", "en": "Starry Cards", "nivel": 2},
    {"id": "galaxia", "nombre": "Cartas galaxia", "en": "Galaxy Cards", "nivel": 8},
    {"id": "dulces", "nombre": "Cartas de dulce", "en": "Candy Cards", "nivel": 16},
    {"id": "neon", "nombre": "Cartas neón", "en": "Neon Cards", "nivel": 22},
]
nubes = [  # plataformas de Salto Nova
    {"id": "algodon", "nombre": "Nubes de algodón", "en": "Cotton Clouds", "nivel": 1},
    {"id": "arcoiris", "nombre": "Nubes arcoíris", "en": "Rainbow Clouds", "nivel": 11},
    {"id": "planetas", "nombre": "Planetas", "en": "Planets", "nivel": 20},
]

# recompensas[nivel] = lista de {tipo, id}
recompensas = {}
for r in ropa:
    if r.get("regalo"):
        recompensas.setdefault(str(r["nivel"]), []).append({"tipo": "ropa", "id": r["id"]})
for c in comida_exotica:
    recompensas.setdefault(str(c["nivel"]), []).append({"tipo": "comida", "id": c["id"]})
for tipo, lista in (("nave", naves), ("cartas", cartas), ("nubes", nubes)):
    for x in lista:
        if x["nivel"] > 1:
            recompensas.setdefault(str(x["nivel"]), []).append({"tipo": tipo, "id": x["id"]})
assert all(str(n) in recompensas for n in range(2, 26)), sorted(set(range(2, 26)) - set(int(k) for k in recompensas))

juegos = [{"id": "salto", "nombre": "Salto Nova", "en": "Nova Jump", "icono": "salto"},
          {"id": "lluvia", "nombre": "Lluvia de bellotas", "en": "Acorn Rain", "icono": "bellota"},
          {"id": "memoria", "nombre": "Memoria", "en": "Memory", "icono": "memoria"},
          {"id": "cohete", "nombre": "Cohete Avellana", "en": "Hazel Rocket", "icono": "cohete"},
          {"id": "pelota", "nombre": "Pelota", "en": "Ball", "icono": "pelota"}]

# precios en pesos chilenos (Google Play mostrará el precio local de cada país)
paquetes = [
    {"id": "bellotas_500", "nombre": "Puñado de bellotas", "en": "Handful of Acorns", "bellotas": 500, "precio": "$990", "tag": ""},
    {"id": "bellotas_1200", "nombre": "Bolsa de bellotas", "en": "Bag of Acorns", "bellotas": 1200, "precio": "$1.990", "tag": "+20%"},
    {"id": "bellotas_3500", "nombre": "Cofre de bellotas", "en": "Chest of Acorns", "bellotas": 3500, "precio": "$4.990", "tag": "popular"},
    {"id": "bellotas_8000", "nombre": "Carreta de bellotas", "en": "Cart of Acorns", "bellotas": 8000, "precio": "$9.990", "tag": "+60%"},
    {"id": "bellotas_20000", "nombre": "Montaña de bellotas", "en": "Mountain of Acorns", "bellotas": 20000, "precio": "$19.990", "tag": "mejor"},
]
especiales = [
    {"id": "pack_inicio", "nombre": "Pack de bienvenida", "en": "Welcome Pack", "bellotas": 2500, "pociones": {"capibara": 3},
     "precio": "$990", "una_vez": True},
    {"id": "capibara_permanente", "nombre": "Capibara para siempre", "en": "Capybara Forever", "bellotas": 0,
     "precio": "$1.499", "una_vez": True},
]

# decoraciones con efectos (animación, luces o partículas): la tarjeta muestra una chispita
CON_EFECTO = {"magica", "dulces", "flor_magica", "girasol", "arcoiris", "disco", "farol", "robot", "carnivora", "luna", "estrella", "lava", "noche",
              "aurora", "galaxia", "lluvia_estrellas", "cerezo", "otono", "magico", "nieve", "columpio", "piscina", "fuente",
              "fogata", "acuario", "jacuzzi", "luces", "clasica", "dorada", "rosa", "menta", "negra"}
for h, slots in deco.items():
    for sl, vs in slots.items():
        for x in vs:
            if x["id"] in CON_EFECTO and (sl not in ("pared", "piso", "cerca", "cortina", "nevera", "mesa") or x["id"] in ("acuario", "luces", "magica", "dulces")):
                x["fx"] = True

# Decoraciones que existían en la versión 0.3 y se rediseñaron en la 0.4: quien las compró recibe de vuelta
# sus bellotas (Estado._limpiar). Clave = lo que queda en "tengo"; valor = precio pagado.
REEMBOLSOS = {
    "deco_cocina_piso_madera_oscura": 60, "deco_cocina_piso_ajedrez_rosa": 70, "deco_cocina_piso_ajedrez_menta": 70,
    "deco_cocina_piso_alfombra_azul": 80, "deco_cocina_piso_alfombra_lila": 80, "deco_cocina_nevera_menta": 120,
    "deco_cocina_nevera_negra": 160, "deco_cocina_nevera_amarilla": 120, "deco_cocina_mesa_rosa": 90,
    "deco_cocina_mesa_blanca": 80, "deco_habitacion_piso_madera_oscura": 60, "deco_habitacion_piso_ajedrez_rosa": 70,
    "deco_habitacion_piso_ajedrez_menta": 70, "deco_habitacion_piso_alfombra_azul": 80,
    "deco_habitacion_cama_nube_magica": 320, "deco_habitacion_lampara_hongo_azul": 70,
    "deco_habitacion_alfombra_redonda_azul": 50, "deco_patio_cerca_rosa": 60, "deco_bano_piso_ajedrez_rosa": 70,
    "deco_bano_piso_ajedrez_menta": 70, "deco_bano_banera_rosa": 120, "deco_bano_banera_menta": 120,
    "deco_bano_cortina_rayas_rosa": 50, "deco_bano_cortina_mar": 70, "deco_bano_cortina_lila": 50,
    "deco_bano_cortina_noche": 90,
}

cat = {"_nota": "GENERADO por godot/tools/generar_catalogo.py — no editar a mano.",
       "ropa": ropa, "pociones": pociones, "bailes": bailes, "comida": comida, "deco": deco, "juegos": juegos,
       "paquetes": paquetes, "especiales": especiales, "comida_exotica": comida_exotica, "naves": naves,
       "cartas": cartas, "nubes": nubes, "recompensas": recompensas, "nivel_compra": {"base": 1200, "por_nivel": 300}, "reembolsos": REEMBOLSOS, "regalo_diario": [20, 30, 40, 50, 60, 80, 150],
       "bellotas_gratis": {"max": 5, "minutos": 30}}

with open(os.path.join(RAIZ, "data", "catalogo.json"), "w", encoding="utf-8") as f:
    json.dump(cat, f, ensure_ascii=False, indent=1)

# ---------------- listado legible ----------------
L = ["# Pocket Pip — catálogo completo", "", "Generado por `godot/tools/generar_catalogo.py`. Precios en bellotas.", ""]
zonas = ["cabeza", "ojos", "cuello", "cuerpo", "espalda", "traje"]
L.append(f"## Ropa ({len(ropa)} prendas)")
for z in zonas:
    items = [r for r in ropa if r["zona"] == z]
    L.append(f"\n### {z.capitalize()} ({len(items)})")
    for r in items:
        a = f" · animación: {r['anim']}" if r["anim"] else ""
        L.append(f"- [x] {r['nombre']} / {r['en']} — {r['precio']} (nivel {r['nivel']}){a}")
tot = 0
for h, slots in deco.items():
    n = sum(len(x) for x in slots.values())
    tot += n
    L.append(f"\n## Decoración: {h} ({n} estilos)")
    for s, vs in slots.items():
        L.append(f"- **{s}** ({len(vs)}): " + ", ".join(x["nombre"] for x in vs))
L.append(f"\nTotal decoración: {tot}")
L.append(f"\n## Pociones ({len(pociones)})")
for p in pociones:
    L.append(f"- [x] {p['nombre']} — {p['precio']} bellotas, {p['segundos']} s")
L.append("- [x] Capibara para siempre — $1.499 (compra con dinero real; en la versión de prueba es gratis)")
L.append("\n## Regalos por nivel (no se venden)")
for n in range(2, 26):
    nom = []
    for x in recompensas[str(n)]:
        src = {"ropa": ropa, "comida": comida_exotica, "nave": naves, "cartas": cartas, "nubes": nubes}[x["tipo"]]
        nom.append(next(y["nombre"] for y in src if y["id"] == x["id"]))
    L.append(f"- [x] Nivel {n}: " + ", ".join(nom))
L.append("\nSubir de nivel pagando: 1.200 bellotas + 300 por cada nivel (nivel 10 → 11: 3.900).")
L.append(f"\n## Minijuegos ({len(juegos)})")
for j in juegos:
    L.append(f"- [x] {j['nombre']}")
L.append("\n## Tienda (pesos chilenos)")
for p in paquetes + especiales:
    L.append(f"- [x] {p['nombre']} — {p['precio']}" + (f" ({p['bellotas']} bellotas)" if p["bellotas"] else ""))
with open(os.path.join(os.path.dirname(RAIZ), "docs", "CATALOGO.md"), "w", encoding="utf-8") as f:
    f.write("\n".join(L) + "\n")
print("ropa", len(ropa), "| deco", {h: sum(len(x) for x in s.values()) for h, s in deco.items()})
