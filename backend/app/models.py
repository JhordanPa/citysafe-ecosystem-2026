from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

class UsuarioDB(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String) 
    rol = Column(String, default="ciudadano")
    
    incidentes = relationship("IncidenteDB", back_populates="usuario")

class IncidenteDB(Base):
    __tablename__ = "incidentes"
    id = Column(Integer, primary_key=True, index=True)
    tipo = Column(String, index=True) 
    latitud = Column(Float, nullable=False)
    longitud = Column(Float, nullable=False)
    nivel_urgencia = Column(Integer, default=1) 
    descripcion = Column(String, nullable=True)
    fecha_reporte = Column(DateTime, default=datetime.now)
    
    
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))
    
    usuario = relationship("UsuarioDB", back_populates="incidentes")