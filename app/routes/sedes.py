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
