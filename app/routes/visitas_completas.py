# app/routes/visitas_completas.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List
try:
    import pandas as pd
    PANDAS_AVAILABLE = True
except ImportError:
    PANDAS_AVAILABLE = False
    print("⚠️ pandas no está disponible. La generación de Excel estará deshabilitada.")

from io import BytesIO
from fastapi.responses import StreamingResponse

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user

router = APIRouter()

@router.post("/visitas-completas-pae", response_model=schemas.VisitaCompletaPAEOut)
def crear_visita_completa_pae(
    datos: schemas.VisitaCompletaPAECreate,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Crea una visita completa PAE con cronograma y respuestas del checklist
    """
    try:
        # Validar que los IDs existan
        municipio = db.query(models.Municipio).filter(models.Municipio.id == datos.municipio_id).first()
        if not municipio:
            raise HTTPException(status_code=400, detail="Municipio no encontrado")
            
        institucion = db.query(models.Institucion).filter(models.Institucion.id == datos.institucion_id).first()
        if not institucion:
            raise HTTPException(status_code=400, detail="Institución no encontrada")
            
        sede = db.query(models.SedeEducativa).filter(models.SedeEducativa.id == datos.sede_id).first()
        if not sede:
            raise HTTPException(status_code=400, detail="Sede no encontrada")
            
        profesional = db.query(models.Usuario).filter(models.Usuario.id == datos.profesional_id).first()
        if not profesional:
            raise HTTPException(status_code=400, detail="Profesional no encontrado")

        # Crear la visita completa
        visita_completa = models.VisitaCompletaPAE(
            fecha_visita=datos.fecha_visita,
            contrato=datos.contrato,
            operador=datos.operador,
            caso_atencion_prioritaria=datos.caso_atencion_prioritaria,
            municipio_id=datos.municipio_id,
            institucion_id=datos.institucion_id,
            sede_id=datos.sede_id,
            profesional_id=datos.profesional_id,
            observaciones=datos.observaciones
        )
        
        db.add(visita_completa)
        db.flush()  # Para obtener el ID
        
        # Guardar las respuestas del checklist
        for respuesta_data in datos.respuestas_checklist:
            respuesta = models.VisitaRespuestaCompleta(
                visita_completa_id=visita_completa.id,
                item_id=respuesta_data.item_id,
                respuesta=respuesta_data.respuesta,
                observacion=respuesta_data.observacion
            )
            db.add(respuesta)
        
        db.commit()
        
        # Retornar la visita completa con relaciones
        return db.query(models.VisitaCompletaPAE).filter(
            models.VisitaCompletaPAE.id == visita_completa.id
        ).first()
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al crear visita completa: {str(e)}"
        )

@router.get("/visitas-completas-pae", response_model=List[schemas.VisitaCompletaPAEOut])
def listar_visitas_completas_pae(
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Lista todas las visitas completas PAE
    """
    try:
        # Obtener todas las visitas con relaciones cargadas
        visitas = db.query(models.VisitaCompletaPAE).options(
            joinedload(models.VisitaCompletaPAE.municipio),
            joinedload(models.VisitaCompletaPAE.institucion),
            joinedload(models.VisitaCompletaPAE.sede),
            joinedload(models.VisitaCompletaPAE.profesional),
            joinedload(models.VisitaCompletaPAE.respuestas_checklist)
        ).all()
        
        print(f"🔍 Encontradas {len(visitas)} visitas completas PAE")
        for visita in visitas:
            print(f"   - Visita ID: {visita.id}, Estado: {visita.estado}, Profesional: {visita.profesional.nombre if visita.profesional else 'N/A'}")
        
        return visitas
    except Exception as e:
        print(f"❌ Error al listar visitas completas: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al listar visitas completas: {str(e)}"
        )

@router.get("/visitas-completas-pae/{visita_id}", response_model=schemas.VisitaCompletaPAEOut)
def obtener_visita_completa_pae(
    visita_id: int,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Obtiene una visita completa PAE específica
    """
    visita = db.query(models.VisitaCompletaPAE).filter(
        models.VisitaCompletaPAE.id == visita_id
    ).first()
    
    if not visita:
        raise HTTPException(status_code=404, detail="Visita no encontrada")
    
    return visita

@router.get("/visitas-completas-pae/{visita_id}/excel")
def generar_excel_visita_completa(
    visita_id: int,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    if not PANDAS_AVAILABLE:
        raise HTTPException(
            status_code=500,
            detail="La generación de Excel no está disponible. Instala pandas: pip install pandas openpyxl"
        )
    """
    Genera un archivo Excel con toda la información de una visita completa PAE
    """
    # Obtener la visita completa con todas las relaciones
    visita = db.query(models.VisitaCompletaPAE).filter(
        models.VisitaCompletaPAE.id == visita_id
    ).first()
    
    if not visita:
        raise HTTPException(status_code=404, detail="Visita no encontrada")
    
    # Obtener las respuestas del checklist
    respuestas = db.query(models.VisitaRespuestaCompleta).filter(
        models.VisitaRespuestaCompleta.visita_completa_id == visita_id
    ).all()
    
    # Crear DataFrame con la información de la visita
    datos_visita = {
        'Campo': [
            'ID Visita',
            'Fecha Visita',
            'Contrato',
            'Operador',
            'Caso Atención Prioritaria',
            'Municipio',
            'Institución',
            'Sede',
            'Profesional',
            'Estado',
            'Fecha Creación',
            'Observaciones'
        ],
        'Valor': [
            visita.id,
            visita.fecha_visita.strftime('%Y-%m-%d %H:%M'),
            visita.contrato,
            visita.operador,
            visita.caso_atencion_prioritaria,
            visita.municipio.nombre if visita.municipio else 'N/A',
            visita.institucion.nombre if visita.institucion else 'N/A',
            visita.sede.nombre if visita.sede else 'N/A',
            visita.profesional.nombre if visita.profesional else 'N/A',
            visita.estado,
            visita.fecha_creacion.strftime('%Y-%m-%d %H:%M'),
            visita.observaciones or 'N/A'
        ]
    }
    
    # Crear DataFrame con las respuestas del checklist
    datos_checklist = []
    for respuesta in respuestas:
        item = db.query(models.ChecklistItem).filter(
            models.ChecklistItem.id == respuesta.item_id
        ).first()
        
        if item:
            categoria = db.query(models.ChecklistCategoria).filter(
                models.ChecklistCategoria.id == item.categoria_id
            ).first()
            
            datos_checklist.append({
                'Categoría': categoria.nombre if categoria else 'N/A',
                'Pregunta': item.pregunta_texto,
                'Respuesta': respuesta.respuesta,
                'Observación': respuesta.observacion or 'N/A'
            })
    
    # Crear Excel con múltiples hojas
    with pd.ExcelWriter('visita_completa_pae.xlsx', engine='openpyxl') as writer:
        # Hoja 1: Información general de la visita
        df_visita = pd.DataFrame(datos_visita)
        df_visita.to_excel(writer, sheet_name='Información Visita', index=False)
        
        # Hoja 2: Respuestas del checklist
        if datos_checklist:
            df_checklist = pd.DataFrame(datos_checklist)
            df_checklist.to_excel(writer, sheet_name='Checklist PAE', index=False)
        
        # Hoja 3: Resumen por categorías
        if datos_checklist:
            df_resumen = pd.DataFrame(datos_checklist)
            resumen_categorias = df_resumen.groupby('Categoría')['Respuesta'].value_counts().unstack(fill_value=0)
            resumen_categorias.to_excel(writer, sheet_name='Resumen por Categorías')
    
    # Leer el archivo generado y retornarlo como respuesta
    with open('visita_completa_pae.xlsx', 'rb') as f:
        excel_data = f.read()
    
    return StreamingResponse(
        BytesIO(excel_data),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename=visita_completa_pae_{visita_id}.xlsx"}
    ) 