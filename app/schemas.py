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

# Alias para compatibilidad con el frontend
MunicipioResponse = MunicipioOut

class InstitucionOut(BaseModel):
    id: int
    nombre: str

    class Config:
        from_attributes = True

# Alias para compatibilidad con el frontend
InstitucionResponse = InstitucionOut

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

# Schema para crear sedes educativas
class SedeEducativaCreate(BaseModel):
    nombre: str
    dane: str
    due: str
    lat: Optional[float] = None
    lon: Optional[float] = None
    principal: bool = False
    municipio_id: int
    institucion_id: int

    class Config:
        from_attributes = True

# Alias para compatibilidad con el frontend
SedeResponse = SedeEducativaSimpleOut

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


    # --- Schemas para Guardar una Visita ---

class VisitaRespuestaCreate(BaseModel):
    item_id: int  # El ID de la pregunta
    respuesta: str  # "Cumple", "No Cumple", etc.
    observacion: Optional[str] = None

# NOTA: Los schemas de Cronograma PAE han sido reemplazados por VisitaCompletaPAE
# Se mantienen comentados por referencia histórica

# class EvaluacionPAECrear(BaseModel):
#     item: str
#     valor: str  # 1, 2, 0, N/A, N/O
# 
# class CronogramaPAECrear(BaseModel):
#     fecha_visita: datetime
#     contrato: str
#     operador: str
#     municipio_id: int
#     institucion_id: int
#     sede_id: int
#     profesional_id: int
#     caso_atencion_prioritaria: str  # SI, NO, NO HUBO SERVICIO, ACTA RAPIDA
#     evaluaciones: List[EvaluacionPAECrear] = []  # Lista vacía por defecto
#     respuestas_checklist: List[VisitaRespuestaCreate] = []  # Respuestas del checklist
#     
#     class Config:
#         json_encoders = {
#             datetime: lambda v: v.isoformat()
#         }

# --- Schemas para el Checklist ---

class ChecklistItemBase(BaseModel):
    id: int
    pregunta_texto: str

    class Config:
        from_attributes = True

class ChecklistCategoriaBase(BaseModel):
    id: int
    nombre: str
    items: List[ChecklistItemBase] = []  # Una lista de preguntas dentro de cada categoría

    class Config:
        from_attributes = True

# --- Schemas para Visita Completa PAE ---

class VisitaRespuestaCompletaCreate(BaseModel):
    item_id: int
    respuesta: str
    observacion: Optional[str] = None

class VisitaCompletaPAECreate(BaseModel):
    # Datos del cronograma PAE
    fecha_visita: datetime
    contrato: str
    operador: str
    caso_atencion_prioritaria: str
    municipio_id: int
    institucion_id: int
    sede_id: int
    profesional_id: int
    
    # Datos adicionales de la visita
    observaciones: Optional[str] = None
    
    # Respuestas del checklist
    respuestas_checklist: List[VisitaRespuestaCompletaCreate] = []
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class VisitaCompletaPAEOut(BaseModel):
    id: int
    fecha_visita: datetime
    contrato: str
    operador: str
    caso_atencion_prioritaria: str
    municipio_id: int
    institucion_id: int
    sede_id: int
    profesional_id: int
    fecha_creacion: datetime
    estado: str
    observaciones: Optional[str]
    
    # Información relacionada
    municipio: MunicipioOut
    institucion: InstitucionOut
    sede: SedeEducativaOut
    profesional: UsuarioOut
    
    # Respuestas del checklist
    respuestas_checklist: List[VisitaRespuestaCreate] = []
    
    class Config:
        from_attributes = True
