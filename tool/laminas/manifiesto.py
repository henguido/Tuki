"""Escribe chapter.json con las 60 láminas a partir de las medidas de
tool/laminas/validacion y de los textos de cada tema.

    python tool/laminas/manifiesto.py

El estado de cada lámina sale de tool/laminas/aprobacion.json (lo escribe la
prueba test/laminas_test.dart con el motor real): solo las aprobadas quedan
como `available`; el resto se registra como `planned`.
"""

import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
CAPITULO = RAIZ / 'assets/chapters/bosque-nuboso/chapter.json'
VALIDACION = RAIZ / 'tool/laminas/validacion'
APROBACION = RAIZ / 'tool/laminas/aprobacion.json'

CONTENT_VERSION = 3

# (tema, título es, título en, descripción es, descripción en, dato es, dato en)
TEMAS = [
    ('rana-en-la-hoja', 'La rana en la hoja', 'The Frog on the Leaf',
     'Una rana descansa sobre una hoja.', 'A frog rests on a leaf.',
     'Muchas ranas del bosque duermen de día sobre las hojas y salen de noche.',
     'Many forest frogs sleep on leaves during the day and come out at night.'),
    ('mariposa', 'La mariposa', 'The Butterfly',
     'Una mariposa con las alas abiertas.', 'A butterfly with its wings open.',
     'Las mariposas sienten el sabor con las patas.',
     'Butterflies taste with their feet.'),
    ('colibri', 'El colibrí', 'The Hummingbird',
     'Un colibrí vuela junto a una flor.', 'A hummingbird flies next to a flower.',
     'El colibrí puede volar hacia atrás.',
     'A hummingbird can fly backwards.'),
    ('tucan', 'El tucán', 'The Toucan',
     'Un tucán posado en una rama.', 'A toucan perched on a branch.',
     'El pico del tucán es muy grande, pero pesa poco.',
     "A toucan's beak is very big, but it is light."),
    ('flor-tropical', 'La flor tropical', 'The Tropical Flower',
     'Una flor de hibisco con sus hojas.', 'A hibiscus flower with its leaves.',
     'Muchas flores de hibisco duran abiertas un solo día.',
     'Many hibiscus flowers stay open for just one day.'),
    ('quetzal', 'El quetzal', 'The Quetzal',
     'Un quetzal posado en una rama, con su cola larga.',
     'A quetzal perched on a branch, with its long tail.',
     'El quetzal vive en bosques húmedos y tiene unas plumas de cola muy largas.',
     'The quetzal lives in humid forests and has very long tail feathers.'),
    ('perezoso', 'El perezoso', 'The Sloth',
     'Un perezoso cuelga de una rama.', 'A sloth hangs from a branch.',
     'El perezoso se mueve muy despacio y pasa casi toda su vida en los árboles.',
     'The sloth moves very slowly and spends almost all its life in the trees.'),
    ('mono', 'El mono', 'The Monkey',
     'Un mono juega entre las ramas.', 'A monkey plays among the branches.',
     'Algunos monos usan la cola para sujetarse a las ramas.',
     'Some monkeys use their tails to hold on to branches.'),
    ('coati', 'El coatí', 'The Coati',
     'Un coatí camina por el bosque.', 'A coati walks through the forest.',
     'El coatí busca comida con su hocico largo y camina con la cola levantada.',
     'The coati looks for food with its long snout and walks with its tail up.'),
    ('helechos', 'Los helechos', 'The Ferns',
     'Helechos del bosque.', 'Forest ferns.',
     'Las hojas nuevas de los helechos nacen enrolladas.',
     'New fern leaves start out curled up.'),
    ('orquideas', 'Las orquídeas', 'The Orchids',
     'Orquídeas en flor.', 'Orchids in bloom.',
     'Muchas orquídeas crecen sobre los árboles sin hacerles daño.',
     'Many orchids grow on trees without harming them.'),
    ('ranas-del-bosque', 'Las ranas del bosque', 'The Forest Frogs',
     'Ranas entre las hojas.', 'Frogs among the leaves.',
     'Las ranas absorben agua a través de la piel.',
     'Frogs take in water through their skin.'),
    ('arbol-gigante', 'El árbol gigante', 'The Giant Tree',
     'Un árbol grande del bosque.', 'A big forest tree.',
     'En un árbol grande del bosque viven muchas plantas y animales.',
     'Many plants and animals live on a big forest tree.'),
    ('cascada', 'La cascada', 'The Waterfall',
     'Una cascada entre las rocas.', 'A waterfall among the rocks.',
     'Una cascada se forma cuando un río cae desde un lugar alto.',
     'A waterfall forms when a river falls from a high place.'),
    ('sendero', 'El sendero del bosque', 'The Forest Trail',
     'Un sendero que cruza el bosque entre los árboles.',
     'A trail that crosses the forest among the trees.',
     'En el bosque nuboso, las nubes pasan entre los árboles y dejan gotitas de agua en las hojas.',
     'In the cloud forest, clouds drift between the trees and leave tiny water drops on the leaves.'),
]

# Plantillas anteriores de las páginas que ya existían.
PREVIAS = {
    'rana-en-la-hoja': {'1': 'pages/rana-en-la-hoja-v1.json'},
    'quetzal': {'1': 'pages/quetzal-v1.json'},
    'sendero': {'1': 'pages/sendero-v1.json'},
}


def main():
    aprobacion = {}
    if APROBACION.exists():
        aprobacion = json.loads(APROBACION.read_text(encoding='utf-8'))
    capitulo = json.loads(CAPITULO.read_text(encoding='utf-8'))
    capitulo['contentVersion'] = CONTENT_VERSION
    paginas = []
    for letra in 'EMDA':
        for i, (tema, tes, ten, des, den, fes, fen) in enumerate(TEMAS, 1):
            art = f'{letra}{i:02d}'
            m = json.loads((VALIDACION / f'{art}.json').read_text(encoding='utf-8'))
            pagina = {
                'id': m['pagina'],
                'artId': art,
                'difficulty': m['nivel'],
                'contentVersion': CONTENT_VERSION,
                'title': {'es': tes, 'en': ten},
            }
            if aprobacion.get(art, {}).get('aprobada'):
                pagina.update({
                    'description': {'es': des, 'en': den},
                    'funFact': {'es': fes, 'en': fen},
                    'template': m['plantilla'].split('bosque-nuboso/')[1],
                    'thumbnail': f"thumbs/{m['pagina']}.png",
                })
                if m['pagina'] in PREVIAS:
                    pagina['previousTemplates'] = PREVIAS[m['pagina']]
            else:
                pagina['status'] = 'planned'
            paginas.append(pagina)
    capitulo['pages'] = paginas
    CAPITULO.write_text(
        json.dumps(capitulo, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8', newline='\n')
    disponibles = sum(1 for p in paginas if 'template' in p)
    print(f'{disponibles} disponibles, {len(paginas) - disponibles} pendientes')


if __name__ == '__main__':
    main()
