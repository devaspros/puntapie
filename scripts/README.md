# Scripts de Despliegue a VPS

Idealmente, querrás desplegar tu aplicación en Heroku. Es la forma más sencilla de lanzar una aplicación Ruby on Rails.

Sin embargo, cuando necesites algo más personalizado o tu aplicación esté alojada en un VPS, entonces vas a necesitar codificar algunos scripts para desplegar tu aplicación.

Los scripts de esta sección son útiles para tener un despliegue similar a Capistrano. Estos scripts funcionan mejor si los configuras para que sean ejecutados por un servidor CI después de fusionar los cambios en una rama establecida.

## Estructura de Carpetas

Se asume la siguiente estructura:

```bash
~/PUNTAPIE # Carpeta principal de tu aplicación Ruby on Rails.
├── app # Carpeta del código Ruby on Rails.
└── deployments # Los despliegues pasan en una carpeta aparte que luego es sincronizada.
    ├── api-gems # Carpeta para instalar gemas. De aquí luego se hace un symlink.
    └── api-release # Baja los cambios más recientes del repo y sincroniza a la carpeta app/ usando RSync.
    └── logs # Para todos los logs que se generan durante un despliegue.
├── backups # Para todos los backups de la base de datos.
├── db # La base de datos SQL debe vivir en una carpeta independiente de todo el proceso para evitar perdida.
```

Puedes crear toda la estructura con este comando:

```bash
mkdir -p ~/PUNTAPIE/{app,deployments/{api-gems,api-release,logs},backups,db}
```

## Scripts

> [!Important]
> Nota que el url es `git@gh`. Eso es intencional. En el VPS se configura el acceso a github.com como alias `gh`

El primero paso es hacer un `git clone` manual desde la carpeta `~/PUNTAPIE/deployments/api-release` en el VPS.

Ejemplo:
```
cd PUNTAPIE/deployments/api-release

git clone git@gh:cesc1989/PUNTAPIE.git .
```

Luego, para iniciar el despliegue, desde la carpeta `api-release`, corre el script `deploy_api.sh`. Este es un entrypoint que ejecutará los demás scripts.

1. 001_deploy_api.sh
2. 002_pull_repo.sh
3. 003_after_deploy.sh
4. 004_application_start.sh

## Ver logs de un deploy

Cada paso del deploy escribe en su propio archivo dentro de `deployments/logs/NNN_paso.log` (ej. `001_pull_remote.log`, `002_bundle_install.log`). El nombre alfabético de estos archivos no coincide con el orden real de ejecución, así que revisarlos uno por uno con `tail` obliga a comparar timestamps a mano entre archivos.

En vez de eso, usa [lnav](https://lnav.org/) para ver todos los logs de deploy fusionados en una sola línea de tiempo real:

1. Instala `lnav` una sola vez en el servidor: `sudo apt install lnav`.
2. Corre el wrapper desde la carpeta `app` (o vía SSH: `ssh ubuntu@host 'bash ~/puntapie/app/scripts/deploy_logs.sh'`):
   ```
   bash scripts/deploy_logs.sh
   ```

El script instala automáticamente el formato custom (`scripts/lnav/puntapie_deploy_log.json`) la primera vez que corre, y abre `lnav` apuntando solo a los logs de deploy. Se excluye a propósito `100_cron.log` (backups de DB/logs), que tiene su propio monitor.

Atajos útiles dentro de `lnav`:
- `/` para buscar (ej. `/error|Error|FATAL`).
- `g` / `G` para ir al inicio / final.
- Si el último archivo sigue creciendo, `lnav` sigue el tail en vivo automáticamente.

Puedes apuntar el script a otra carpeta de logs (por ejemplo para probar con datos de prueba) definiendo `LOG_DIR`:
```
LOG_DIR=/ruta/a/otros/logs bash scripts/deploy_logs.sh
```
