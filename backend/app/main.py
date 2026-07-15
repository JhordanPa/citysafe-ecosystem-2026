from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List
from datetime import datetime
from . import models, schemas, auth, database
import json
import paho.mqtt.publish as publish

MQTT_BROKER = "broker.emqx.io"
MQTT_TOPIC = "citysafe/alertas"

def notificar_godot(incidente):
    # Payload con los datos de una notificación de Citysafe
    payload = {
        "id": incidente.id,
        "tipo": incidente.tipo,
        "latitud": incidente.latitud,
        "longitud": incidente.longitud,
        "nivel_urgencia": incidente.nivel_urgencia,
        "descripcion": incidente.descripcion
    }
    
    # Se envía el mensaje al broker mqtt[cite: 38]
    try:
        publish.single(MQTT_TOPIC, payload=json.dumps(payload), hostname=MQTT_BROKER)
        print(f"Alerta MQTT enviada: {payload['tipo']}")
    except Exception as e:
        print(f"Error al enviar MQTT: {e}")

models.Base.metadata.create_all(bind=database.engine)
app = FastAPI(title="CitySafe API - Ecosistema de Seguridad", version="1.0.0")

# Configuracion del protocolo de seguridad Cors para distintos puertos[cite: 38]
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_current_user(db: Session = Depends(database.get_db), username: str = Depends(auth.validar_token)):
    user = db.query(models.UsuarioDB).filter(models.UsuarioDB.username == username).first()
    if user is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return user

# POST para registrar usuario y contraseña[cite: 38]
@app.post("/usuarios/", response_model=schemas.Usuario, tags=["Usuarios"])
def registrar_usuario(user: schemas.UsuarioCreate, db: Session = Depends(database.get_db)):
    db_user = db.query(models.UsuarioDB).filter(models.UsuarioDB.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="El nombre de usuario ya está registrado")
    
    hashed_password = auth.obtener_password_hash(user.password)
    nuevo_usuario = models.UsuarioDB(username=user.username, hashed_password=hashed_password, rol=user.rol)
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)
    return nuevo_usuario

# GET para tener datos e informacion propia (nombre, id, rol)[cite: 38]
@app.get("/usuarios/me", response_model=schemas.Usuario, tags=["Usuarios"])
def read_users_me(current_user: models.UsuarioDB = Depends(get_current_user)):
    return current_user

# POST para login con usuario y contraseña usando protocolo estándar OAuth2[cite: 38]
@app.post("/token", tags=["Seguridad"])
def login_para_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(database.get_db)):
    user = db.query(models.UsuarioDB).filter(models.UsuarioDB.username == form_data.username).first()
    
    if not user or not auth.verificar_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = auth.crear_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}

# POST para el reporte/registro de incidentes[cite: 38]
@app.post("/incidentes/", response_model=schemas.Incidente, tags=["Incidentes y Despacho"])
def reportar_incidente(
    incidente: schemas.IncidenteCreate, 
    db: Session = Depends(database.get_db), 
    current_user: models.UsuarioDB = Depends(get_current_user)
):
    # 1. Identificamos si el reporte viene de un dispositivo IoT simulado
    es_iot = "Sensor de Ruido" in incidente.tipo or "Botón de pánico" in incidente.tipo or "Tótem Físico" in incidente.tipo

    if es_iot:
        # Buscamos un reporte de este mismo usuario que comparta las mismas coordenadas o el mismo nombre
        incidente_existente = db.query(models.IncidenteDB).filter(
            models.IncidenteDB.usuario_id == current_user.id
        ).filter(
            or_(
                (models.IncidenteDB.latitud == incidente.latitud) & (models.IncidenteDB.longitud == incidente.longitud),
                models.IncidenteDB.tipo == incidente.tipo
            )
        ).first()

        # Si encontramos basura previa en ese punto, la borramos
        if incidente_existente:
            db.delete(incidente_existente)
            db.commit()

    # 2. Creamos y guardamos el informe nuevo y limpio en la DB
    nuevo_incidente = models.IncidenteDB(**incidente.model_dump(), usuario_id=current_user.id)
    db.add(nuevo_incidente)
    db.commit()
    db.refresh(nuevo_incidente)
    
    # Notificamos a todos los clientes (Godot) sobre el nuevo pin
    notificar_godot(nuevo_incidente)
    
    return nuevo_incidente

# GET para listar incidentes registrados[cite: 38]
@app.get("/incidentes/", response_model=List[schemas.Incidente], tags=["Incidentes y Despacho"])
def listar_incidentes(db: Session = Depends(database.get_db)):
    return db.query(models.IncidenteDB).all()

# Funcion de borrado para los incidentes registrados[cite: 38]
@app.delete("/incidentes/{incidente_id}", tags=["Incidentes y Despacho"])
def eliminar_incidente(
    incidente_id: int, 
    db: Session = Depends(database.get_db),
    current_user: models.UsuarioDB = Depends(get_current_user)
):
    incidente = db.query(models.IncidenteDB).filter(models.IncidenteDB.id == incidente_id).first()
    if not incidente:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")
    
    if incidente.usuario_id != current_user.id and current_user.rol not in ["gestor", "admin"]:
        raise HTTPException(status_code=403, detail="No autorizado para eliminar este incidente")
        
    db.delete(incidente)
    db.commit()
    return {"message": "Incidente eliminado exitosamente"}