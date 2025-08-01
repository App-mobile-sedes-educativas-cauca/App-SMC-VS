# app/models.py

from sqlalchemy import Column, Integer, Float, String, Text, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

# --- MODELOS DE AUTENTICACIÓN Y ROLES ---

class Rol(Base):
    """
    Define los roles de los usuarios en el sistema (ej. 'Administrador', 'Auditor').
    """
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, nullable=False)
    
    # Relación para ver qué usuarios tienen este rol
    usuarios = relationship("Usuario", back_populates="rol")

class Usuario(Base):
    """
    Almacena la información de los usuarios que pueden iniciar sesión en la app.
    """
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    correo = Column(String, unique=True, index=True, nullable=False)
    contrasena = Column(String, nullable=False)  # Debería ser un hash
    rol_id = Column(Integer, ForeignKey("roles.id"), nullable=False)
    
    # Relaciones
    rol = relationship("Rol", back_populates="usuarios")
    # visitas = relationship("Visita", back_populates="usuario")  # Comentado porque Visita ya no existe

# --- MODELOS DE ESTRUCTURA EDUCATIVA (NORMALIZADOS) ---

class Municipio(Base):
    """
    Catálogo de todos los municipios.
    """
    __tablename__ = "municipios"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, nullable=False)

    # Relación para ver todas las sedes en este municipio
    sedes = relationship("SedeEducativa", back_populates="municipio")

class Institucion(Base):
    """
    Catálogo de todas las instituciones educativas.
    """
    __tablename__ = "instituciones"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, nullable=False)
    municipio_id = Column(Integer, ForeignKey("municipios.id"), nullable=False)

    # Relaciones
    municipio = relationship("Municipio")
    sedes = relationship("SedeEducativa", back_populates="institucion")

# UNIFICADO: Este modelo ahora combina Sede y SedeEducativa
class SedeEducativa(Base):
    """
    Modelo centralizado para cada sede educativa. 
    Contiene toda la información y se relaciona con Municipio e Institución.
    """
    __tablename__ = "sedes_educativas"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column("nombre_sede", String, nullable=False)
    dane = Column(String, unique=True, nullable=False)
    due = Column(String, unique=True, nullable=False)
    lat = Column(Float, nullable=True)
    lon = Column(Float, nullable=True)
    principal = Column(Boolean, default=False)  # Para identificar la sede principal

    # Foreign Keys para las relaciones
    municipio_id = Column(Integer, ForeignKey("municipios.id"), nullable=False)
    institucion_id = Column(Integer, ForeignKey("instituciones.id"), nullable=False)

    # Relaciones para acceder a los objetos completos
    municipio = relationship("Municipio", back_populates="sedes")
    institucion = relationship("Institucion", back_populates="sedes")
    # visitas = relationship("Visita", back_populates="sede")  # Comentado porque Visita ya no existe


# --- MODELO PRINCIPAL DE LA APLICACIÓN ---

# NOTA: El modelo Visita ha sido reemplazado por VisitaCompletaPAE
# Se mantiene comentado por referencia histórica

# class Visita(Base):
#     """
#     Almacena cada registro de visita realizado por un auditor a una sede.
#     """
#     __tablename__ = 'visitas'
#     
#     id = Column(Integer, primary_key=True)
#     fecha_creacion = Column(DateTime, default=datetime.utcnow)
#     estado = Column(String, default="pendiente") # ej: pendiente, completada
#     observaciones = Column(Text, nullable=True)
#     
#     # Rutas a los archivos de evidencia guardados en el servidor
#     foto_evidencia = Column(String, nullable=True)
#     video_evidencia = Column(String, nullable=True)
#     audio_evidencia = Column(String, nullable=True)
#     pdf_evidencia = Column(String, nullable=True)
#     foto_firma = Column(String, nullable=True)
#     
#     # Foreign Keys
#     usuario_id = Column(Integer, ForeignKey('usuarios.id'), nullable=False)
#     sede_id = Column(Integer, ForeignKey('sedes_educativas.id'), nullable=False)
#     
#     # Relaciones
#     usuario = relationship("Usuario", back_populates="visitas")
#     sede = relationship("SedeEducativa", back_populates="visitas")
#     respuestas = relationship("VisitaRespuesta", back_populates="visita")

# --- NUEVO MODELO: VISITA COMPLETA PAE ---

class VisitaCompletaPAE(Base):
    """
    Modelo unificado que combina cronograma PAE + respuestas del checklist
    para generar reportes Excel completos
    """
    __tablename__ = "visitas_completas_pae"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # --- DATOS DEL CRONOGRAMA PAE ---
    fecha_visita = Column(DateTime, nullable=False)
    contrato = Column(String, nullable=False)
    operador = Column(String, nullable=False)
    caso_atencion_prioritaria = Column(String, nullable=True)  # SI, NO, NO HUBO SERVICIO, ACTA RAPIDA
    
    # --- DATOS DE UBICACIÓN ---
    municipio_id = Column(Integer, ForeignKey("municipios.id"))
    institucion_id = Column(Integer, ForeignKey("instituciones.id"))
    sede_id = Column(Integer, ForeignKey("sedes_educativas.id"))
    profesional_id = Column(Integer, ForeignKey("usuarios.id"))
    
    # --- DATOS DE LA VISITA ---
    fecha_creacion = Column(DateTime, default=datetime.utcnow)
    estado = Column(String, default="pendiente")  # pendiente, completada, cancelada
    observaciones = Column(Text, nullable=True)
    
    # --- ARCHIVOS DE EVIDENCIA ---
    foto_evidencia = Column(String, nullable=True)
    video_evidencia = Column(String, nullable=True)
    audio_evidencia = Column(String, nullable=True)
    pdf_evidencia = Column(String, nullable=True)
    foto_firma = Column(String, nullable=True)
    
    # --- RELACIONES ---
    municipio = relationship("Municipio")
    institucion = relationship("Institucion")
    sede = relationship("SedeEducativa")
    profesional = relationship("Usuario")
    respuestas_checklist = relationship("VisitaRespuestaCompleta", back_populates="visita_completa")

