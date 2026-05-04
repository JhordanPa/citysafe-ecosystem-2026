from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# --- ESQUEMAS PARA USUARIO ---
class UsuarioBase(BaseModel):
    username: str

class UsuarioCreate(UsuarioBase):
    password: str

class Usuario(UsuarioBase):
    id: int

    class Config:
        from_attributes = True

# --- ESQUEMAS PARA INCIDENTE ---
class IncidenteBase(BaseModel):
    tipo: str
    latitud: float
    longitud: float
    nivel_urgencia: int
    descripcion: Optional[str] = None

class IncidenteCreate(IncidenteBase):
    pass

class Incidente(IncidenteBase):
    id: int
    fecha_reporte: datetime
    usuario_id: int

    class Config:
        from_attributes = True
