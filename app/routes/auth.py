# auth.py

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from app import models, schemas
from app.database import get_db
import os # NUEVO: Para leer variables de entorno
from fastapi import APIRouter
from app.schemas import Login 


router = APIRouter(
    prefix="/auth", # MEJORADO: Agrupar todas las rutas de auth bajo un prefijo
    tags=["Autenticación"]
)

# --- CONFIGURACIÓN ---

# MEJORADO: Cargar la clave secreta desde variables de entorno para mayor seguridad
SECRET_KEY = os.getenv("SECRET_KEY", "una_clave_secreta_por_defecto_solo_para_desarrollo")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

bearer_scheme = HTTPBearer()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# --- FUNCIONES AUXILIARES ---

def _crear_token_acceso(usuario: models.Usuario) -> str:
   
    expiration = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    token_data = {
        "sub": usuario.correo,
        "rol": usuario.rol.nombre,
        "id": usuario.id,  
        "exp": expiration
    }
    return jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)

# NUEVO: Función centralizada para decodificar tokens y obtener el usuario
def _obtener_usuario_por_token(token: str, db: Session) -> models.Usuario:
    """Decodifica un token, valida su payload y devuelve el usuario correspondiente."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        correo: str = payload.get("sub")
        if correo is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido (sin 'sub')")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido o expirado")

    usuario = db.query(models.Usuario).filter(models.Usuario.correo == correo).first()
    if usuario is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuario del token no encontrado")
    
    return usuario

# --- DEPENDENCIAS DE FASTAPI ---

def obtener_usuario_actual(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db)
) -> models.Usuario:
    """Dependencia para obtener el usuario autenticado en rutas protegidas."""
    return _obtener_usuario_por_token(credentials.credentials, db)

def verificar_rol_permitido(roles_permitidos: list):
    """
    Dependencia que verifica si el rol del usuario autenticado está en la lista de roles permitidos.
    """
    def validador(usuario: models.Usuario = Depends(obtener_usuario_actual)):
        if usuario.rol.nombre not in roles_permitidos:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Acceso denegado. Rol '{usuario.rol.nombre}' no autorizado."
            )
        return usuario
    return validador

# --- RUTAS DE LA API ---

@router.post("/register", response_model=schemas.TokenData, status_code=status.HTTP_201_CREATED)
def register(usuario: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    if db.query(models.Usuario).filter(models.Usuario.correo == usuario.correo).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El correo ya está registrado")

    nuevo_usuario = models.Usuario(
        nombre=usuario.nombre,
        correo=usuario.correo,
        contrasena=pwd_context.hash(usuario.contrasena),
        rol_id=usuario.rol_id
    )
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)

    token = _crear_token_acceso(nuevo_usuario)
    
    # --- LA CORRECCIÓN ESTÁ AQUÍ ---
    # Ahora devolvemos un diccionario completo que coincide con el schema TokenData
    return {
        "access_token": token,
        "token_type": "bearer",
        "usuario": nuevo_usuario 
    }


@router.post("/login", response_model=schemas.TokenData)
def login(form_data: schemas.Login, db: Session = Depends(get_db)):
    """Inicia sesión y devuelve un token de acceso Y la información del usuario."""
    usuario = db.query(models.Usuario).filter(models.Usuario.correo == form_data.correo).first()
    if not usuario or not pwd_context.verify(form_data.contrasena, usuario.contrasena):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Credenciales inválidas"
        )

    token = _crear_token_acceso(usuario)
    
    # MEJORADO: Devolvemos un diccionario que coincide con el nuevo schema TokenData
    return {
        "access_token": token, 
        "token_type": "bearer",
        "usuario": usuario  
    }

@router.get("/me", response_model=schemas.UsuarioOut)
def read_users_me(usuario: models.Usuario = Depends(obtener_usuario_actual)):
    """Devuelve la información del usuario actualmente autenticado."""
    return usuario


@router.put("/me/cambiar-contrasena")
def cambiar_contrasena(
    datos: schemas.CambioContrasena,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    """Permite al usuario autenticado cambiar su propia contraseña."""
    if not pwd_context.verify(datos.actual, usuario.contrasena):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Contraseña actual incorrecta")

    usuario.contrasena = pwd_context.hash(datos.nueva)
    db.commit()
    return {"mensaje": "Contraseña actualizada correctamente"}

# Las rutas de recuperación y restablecimiento de contraseña están bien como las tienes.
# En una aplicación real, la ruta /recuperar enviaría el token por correo electrónico en lugar de imprimirlo.