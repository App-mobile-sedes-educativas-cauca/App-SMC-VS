from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..models import SedeEducativa, Institucion, Municipio
from ..schemas import SedeResponse, SedeEducativaCreate

router = APIRouter(prefix="", tags=["sedes"])

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

@router.post("/sedes", response_model=SedeResponse)
def crear_sede(sede_data: SedeEducativaCreate, db: Session = Depends(get_db)):
    """Crear una nueva sede educativa"""
    try:
        # Verificar que el municipio existe
        municipio = db.query(Municipio).filter(Municipio.id == sede_data.municipio_id).first()
        if not municipio:
            raise HTTPException(status_code=404, detail="Municipio no encontrado")
        
        # Verificar que la institución existe
        institucion = db.query(Institucion).filter(Institucion.id == sede_data.institucion_id).first()
        if not institucion:
            raise HTTPException(status_code=404, detail="Institución no encontrada")
        
        # Verificar que la institución pertenece al municipio especificado
        if institucion.municipio_id != sede_data.municipio_id:
            raise HTTPException(
                status_code=400, 
                detail="La institución no pertenece al municipio especificado"
            )
        
        # Verificar que el código DANE no esté duplicado
        sede_existente_dane = db.query(SedeEducativa).filter(SedeEducativa.dane == sede_data.dane).first()
        if sede_existente_dane:
            raise HTTPException(
                status_code=400, 
                detail=f"Ya existe una sede con el código DANE: {sede_data.dane}"
            )
        
        # Verificar que el código DUE no esté duplicado
        sede_existente_due = db.query(SedeEducativa).filter(SedeEducativa.due == sede_data.due).first()
        if sede_existente_due:
            raise HTTPException(
                status_code=400, 
                detail=f"Ya existe una sede con el código DUE: {sede_data.due}"
            )
        
        # Crear la nueva sede
        nueva_sede = SedeEducativa(
            nombre=sede_data.nombre,
            dane=sede_data.dane,
            due=sede_data.due,
            lat=sede_data.lat,
            lon=sede_data.lon,
            principal=sede_data.principal,
            municipio_id=sede_data.municipio_id,
            institucion_id=sede_data.institucion_id
        )
        
        db.add(nueva_sede)
        db.commit()
        db.refresh(nueva_sede)
        
        print(f"✅ Nueva sede creada: {nueva_sede.nombre} (ID: {nueva_sede.id})")
        print(f"   - DANE: {nueva_sede.dane}")
        print(f"   - DUE: {nueva_sede.due}")
        print(f"   - Municipio: {municipio.nombre}")
        print(f"   - Institución: {institucion.nombre}")
        
        return nueva_sede
        
    except HTTPException:
        # Re-lanzar las excepciones HTTP que ya fueron creadas
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Error al crear sede: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Error interno al crear la sede: {str(e)}"
        )
