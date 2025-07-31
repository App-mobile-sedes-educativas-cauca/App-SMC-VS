from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..models import Institucion
from ..schemas import InstitucionResponse

router = APIRouter(prefix="/api", tags=["instituciones"])

@router.get("/instituciones", response_model=List[InstitucionResponse])
def get_instituciones(db: Session = Depends(get_db)):
    """Obtener todas las instituciones"""
    try:
        instituciones = db.query(Institucion).all()
        return instituciones
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener instituciones: {str(e)}")

@router.get("/instituciones_por_municipio/{municipio_id}", response_model=List[InstitucionResponse])
def get_instituciones_por_municipio(municipio_id: int, db: Session = Depends(get_db)):
    """Obtener instituciones por municipio"""
    try:
        instituciones = db.query(Institucion).filter(Institucion.municipio_id == municipio_id).all()
        return instituciones
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener instituciones por municipio: {str(e)}")

@router.get("/instituciones/{institucion_id}", response_model=InstitucionResponse)
def get_institucion(institucion_id: int, db: Session = Depends(get_db)):
    """Obtener una institución específica por ID"""
    institucion = db.query(Institucion).filter(Institucion.id == institucion_id).first()
    if not institucion:
        raise HTTPException(status_code=404, detail="Institución no encontrada")
    return institucion 