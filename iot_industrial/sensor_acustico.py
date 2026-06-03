import requests
import time
import random

# --- CONFIGURACIÓN DEL DISPOSITIVO IoT ---
API_URL = "http://localhost:8000/incidentes/"
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJKYXBwIiwiZXhwIjoxNzgwNTcwNDA0fQ.nDlR1keSRdpE5UthdfeMCEuq_h4e0lTi3Wyzu6ULVWU" 

# Ubicación estática del poste inteligente
SENSOR_LAT = -12.0621
SENSOR_LNG = -77.1435

def generar_decibelios():
    # 90% del tiempo hay ruido urbano normal, 10% de probabilidad de un pico fuerte
    if random.random() > 0.90:
        return round(random.uniform(120.0, 140.0), 1) # Disparo o choque en carretera
    else:
        return round(random.uniform(40.0, 75.0), 1)   # Tráfico y ambiente normal

def monitorear_audio():
    print("--- Iniciando Módulo IoT Acústico CitySafe (MOTE-001) ---")
    
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json"
    }

    while True:
        db_actual = generar_decibelios()
        print(f"[Micrófono] Nivel de ruido local: {db_actual} dB")

        if db_actual > 120.0:
            print(f"⚠️ [ALERTA] Ruido extremo detectado ({db_actual} dB). Transmitiendo telemetría...")
            
            # Esquema exacto que espera la API
            payload = {
                "tipo": "Alarma Acústica",
                "latitud": SENSOR_LAT,
                "longitud": SENSOR_LNG,
                "nivel_urgencia": 5,
                "descripcion": f"Pico acústico anómalo de {db_actual} dB detectado automáticamente. Posible altercado o disparo en la zona."
            }

            try:
                response = requests.post(API_URL, json=payload, headers=headers)
                if response.status_code == 200:
                    print("[ÉXITO] Incidente despachado a la red CitySafe.\n")
                else:
                    print(f"[ERROR] Fallo en la red. Código: {response.status_code}\n")
            except Exception as e:
                print(f"[CRÍTICO] Conexión perdida con el servidor central: {e}\n")
            
            # Entra en modo de enfriamiento temporal para no generar reportes duplicados
            time.sleep(15) 
        else:
            # Pausa corta
            time.sleep(3)

if __name__ == "__main__":
    monitorear_audio()