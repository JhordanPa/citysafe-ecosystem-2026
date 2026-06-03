import requests
import time

API_URL = "http://localhost:8000/incidentes/"
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJKYXBwIiwiZXhwIjoxNzgwNTcwNDA0fQ.nDlR1keSRdpE5UthdfeMCEuq_h4e0lTi3Wyzu6ULVWU" 

# Ubicación estática del Botón
BOTON_LAT = -12.0431
BOTON_LNG = -77.0282

def iniciar_totem():
    print("--- Tótem de Seguridad CitySafe (BOTON-002) Iniciado ---")
    print("Esperando interacción ciudadana...")
    
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json"
    }

    while True:
        input("\n[PULSA ENTER PARA ACTIVAR EL BOTÓN DE PÁNICO]")
        
        print("🚨 ¡BOTÓN PRESIONADO! Enviando señal de auxilio a la central...")
        
        payload = {
            "tipo": "Botón de Pánico",
            "latitud": BOTON_LAT,
            "longitud": BOTON_LNG,
            "nivel_urgencia": 5,
            "descripcion": "Activación manual del tótem de seguridad. Requiere asistencia policial inmediata."
        }

        try:
            response = requests.post(API_URL, json=payload, headers=headers)
            if response.status_code == 200:
                print("[ÉXITO] Central notificada. Unidades en camino.")
            else:
                print(f"[ERROR] Código: {response.status_code}")
        except Exception as e:
            print(f"[CRÍTICO] Fallo de red: {e}")
            
        time.sleep(2)

if __name__ == "__main__":
    iniciar_totem()