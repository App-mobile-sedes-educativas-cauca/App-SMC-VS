<<<<<<< HEAD
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import SedeEducativa
from typing import List

router = APIRouter()

@router.get("/municipios", summary="Listar municipios únicos", response_model=List[str])
def listar_municipios(db: Session = Depends(get_db)):
    """
    Retorna la lista de municipios únicos presentes en la tabla de sedes educativas.
    """
    municipios = db.query(SedeEducativa.municipio).distinct().all()
    return [m[0] for m in municipios if m[0]]  # Devuelve solo el nombre

@router.get("/sedes_por_municipio/{municipio_id}", summary="Listar sedes por municipio")
def obtener_sedes_por_municipio(municipio_id: int, db: Session = Depends(get_db)):
    """
    Retorna las sedes educativas asociadas a un municipio dado (por ID numérico).
    """
    return db.query(SedeEducativa).filter(SedeEducativa.municipio == municipio_id).all()
=======
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..models import SedeEducativa, Institucion
from ..schemas import SedeResponse

router = APIRouter(prefix="/api", tags=["sedes"])

@router.get("/sedes", response_model=List[SedeResponse])
def get_sedes(db: Session = Depends(get_db)):
    """Obtener todas las sedes"""
    try:
        sedes = db.query(SedeEducativa).all()
        return sedes
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener sedes: {str(e)}")

@router.get("/sedes_por_institucion/{institucion_id}", response_model=List[SedeResponse])
def get_sedes_por_institucion(institucion_id: int, db: Session = Depends(get_db)):
    """Obtener sedes por institución"""
    try:
        sedes = db.query(SedeEducativa).filter(SedeEducativa.institucion_id == institucion_id).all()
        return sedes
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener sedes por institución: {str(e)}")

@router.get("/sedes_por_municipio/{municipio_id}", response_model=List[SedeResponse])
def get_sedes_por_municipio(municipio_id: int, db: Session = Depends(get_db)):
    """Obtener sedes por municipio"""
    try:
        sedes = db.query(SedeEducativa).join(Institucion).filter(Institucion.municipio_id == municipio_id).all()
        return sedes
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener sedes por municipio: {str(e)}")

@router.get("/sedes/{sede_id}", response_model=SedeResponse)
def get_sede(sede_id: int, db: Session = Depends(get_db)):
    """Obtener una sede específica por ID"""
    sede = db.query(SedeEducativa).filter(SedeEducativa.id == sede_id).first()
    if not sede:
        raise HTTPException(status_code=404, detail="Sede no encontrada")
    return sede
>>>>>>> frontend
