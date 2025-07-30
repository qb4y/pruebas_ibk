# README

## Synopsis

Este rol de Ansible despliega CrowdStrike Falcon Sensor en servidores Linux (RedHat-based) y Windows Server, automatizando la descarga desde MinIO mediante URLs pre-firmadas, instalación y configuración del agente EDR. Integra `vault_core` para credenciales y utiliza internamente `provider_minio` dinámico para gestión de instaladores, facilitando el despliegue masivo de seguridad endpoint con máxima simplicidad para el usuario.

---

## Variables

| Variable                                       | Default     | Comments                                                                                       |
| ---------------------------------------------- | ----------- | ---------------------------------------------------------------------------------------------- |
| **crowdstrike_console_url** (String)           | Desde Vault | **Auto** URL de la consola CrowdStrike Falcon, obtenida desde `vault_all_secrets.crowdstrike`. |
| **crowdstrike_customer_id** (String)           | Desde Vault | **Auto** Customer ID de CrowdStrike, obtenido desde Vault.                                     |
| **crowdstrike_endpoint_1** (String)            | Desde Vault | **Auto** Primer endpoint de conectividad CrowdStrike.                                          |
| **crowdstrike_endpoint_2** (String)            | Desde Vault | **Auto** Segundo endpoint de conectividad CrowdStrike.                                         |
| **crowdstrike_include_certificates** (Boolean) | `false`     | **Optional** Incluir descarga de certificados DigiCert (innecesario en Windows Server 2022+).  |

---

## Internal Variables (Managed Automatically)

| Variable                               | Type            | Comments                                                                    |
| -------------------------------------- | --------------- | --------------------------------------------------------------------------- |
| **provider_minio_product** (String)    | "crowdstrike"   | **Auto** Configurado internamente para provider_minio.                      |
| **crowdstrike_installer_url** (String) | URL pre-firmada | **Auto** URL temporal del instalador (generada por provider_minio).         |
| **crowdstrike_cert_urls** (List)       | Lista de URLs   | **Auto** URLs temporales de certificados DigiCert (si están habilitados).   |
| **os_key** (String)                    | Clave de SO     | **Auto** Clave del sistema operativo detectado (ej: "Windows", "RedHat-8"). |

---

## Results from execution

| Return Code Group | Return Code | Comments                                                             |
| ----------------- | ----------- | -------------------------------------------------------------------- |
| CROWDSTRIKE       | 1000        | El sistema operativo no es compatible con CrowdStrike Falcon.        |
| CROWDSTRIKE       | 1001        | No se encontró el instalador adecuado en MinIO para el SO detectado. |
| CROWDSTRIKE       | 1002        | Falló la obtención de credenciales CrowdStrike desde Vault.          |
| CROWDSTRIKE       | 1003        | Ya existe una instalación previa de CrowdStrike.                     |
| CROWDSTRIKE       | 1004        | Provider MinIO no pudo generar URLs de descarga.                     |
| CROWDSTRIKE       | 2000        | Falló la descarga del instalador desde MinIO (URL pre-firmada).      |
| CROWDSTRIKE       | 2001        | Error durante la instalación del agente CrowdStrike.                 |
| CROWDSTRIKE       | 2002        | Falló la configuración del Customer ID.                              |
| CROWDSTRIKE       | 3000        | Los servicios CrowdStrike no están activos después de instalación.   |
| CROWDSTRIKE       | 3001        | Sin conectividad con endpoints CrowdStrike.                          |

---

## Procedure

Este rol realiza los siguientes pasos:

### Integración con Dependencias:

- Obtención de credenciales CrowdStrike desde Vault via `vault_core`.
- Configuración automática de variables para `provider_minio` dinámico.
- Llamada interna a `provider_minio` para generar URLs pre-firmadas temporales.
- Validación de URLs de descarga y conectividad con MinIO.

### Instalación Windows:

- Descarga de instalador desde MinIO usando URL pre-firmada (sin credenciales).
- Descarga opcional de certificados DigiCert (saltada por defecto).
- **Instalación de certificados omitida** (Windows Server 2022+ ya los incluye).
- Instalación silenciosa con Customer ID: `/install /quiet /norestart CID=<id>`.
- Validación de servicios CSAgent y CSFalconService.

