# app/routes/visitas.py

from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Request, Query, Path, status
from sqlalchemy.orm import Session, joinedload
from app import models, schemas
from app.database import get_db
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy import func
from typing import Optional, List
from uuid import uuid4
import shutil
import os

# Asumo que estas dependencias vienen de tu archivo auth.py
from app.dependencies import get_current_user 

router = APIRouter(
    prefix="/api",  # Es una buena práctica añadir un prefijo a todas las rutas de la API
    tags=["Visitas y Sedes"] # Agrupa las rutas en la documentación de Swagger
)

# --- ENDPOINTS DE CONSULTA GEOGRÁFICA (NORMALIZADOS) ---

@router.get("/municipios", response_model=List[schemas.MunicipioOut])
def listar_municipios(db: Session = Depends(get_db)):
    """
    Obtiene una lista de todos los municipios desde la tabla normalizada.
    """
    return db.query(models.Municipio).order_by(models.Municipio.nombre).all()

@router.get("/instituciones", response_model=List[schemas.InstitucionOut])
def listar_instituciones(db: Session = Depends(get_db)):
    """
    Obtiene una lista de todas las instituciones educativas.
    """
    return db.query(models.Institucion).order_by(models.Institucion.nombre).all()

@router.get("/sedes_por_municipio/{municipio_id}", response_model=List[schemas.SedeEducativaSimpleOut])
def listar_sedes_por_municipio(municipio_id: int, db: Session = Depends(get_db)):
    """
    Obtiene las sedes educativas filtrando por el ID del municipio.
    """
    sedes = db.query(models.SedeEducativa).filter(models.SedeEducativa.municipio_id == municipio_id).order_by(models.SedeEducativa.nombre).all()
    
    if not sedes:
        raise HTTPException(
            status_code=404, 
            detail="No se encontraron sedes para el municipio especificado."
        )
    return sedes

# --- ENDPOINTS DE VISITAS (CRUD Y LÓGICA DE NEGOCIO) ---

@router.post("/visitas", response_model=schemas.VisitaOut, status_code=status.HTTP_201_CREATED)
def crear_visita(
    # El usuario se obtiene del token, no se envía en el formulario
    usuario: models.Usuario = Depends(get_current_user),
    # Datos del formulario
    sede_id: int = Form(...),
    tipo_asunto: str = Form(...),
    observaciones: str = Form(...),
    lat: float = Form(...),
    lon: float = Form(...),
    # Archivos opcionales
    foto_evidencia: UploadFile = File(None),
    video_evidencia: UploadFile = File(None),
    audio_evidencia: UploadFile = File(None),
    pdf_evidencia: UploadFile = File(None),
    foto_firma: UploadFile = File(None),
    # Dependencia de la base de datos
    db: Session = Depends(get_db)
):
    """
    Crea un nuevo registro de visita. El ID del usuario se toma del token de autenticación.
    """
    def guardar_archivo(archivo: UploadFile, carpeta: str) -> Optional[str]:
        if not archivo:
            return None
        
        # Uso de UUID para nombres de archivo únicos y seguros
        ext = archivo.filename.split(".")[-1]
        nombre_archivo = f"{uuid4()}.{ext}"
        ruta_directorio = os.path.join("media", carpeta)
        os.makedirs(ruta_directorio, exist_ok=True)
        ruta_completa = os.path.join(ruta_directorio, nombre_archivo)
        
        with open(ruta_completa, "wb") as buffer:
            shutil.copyfileobj(archivo.file, buffer)
        
        # Guardamos la ruta relativa
        return ruta_completa

    nueva_visita = models.Visita(
        sede_id=sede_id,
        usuario_id=usuario.id, # Obtenido del token
        tipo_asunto=tipo_asunto,
        observaciones=observaciones,
        lat=lat,
        lon=lon,
        estado="pendiente", # Estado por defecto
        # Rutas a los archivos guardados
        foto_evidencia=guardar_archivo(foto_evidencia, "fotos"),
        video_evidencia=guardar_archivo(video_evidencia, "videos"),
        audio_evidencia=guardar_archivo(audio_evidencia, "audios"),
        pdf_evidencia=guardar_archivo(pdf_evidencia, "pdfs"),
        foto_firma=guardar_archivo(foto_firma, "firmas")
    )
    
    db.add(nueva_visita)
    db.commit()
    db.refresh(nueva_visita)
    
    # Para la respuesta, cargamos las relaciones para que el schema Pydantic funcione
    return db.query(models.Visita).options(
        joinedload(models.Visita.sede),
        joinedload(models.Visita.usuario).joinedload(models.Usuario.rol)
    ).filter(models.Visita.id == nueva_visita.id).first()


