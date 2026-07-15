#!/bin/bash

# Colores declarados
VERDE='\033[0;32m'
AZUL='\033[0;34m'
NC='\033[0m'

echo -e "${AZUL}Iniciando instalacion de archivos necesarios...${NC}"
echo "------------------------------------------------------------"

# Solicitar permisos de administrador al inicio
echo -e "${AZUL}[1/5] Actualizando el sistema operativo...${NC}"
sudo apt update && sudo apt upgrade -y

# Instala Python y Git
echo -e "${AZUL}[2/5] Instalando Python y herramientas de entorno...${NC}"
sudo apt install python3 python3-venv python3-pip git -y

# Instala Flutter
echo -e "${AZUL}[3/5] Instalando Flutter SDK a nivel global...${NC}"
sudo snap install flutter --classic

# Instala el Backend local
echo -e "${AZUL}[4/6] Configurando entorno virtual y librerías del Backend...${NC}"
if [ -d "backend" ]; then
    cd backend
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
    cd ..
else
    echo "Error: No se encontró la carpeta 'backend'"
fi

# Configura el entorno virtual para IoT Industrial
echo -e "${AZUL}[5/6] Configurando entorno virtual de IoT Industrial...${NC}"
if [ -d "iot_industrial" ]; then
    cd iot_industrial
    python3 -m venv venv
    source venv/bin/activate

    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    else
        echo "No se encontró requirements.txt en iot_industrial."
    fi

    deactivate
    cd ..
else
    echo "Error: No se encontró la carpeta 'iot_industrial'"
fi

# Configura el Flutter Mobile local
echo -e "${AZUL}[5/5] Descargando paquetes y librerías de Flutter Mobile...${NC}"
if [ -d "mobile" ]; then
    cd mobile
    flutter pub get
    cd ..
else
    echo "Error: No se encontró la carpeta 'mobile'"
fi

echo "------------------------------------------------------------"
echo -e "${VERDE} ¡Instalación completada con éxito!${NC}"
echo -e "${VERDE}Todo el ecosistema CitySafe está listo para ser usado.${NC}"