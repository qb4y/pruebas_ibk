# README

## Synopsis

Este rol de Ansible actúa como proveedor dinámico de URLs pre-firmadas desde MinIO para múltiples productos de seguridad. Genera enlaces temporales seguros usando MinIO Client (mc) basado en mapeos centralizados y detección automática del sistema operativo. Diseñado como rol secundario para integrarse con roles principales como CrowdStrike, Nessus, Splunk, etc.

---

## Variables

| Variable                                          | Default     | Comments                                                                                     |
| ------------------------------------------------- | ----------- | -------------------------------------------------------------------------------------------- |
| **provider_minio_product** (String)               | No default  | **Mandatory** Producto a procesar: `crowdstrike`, `nessus`, etc. Definido por rol principal. |
| **PROVIDER_MINIO_INCLUDE_CERTIFICATES** (Boolean) | `false`     | **Optional** Incluir certificados adicionales (solo para productos que los requieran).       |
| **minio_host** (String)                           | Desde Vault | **Auto** Hostname o IP del servidor MinIO, obtenido desde `vault_all_secrets.minio`.         |
| **minio_port** (Integer)                          | Desde Vault | **Auto** Puerto de conexión al servidor MinIO.                                               |
| **minio_user** (String)                           | Desde Vault | **Auto** Usuario para autenticación en MinIO.                                                |
| **minio_password** (String)                       | Desde Vault | **Auto** Contraseña para autenticación en MinIO.                                             |
| **minio_bucket** (String)                         | Desde Vault | **Auto** Nombre del bucket que contiene los instaladores.                                    |

---

## Output Variables

| Variable                              | Type             | Comments                                                                         |
| ------------------------------------- | ---------------- | -------------------------------------------------------------------------------- |
| **product_installer_url** (String)    | URL pre-firmada  | URL temporal del instalador principal (expira en 10 minutos).                    |
| **product_certificate_urls** (List)   | Lista de URLs    | URLs temporales de certificados (si aplica para el producto).                    |
| **{product}\_installer_url** (String) | URL específica   | Variable de compatibilidad para cada producto (ej: `crowdstrike_installer_url`). |
| **{product}\_cert_urls** (List)       | Lista específica | Variable de compatibilidad para certificados por producto.                       |
| **os_key** (String)                   | Clave de SO      | Clave generada automáticamente (ej: "Windows", "RedHat-8", "Ubuntu-22").         |

---

## Results from execution

| Return Code Group | Return Code | Comments                                                          |
| ----------------- | ----------- | ----------------------------------------------------------------- |
| PROVIDER_MINIO    | 1000        | Producto no está soportado en los mapeos centralizados.           |
| PROVIDER_MINIO    | 1001        | Sistema operativo no soportado para el producto especificado.     |
| PROVIDER_MINIO    | 1002        | No se pudo establecer conectividad con el servidor MinIO.         |
| PROVIDER_MINIO    | 1003        | MinIO Client (mc) no está disponible en el execution environment. |
| PROVIDER_MINIO    | 1004        | El instalador solicitado no existe en el bucket MinIO.            |
| PROVIDER_MINIO    | 2000        | Error en la generación de URLs pre-firmadas con mc share.         |
| PROVIDER_MINIO    | 2001        | Variables de MinIO no fueron cargadas correctamente desde Vault.  |

---

## Procedure

Este rol realiza los siguientes pasos:

### Carga de Configuración:

- Carga de mapeos centralizados desde `vars/mapping_installers.yml`.
- Validación del producto especificado en `provider_minio_product`.
- Integración con credenciales MinIO desde `vault_all_secrets.minio`.

### Detección y Mapeo:

- Auto-detección del sistema operativo y versión del host.
- Construcción automática de clave de mapeo (ej: "Windows", "RedHat-8").
- Selección del instalador apropiado desde mapeos centralizados.
- Validación de compatibilidad SO vs producto.

### Generación de URLs Pre-firmadas:

- Configuración de alias MinIO Client (mc) con credenciales.
- Verificación de existencia de archivos en bucket MinIO.
- Generación de URLs temporales con `mc share download --expire 10m`.
- Procesamiento de certificados adicionales (si están habilitados).

### Establecimiento de Variables:

- Variables genéricas: `product_installer_url`, `product_certificate_urls`.
- Variables específicas: `{producto}_installer_url`, `{producto}_cert_urls`.
- Variables de contexto: `os_key`, `installer_path`.

---

## Supported Products

| Producto        | Windows | RHEL/CentOS | Ubuntu/Debian | Certificados  | Descripción                          |
| --------------- | ------- | ----------- | ------------- | ------------- | ------------------------------------ |
| **crowdstrike** | ✅      | ✅          | ❌            | ✅ (Opcional) | CrowdStrike Falcon Sensor - EDR      |
| **nessus**      | ✅      | ✅          | ✅            | ❌            | Nessus Agent - Vulnerability Scanner |

---

## Supported Operating Systems

### Claves de Mapeo Generadas:

- **Windows**: `Windows`
- **RedHat Family**: `RedHat-8`, `CentOS-7`, `Rocky-9`, `AlmaLinux-8`, `OracleLinux-8`
- **Debian Family**: `Ubuntu-20`, `Ubuntu-22`, `Debian-11`, `Debian-12`

---

## Support

- Equipo de soporte: COE (Center of Excellence) Kyndryl - Interbank - Security Automation
- Canal interno: `#minio-provider-support`
- Gestión de issues en el repositorio GitHub de `provider_minio`.

---

## Deployment

### Tower

- Proyecto: `proj-provider-minio`
- Job Template: `jt-minio-url-generator`
- Frecuencia: On demand, como rol secundario en despliegues.
- Execution Environment: **Debe incluir MinIO Client (mc) preinstalado**.
- Reutilizable en automatizaciones de seguridad y aprovisionamiento.

---

## Known problems and limitations

- Requiere MinIO Client (mc) preinstalado en Custom Execution Environment.
- URLs pre-firmadas expiran en 10 minutos (configurable en `global_config.default_expiry`).
- Solo valida existencia de archivos, no su integridad.
- Requiere conectividad de red con el servidor MinIO desde el control node.
- No soporta autenticación MinIO con certificados SSL personalizados.

---

## Prerequisites

- **Custom Execution Environment** con MinIO Client (mc) preinstalado.
- Acceso al Vault con credenciales MinIO (`vault_core` debe ejecutarse previamente).
- Conectividad de red desde control node con servidor MinIO.
- Bucket MinIO configurado con instaladores organizados según estructura esperada.
- Mapeos actualizados en `vars/mapping_installers.yml` para productos requeridos.

---

## File Structure

```
provider_minio/
├── tasks/
│   ├── main.yml                 # Control principal
│   └── generate_urls.yml        # Lógica dinámica unificada
├── vars/
│   └── mapping_installers.yml   # Mapeos centralizados por producto
└── README.md                    # Esta documentación
```