@router.get("/visitas", response_model=List[schemas.VisitaOut])
def listar_visitas_para_admin(
    request: Request,
    db: Session = Depends(get_db),
    # Filtros opcionales
    municipio_id: Optional[int] = Query(None),
    sede_id: Optional[int] = Query(None),
    estado: Optional[str] = Query(None),
    # Dependencia de autorización
    usuario: models.Usuario = Depends(get_current_user)
):
    """
    Endpoint unificado para listar visitas. Los administradores pueden ver todo.
    Los demás usuarios deben usar /visitas/mis-visitas.
    """
    # Verificación de rol
    if usuario.rol.nombre != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes permiso para ver todas las visitas.")

    query = db.query(models.Visita).options(
        joinedload(models.Visita.sede).joinedload(models.SedeEducativa.municipio),
        joinedload(models.Visita.usuario).joinedload(models.Usuario.rol)
    ).order_by(models.Visita.fecha_creacion.desc())

    # Aplicar filtros
    if sede_id:
        query = query.filter(models.Visita.sede_id == sede_id)
    if estado:
        query = query.filter(models.Visita.estado.ilike(f"%{estado}%"))
    if municipio_id:
        query = query.join(models.SedeEducativa).filter(models.SedeEducativa.municipio_id == municipio_id)

    visitas = query.all()
    
    # Reutilizamos la función para construir URLs absolutas
    for visita in visitas:
        visita.foto_evidencia = _build_absolute_url(request, visita.foto_evidencia)
        # ... (repetir para los otros campos de archivo)

    return visitas


@router.get("/visitas/mis-visitas", response_model=List[schemas.VisitaOut])
def listar_mis_visitas(
    request: Request,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(get_current_user),
    estado: Optional[str] = Query(None, description="Filtrar por estado: 'pendiente' o 'completada'")
):
    """
    Obtiene la lista de visitas asignadas al usuario actualmente autenticado.
    """
    query = db.query(models.Visita).options(
        joinedload(models.Visita.sede),
        joinedload(models.Visita.usuario).joinedload(models.Usuario.rol)
    ).filter(models.Visita.usuario_id == usuario.id).order_by(models.Visita.fecha_creacion.desc())
    
    if estado:
        query = query.filter(models.Visita.estado == estado)

    visitas = query.all()

    for visita in visitas:
        visita.foto_evidencia = _build_absolute_url(request, visita.foto_evidencia)
        # ... (repetir para los otros campos de archivo)

    return visitas


@router.put("/visitas/{visita_id}/estado", response_model=schemas.VisitaOut)
def actualizar_estado_visita(
    visita_id: int,
    nuevo_estado: schemas.EstadoVisitaUpdate, # Usamos un schema para el body
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(get_current_user)
):
    """
    Actualiza el estado de una visita a 'pendiente' or 'completada'.
    """
    visita = db.query(models.Visita).filter(models.Visita.id == visita_id).first()
    if not visita:
        raise HTTPException(status_code=404, detail="Visita no encontrada")
    
    # Opcional: Verificar si el usuario tiene permiso para cambiar el estado
    if visita.usuario_id != usuario.id and usuario.rol.nombre != 'admin':
        raise HTTPException(status_code=403, detail="No tienes permiso para modificar esta visita.")

    visita.estado = nuevo_estado.estado
    db.commit()
    db.refresh(visita)
    return visita


# --- FUNCIÓN AUXILIAR ---
def _build_absolute_url(request: Request, file_path: str) -> Optional[str]:
    """Construye una URL absoluta para un archivo de evidencia."""
    if not file_path:
        return None
    return str(request.base_url.replace(path=file_path))