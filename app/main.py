# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app import models
from app.database import engine
from app.routes import visitas, sedes, dashboard, auth, visitas_completas, usuarios, reportes
# 1. Crear la instancia de la aplicación
app = FastAPI(
    title="API de Seguimiento de Sedes Educativas",
    description="API para gestionar las visitas a las sedes educativas del Cauca.",
    version="1.0.0"
)

# 2. Añadir el Middleware de CORS
origins = ["*"]  # Permite todo para desarrollo

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 3. Crear las tablas de la base de datos
models.Base.metadata.create_all(bind=engine)

# 4. Incluir los Routers
app.include_router(visitas.router, prefix="/api", tags=["Visitas"])
app.include_router(sedes.router, prefix="/api", tags=["Sedes"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["Dashboard"])
app.include_router(auth.router)
app.include_router(visitas_completas.router, prefix="/api", tags=["Visitas Completas PAE"])
app.include_router(usuarios.router, prefix="/api", tags=["Usuarios"])
app.include_router(reportes.router, prefix="/api/reportes", tags=["Reportes"])

# 5. Ruta de Bienvenida
@app.get("/", tags=["Root"])
def read_root():
    return {"mensaje": "API de Seguimiento de Sedes Educativas está en línea"}
