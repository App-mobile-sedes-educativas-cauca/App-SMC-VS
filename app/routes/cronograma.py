from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app import models, schemas
from app.database import get_db

router = APIRouter()

@router.post("/cronogramas_pae", status_code=201)
def crear_cronograma_pae(datos: schemas.CronogramaPAECrear, db: Session = Depends(get_db)):
    # Crear cronograma base
    cronograma = models.CronogramaVisitaPAE(
        fecha_visita=datos.fecha_visita,
        contrato=datos.contrato,
        operador=datos.operador,
        municipio_id=datos.municipio_id,
        institucion_id=datos.institucion_id,
        sede_id=datos.sede_id,
        profesional_id=datos.profesional_id
    )
    db.add(cronograma)
    db.commit()
    db.refresh(cronograma)

    # Registrar ítems de evaluación
    for item in datos.evaluaciones:
        evaluacion = models.EvaluacionPAE(
            cronograma_id=cronograma.id,
            item=item.item,
            valor=item.valor
        )
        db.add(evaluacion)

    db.commit()
    return {"mensaje": "Cronograma y evaluación registrados correctamente", "cronograma_id": cronograma.id}