### Instalación Linux:

- Descarga de RPM específico para distribución/versión desde MinIO.
- Instalación via package manager (yum/dnf).
- Configuración de CID con falconctl.
- Inicio y habilitación del servicio falcon-sensor.

### Validaciones Post-Instalación:

- Verificación de estado de servicios/procesos CrowdStrike.
- Confirmación de configuración del agente.
- Reporte de estado final con información de conectividad.

---

## Supported Operating Systems

| OS Family          | Versions   | Installer Source                                    | Status |
| ------------------ | ---------- | --------------------------------------------------- | ------ |
| **Windows Server** | 2012 R2+   | `crowdstrike-installers/windows/WindowsSensor.exe`  | ✅     |
| **RedHat**         | 6, 7, 8, 9 | `crowdstrike-installers/linux/redhat-{version}.rpm` | ✅     |
| **CentOS**         | 6, 7, 8    | `crowdstrike-installers/linux/redhat-{version}.rpm` | ✅     |
| **Rocky Linux**    | 8, 9       | `crowdstrike-installers/linux/redhat-8.rpm`         | ✅     |
| **AlmaLinux**      | 8, 9       | `crowdstrike-installers/linux/redhat-8.rpm`         | ✅     |
| **Oracle Linux**   | 6, 7, 8    | `crowdstrike-installers/linux/redhat-{version}.rpm` | ✅     |

---

## Support

- Equipo de soporte: COE (Center of Excellence) Kyndryl - Interbank - Security Automation
- Canal interno: `#crowdstrike-deploy-support`
- Gestión de issues en el repositorio GitHub de `crowdstrike`.

---

## Deployment

### Tower

- Proyecto: `proj-crowdstrike-edr`
- Job Template: `jt-deploy-crowdstrike-falcon`
- Frecuencia: On demand, cada vez que se aprovisiona un nuevo servidor.
- Execution Environment: **Debe incluir MinIO Client (mc) preinstalado**.
- Reutilizable en automatizaciones de seguridad, hardening y compliance.

---

## Known problems and limitations

- Solo soporta RHEL/CentOS/Rocky/Alma/Oracle Linux 6/7/8/9 y Windows Server 2012+.
- Requiere conectividad con MinIO (para descarga) y endpoints CrowdStrike (puerto 443).
- URLs pre-firmadas expiran en 10 minutos; en caso de ejecuciones largas, pueden fallar.
- No valida compatibilidad de kernel Linux específicas.
- **Certificados DigiCert no se instalan** (optimización para Windows Server modernos).

---

## Prerequisites

- **Custom Execution Environment** con MinIO Client (mc) preinstalado.
- Acceso al Vault con credenciales CrowdStrike y MinIO.
- Conectividad con servidor MinIO (para descarga) y endpoints CrowdStrike (para registro).
- Rol dependiente: `vault_core` (para credenciales), `provider_minio` (llamado internamente).
- Servidores Linux con package manager y Windows con PowerShell 5.0+.
- Requiere collections: `ansible.windows`, `community.general`, `ansible.posix`.

---

## File Structure

```
crowdstrike/
├── tasks/
│   ├── main.yml                 # Control principal y llamada a provider_minio
│   ├── windows.yml              # Instalación específica para Windows
│   └── linux.yml               # Instalación específica para Linux
└── README.md                    # Esta documentación
```

---

## Migration Notes

### Desde Versión Anterior:

- **Playbooks existentes funcionan sin cambios** (compatibilidad total).
- **Certificados DigiCert se saltan automáticamente** (optimización).
- **Provider MinIO ahora es dinámico** (más eficiente).
- **URLs pre-firmadas** (mayor seguridad, expiran en 10 minutos).

### Beneficios de la Nueva Versión:

- ✅ **Playbook más simple**: Solo especificar `roles: [crowdstrike]`
- ✅ **Sin configuración manual**: CrowdStrike maneja provider_minio internamente
- ✅ **Más rápido**: Sin instalación innecesaria de certificados
- ✅ **Más seguro**: URLs temporales en lugar de credenciales hardcodeadas
- ✅ **Extensible**: Fácil agregar soporte para nuevos productos (Nessus, Splunk, etc.)
