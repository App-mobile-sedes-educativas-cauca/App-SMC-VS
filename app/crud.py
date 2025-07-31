from sqlalchemy.orm import Session
from . import models, schemas

# --- LÓGICA PARA EL CHECKLIST ---

def get_checklist_data(db: Session):
    """
    Obtiene todas las categorías y, para cada una, anida sus ítems (preguntas).
    """
    # 1. Obtiene todas las categorías de la base de datos.
    categorias = db.query(models.ChecklistCategoria).all()
    # 2. Obtiene todos los ítems de la base de datos.
    items = db.query(models.ChecklistItem).all()

    # 3. Crea un diccionario para organizar los datos eficientemente.
    #    La clave es el ID de la categoría.
    categorias_dict = {
        cat.id: schemas.ChecklistCategoriaBase(id=cat.id, nombre=cat.nombre, items=[]) 
        for cat in categorias
    }

    # 4. Recorre cada ítem y lo agrega a la lista de su categoría correspondiente.
    for item in items:
        if item.categoria_id in categorias_dict:
            categorias_dict[item.categoria_id].items.append(
                schemas.ChecklistItemBase(id=item.id, pregunta_texto=item.pregunta_texto)
            )
    
    # 5. Devuelve una lista con todas las categorías ya organizadas.
    return list(categorias_dict.values())


# --- LÓGICA PARA LAS VISITAS ---

def create_visita_y_respuestas(db: Session, visita_data: schemas.VisitaCreate):
    """
    Guarda una visita principal y luego guarda cada una de sus respuestas
    del checklist asociadas.
    """
    # 1. Crea el registro de la visita principal en la tabla 'visitas'.
    db_visita = models.Visita(
        sede_id=visita_data.sede_id,
        usuario_id=visita_data.usuario_id
        # ... aquí puedes agregar otros campos de la visita ...
    )
    db.add(db_visita)
    db.commit()  # Confirma la transacción para crear la visita y obtener su ID.
    db.refresh(db_visita)

    # 2. Itera sobre cada respuesta recibida desde la app.
    for respuesta_data in visita_data.respuestas:
        db_respuesta = models.VisitaRespuesta(
            visita_id=db_visita.id, # Asocia la respuesta a la visita recién creada.
            item_id=respuesta_data.item_id,
            respuesta=respuesta_data.respuesta,
            observacion=respuesta_data.observacion
        )
        db.add(db_respuesta)
    
    # 3. Confirma la transacción para guardar todas las respuestas.
    db.commit()
    
    return db_visita