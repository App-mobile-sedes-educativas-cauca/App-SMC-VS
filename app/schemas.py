# app/schemas.py

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

# --- Schemas para Roles y Usuarios ---

class RolOut(BaseModel):
    id: int
    nombre: str

    class Config:
        from_attributes = True

class UsuarioOut(BaseModel):
    id: int
    nombre: str
    correo: str
    rol: RolOut # Anidamos el rol para ver su nombre

    class Config:
        from_attributes = True

class UsuarioCreate(BaseModel):
    nombre: str
    correo: str
    contrasena: str
    rol_id: int

class Login(BaseModel):
    correo: str
    contrasena: str

class TokenData(BaseModel):
    access_token: str
    token_type: str
    usuario: UsuarioOut

class CambioContrasena(BaseModel):
    actual: str
    nueva: str

# --- Schemas para Estructura Educativa (NORMALIZADOS) ---

class MunicipioOut(BaseModel):
    id: int
    nombre: str

    class Config:
        from_attributes = True

class InstitucionOut(BaseModel):
    id: int
    nombre: str

    class Config:
        from_attributes = True

# Schema completo para la sede
class SedeEducativaOut(BaseModel):
    id: int
    nombre: str
    dane: str
    due: str
    lat: Optional[float]
    lon: Optional[float]
    principal: bool
    # Anidamos los objetos completos para tener toda la info
    municipio: MunicipioOut
    institucion: InstitucionOut

    class Config:
        from_attributes = True

# Schema simplificado para listas
class SedeEducativaSimpleOut(BaseModel):
    id: int
    nombre: str

    class Config:
        from_attributes = True

# --- Schemas para Visitas ---

class VisitaOut(BaseModel):
    id: int
    fecha_creacion: datetime
    estado: str
    observaciones: Optional[str]
    
    # Anidamos la información de la sede y el usuario
    sede: SedeEducativaOut
    usuario: UsuarioOut

    # Rutas a los archivos (opcionalmente puedes construir la URL completa aquí)
    foto_evidencia: Optional[str]
    video_evidencia: Optional[str]
    audio_evidencia: Optional[str]
    pdf_evidencia: Optional[str]
    foto_firma: Optional[str]

    class Config:
        from_attributes = True

class EstadoVisitaUpdate(BaseModel):
    estado: str 


    # --- Schemas para Cronograma y Evaluación PAE ---

class EvaluacionPAECrear(BaseModel):
    item: str
    valor: str  # 1, 2, 0, N/A, N/O

class CronogramaPAECrear(BaseModel):
    fecha_visita: datetime
    contrato: str
    operador: str
    municipio_id: int
    institucion_id: int
    sede_id: int
    profesional_id: int
    evaluaciones: List[EvaluacionPAECrear]