class VisitaRespuestaCompleta(Base):
    """
    Respuestas del checklist asociadas a una visita completa PAE
    """
    __tablename__ = "visita_respuestas_completas"
    
    id = Column(Integer, primary_key=True, index=True)
    visita_completa_id = Column(Integer, ForeignKey("visitas_completas_pae.id"), nullable=False)
    item_id = Column(Integer, ForeignKey("checklist_items.id"), nullable=False)
    respuesta = Column(String, nullable=False)  # "Cumple", "No Cumple", "Cumple Parcialmente", "N/A", "N/O"
    observacion = Column(Text, nullable=True)
    
    # Relaciones
    visita_completa = relationship("VisitaCompletaPAE", back_populates="respuestas_checklist")
    item = relationship("ChecklistItem")


# --- MODELOS DE CRONOGRAMA Y EVALUACIÓN PAE ---

# NOTA: Estos modelos han sido reemplazados por VisitaCompletaPAE
# Se mantienen comentados por referencia histórica

# class CronogramaVisitaPAE(Base):
#     """
#     Almacena los cronogramas de visitas PAE programadas.
#     """
#     __tablename__ = 'cronogramas_pae'
#     
#     id = Column(Integer, primary_key=True, index=True)
#     fecha_visita = Column(DateTime, nullable=False)
#     contrato = Column(String, nullable=False)
#     operador = Column(String, nullable=False)
#     caso_atencion_prioritaria = Column(String, nullable=True)  # SI, NO, NO HUBO SERVICIO, ACTA RAPIDA
#     
#     # Foreign Keys
#     municipio_id = Column(Integer, ForeignKey("municipios.id"))
#     institucion_id = Column(Integer, ForeignKey("instituciones.id"))
#     sede_id = Column(Integer, ForeignKey("sedes_educativas.id"))
#     profesional_id = Column(Integer, ForeignKey("usuarios.id"))
#     
#     # Relaciones
#     municipio = relationship("Municipio")
#     institucion = relationship("Institucion")
#     sede = relationship("SedeEducativa")
#     profesional = relationship("Usuario")

# class EvaluacionPAE(Base):
#     """
#     Almacena las evaluaciones PAE realizadas durante las visitas.
#     """
#     __tablename__ = 'evaluaciones_pae'
#     
#     id = Column(Integer, primary_key=True, index=True)
#     fecha_evaluacion = Column(DateTime, default=datetime.utcnow)
#     resultado = Column(String, nullable=False)  # "APROBADO", "REPROBADO", "CONDICIONAL"
#     observaciones = Column(Text, nullable=True)
#     
#     # Foreign Keys
#     cronograma_id = Column(Integer, ForeignKey("cronogramas_pae.id"))
#     evaluador_id = Column(Integer, ForeignKey("usuarios.id"))
#     
#     # Relaciones
#     cronograma = relationship("CronogramaVisitaPAE")
#     evaluador = relationship("Usuario")

# --- MODELOS DEL CHECKLIST ---

class ChecklistCategoria(Base):
    """
    Categorías del checklist (ej: "Equipos y utensilios", "Personal manipulador")
    """
    __tablename__ = "checklist_categorias"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    
    # Relación para ver todos los items de esta categoría
    items = relationship("ChecklistItem", back_populates="categoria", order_by="ChecklistItem.orden")


class ChecklistItem(Base):
    """
    Items individuales del checklist (preguntas específicas)
    """
    __tablename__ = "checklist_items"
    
    id = Column(Integer, primary_key=True, index=True)
    pregunta_texto = Column(Text, nullable=False)
    categoria_id = Column(Integer, ForeignKey("checklist_categorias.id"), nullable=False)
    orden = Column(Integer, nullable=False)  # Para ordenar los items dentro de cada categoría
    
    # Relaciones
    categoria = relationship("ChecklistCategoria", back_populates="items")
    # respuestas = relationship("VisitaRespuesta", back_populates="item")  # Comentado porque VisitaRespuesta ya no existe


# NOTA: El modelo VisitaRespuesta ha sido reemplazado por VisitaRespuestaCompleta
# Se mantiene comentado por referencia histórica

# class VisitaRespuesta(Base):
#     """
#     Respuestas específicas de cada visita a los items del checklist
#     """
#     __tablename__ = "visita_respuestas"
#     
#     id = Column(Integer, primary_key=True, index=True)
#     visita_id = Column(Integer, ForeignKey("visitas.id"), nullable=False)
#     item_id = Column(Integer, ForeignKey("checklist_items.id"), nullable=False)
#     respuesta = Column(String, nullable=False)  # "Cumple", "No Cumple", "Cumple Parcialmente", "N/A", "N/O"
#     observacion = Column(Text, nullable=True)
#     
#     # Relaciones
#     visita = relationship("Visita", back_populates="respuestas")
#     item = relationship("ChecklistItem", back_populates="respuestas")
