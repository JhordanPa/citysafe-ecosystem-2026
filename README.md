**CitySafe Ecosystem 2026**
Sistema de Monitoreo Urbano y Gestión de Alertas de Seguridad

## Integrantes
* Jeick Carlos Emilio Melgar Matos - [Lider]
* Jhordan Alexis Pasion Paucar - [Participe]
* Alex Antony Ramos Rojas - [Participe]
* Diego Andre Yupanqui Carpio - [Participe]

## Instalación (Guía para Linux / Ubuntu)
Recuerde descromprimir el .zip en la raiz del sistema.

### Pasos a seguir:

1. **Apertura de una terminal con ubicacion a la carpeta**
Abra una nueva terminal con ubicacion a esta carpeta principal `citysafe-ecosystem-2026-main`

    bash
    cd citysafe-ecosystem-2026-main
    

Si el nombre lo ha cambiado, reemplazarlo.

    bash
    cd nombre_nuevo
    

_Todo esto teniendo en cuenta que el archivo .zip fue descomprimido en la raíz del sistema_

2. **Instalacion de dependencias y requerimientos**
Escriba los comandos siguientes:

    bash
    chmod +x mandatory.sh
    ./mandatory.sh
    

Espere la instalacion de todos los archivos...

3. **Iniciando la base de datos**
Ya terminado la instalación, ingrese a la carpeta /backend desde la terminal.

    bash
    cd backend
    

Una vez dentro, ejecute los comandos:

    bash
    source venv/bin/activate
    uvicorn app.main:app --reload
    

La base de datos habrá sido iniciada correctamente

4. **Iniciando el aplicativo**
Abra una nueva terminal con ubicacion a la carpeta principal en la que estamos trabajando.

    bash
    cd citysafe-ecosystem-2026-main
    

Nos dirigimos a iniciar el aplicativo ahora...

    bash
    cd mobile
    flutter run -d tipo_de_inicio
    

El tipo_de_inicio reemplazarlo por cualquiera de su preferencia:
    web-server
    chrome
    mobile

_ejem: flutter run -d chrome_
