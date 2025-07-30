# Rol Principal de Parchado - README

## Descripción

Rol Ansible multiplataforma que automatiza el proceso de parchado tanto para sistemas **Windows** como **Linux**. Incluye detección automática del sistema operativo y ejecuta el parchado correspondiente usando las herramientas apropiadas para cada plataforma.

### Características principales:
- **Detección automática de SO** o selección manual via `type_os`
- **Windows**: Soporte para WSUS y SCCM 
- **Linux**: Soporte para Satellite, Internet, Reposerver, SUSE Manager
- **Validaciones exhaustivas** de variables y prerrequisitos
- **Manejo de errores** con procedimientos de rescate
- **Reportes detallados** en formato JSON
- **Logging y notificaciones** opcionales

---

## Variables Requeridas

### Para Windows (`type_os: "windows"`)

| Variable | Ejemplo | Descripción |
|----------|---------|-------------|
| `patching_mode` | `"wsus"` | Modo de parchado: `wsus` o `sccm` |
| `target_environment` | `"DES"` | Ambiente: `PROD`, `DES`, `QA` |
| `domain_name` | `"grupoib.local"` | Dominio de Active Directory |
| `wsus_server` | `"ibmwsusvp01"` | Servidor WSUS (solo para modo wsus) |
| `ad_username` | `"itbipat1"` | Usuario de Active Directory |
| `ad_password` | `"password"` | Contraseña del usuario AD |
| `selected_category` | `["CriticalUpdates", "SecurityUpdates"]` | Categorías de parches |

### Para Linux (`type_os: "linux"`)

| Variable | Ejemplo | Descripción |
|----------|---------|-------------|
| `patch_source` | `"satellite"` | Fuente: `internet`, `satellite`, `reposerver`, `susemanager` |
| `patch_type` | `"security_all"` | Tipo: `update_all`, `security_all`, `rcp_all`, `bugfix_all` |
| `backup_to_jumphost` | `true` | Hacer backup de configuración |
| `reboot_required` | `true` | Reiniciar servidor después del parchado |

---

## Variables Opcionales

### Windows

| Variable | Default | Descripción |
|----------|---------|-------------|
| `update_operation` | `"install"` | Operación: `install` o `download` |
| `reboot_after_installation` | `true` | Reiniciar después de instalar |
| `resume_services` | `true` | Reanudar servicios |
| `perform_ou_registration` | `false` | Registrar en OU de AD |
| `rescue_endpoint` | `false` | Ejecutar procedimientos de rescate |
| `save_logs` | `false` | Guardar logs detallados |
| `logs_path` | `"C:/temp/patch_logs"` | Ruta para logs |

### Linux

| Variable | Default | Descripción |
|----------|---------|-------------|
| `package_download_location` | `""` | Ubicación para descargar paquetes |
| `yum_exclude_patch_list` | `""` | Parches a excluir (separados por coma) |
| `jumphost_path` | `"/tmp"` | Ruta en jumphost para backups |
| `boot_space_threshold_mb` | `256` | Umbral espacio libre /boot (MB) |
| `force_reboot` | `false` | Forzar reinicio aunque esté actualizado |
| `send_email` | `false` | Enviar notificaciones por email |
| `teams_notification` | `false` | Notificaciones MS Teams |
| `service_restart_list` | `""` | Servicios a reiniciar |
| `fail_on_error` | `true` | Fallar en caso de error |

---

## Ejemplos de Uso

### 1. Windows con WSUS (Ejemplo completo)

```yaml
---
- name: Parchado Windows con WSUS
  hosts: windows_servers
  vars:
    type_os: "windows"
    patching_mode: "wsus"
    target_environment: "DES"
    domain_name: "grupoib.local"
    wsus_server: "ibmwsusvp01"
    ad_username: "itbipat1"
    ad_password: "G.3pmE_yTZvpUZ98Q.FzsRZ4V"
    selected_category: 
      - "CriticalUpdates"
      - "SecurityUpdates"
    # Opcionales
    reboot_after_installation: true
    save_logs: true
    logs_path: "C:/temp/patch_logs"
  roles:
    - parchado
```

### 2. Linux con Satellite

```yaml
---
- name: Parchado Linux con Satellite
  hosts: linux_servers
  vars:
    type_os: "linux"
    patch_source: "satellite"
    patch_type: "security_all"
    backup_to_jumphost: true
    reboot_required: true
    jumphost_path: "/backup/patches"
    # Opcionales
    send_email: true
    recipients: ["admin@empresa.com"]
    smtp_host_ip: "10.1.1.100"
  roles:
    - parchado
```

### 3. Detección Automática de SO

```yaml
---
- name: Parchado con detección automática
  hosts: mixed_servers
  vars:
    # Windows vars (se usan si es Windows)
    patching_mode: "wsus"
    target_environment: "PROD"
    domain_name: "grupoib.local"
    wsus_server: "ibmwsusvp01"
    ad_username: "itbipat1"
    ad_password: "password"
    selected_category: ["SecurityUpdates"]
    
    # Linux vars (se usan si es Linux)
    patch_source: "satellite"
    patch_type: "update_all"
    backup_to_jumphost: false
    reboot_required: true
  roles:
    - parchado
```

### 4. Usando desde main_router.yml

```bash
ansible-playbook main_router.yml \
  -i "servidor.ejemplo.com," \
  -e actions=parchado \
  -e type_os=windows \
  -e patching_mode=wsus \
  -e target_environment=DES \
  -e domain_name=grupoib.local \
  -e wsus_server=ibmwsusvp01 \
  -e ad_username=itbipat1 \
  -e ad_password=G.3pmE_yTZvpUZ98Q.FzsRZ4V \
  -e selected_category='["CriticalUpdates","SecurityUpdates"]'
```

---

## Categorías de Parches Windows

### Categorías Disponibles:
- `CriticalUpdates` - Actualizaciones críticas
- `SecurityUpdates` - Actualizaciones de seguridad  
- `UpdateRollups` - Paquetes acumulativos
- `FeaturePacks` - Paquetes de características
- `ServicePacks` - Service Packs
- `Definition Updates` - Actualizaciones de definiciones
- `Drivers` - Controladores
- `Tools` - Herramientas

### Combinaciones Recomendadas:
```yaml
# Solo críticas y seguridad (recomendado)
selected_category: ["CriticalUpdates", "SecurityUpdates"]

# Completo (incluye drivers y herramientas)
selected_category: ["CriticalUpdates", "SecurityUpdates", "UpdateRollups", "Drivers"]

# Solo actualizaciones de seguridad
selected_category: ["SecurityUpdates"]
```

---

## Tipos de Parchado Linux

### Tipos Principales:
- `update_all` - Actualizar todos los paquetes
- `security_all` - Solo actualizaciones de seguridad
- `rcp_all` - Paquetes Red Hat Customer Portal
- `bugfix_all` - Correcciones de errores

### Por Severidad (solo RHEL):
- `severity_high` - Alta severidad
- `severity_medium` - Severidad media  
- `severity_low` - Baja severidad
- `severity_all` - Todas las severidades

### Operaciones Especiales:
- `download_only` - Solo descargar (RHEL)
- `install_from_folder` - Instalar desde carpeta (RHEL)

---

## Fuentes de Parchado Linux

### Fuentes Soportadas:

| Fuente | Descripción | SO Soportados |
|--------|-------------|---------------|
| `internet` | Repositorios oficiales de internet | RHEL, CentOS, Ubuntu, SUSE |
| `satellite` | Red Hat Satellite Server | RHEL, CentOS |
| `reposerver` | Servidor de repositorios local | RHEL, CentOS |
| `susemanager` | SUSE Manager | SUSE Linux Enterprise |

---

## Validaciones y Verificaciones

### Pre-validaciones Windows:
- ✅ Conectividad WinRM
- ✅ Permisos de administrador
- ✅ Espacio en disco suficiente
- ✅ Servicios Windows Update
- ✅ Conectividad WSUS/SCCM

### Pre-validaciones Linux:
- ✅ Conectividad SSH
- ✅ Permisos sudo
- ✅ Espacio en `/boot` y `/var`  
- ✅ Carga del sistema
- ✅ Estado de cluster (opcional)
- ✅ Repositorios configurados

---

## Manejo de Errores

### Códigos de Retorno Windows:

| Código | Descripción |
|--------|-------------|
| `2000` | Actualizaciones instaladas exitosamente |
| `2001` | No hay actualizaciones disponibles |
| `3000` | Modo de parchado inválido |
| `3001` | Variables faltantes para WSUS |
| `3003` | Fallo conectividad servidor WSUS |
| `3007` | Fallo instalación de actualizaciones |

### Procedimientos de Rescate:
- Reset de componentes WSUS
- Limpieza de archivos temporales
- Reinicio de servicios
- Reintento automático

---

## Salida y Reportes

### Estructura del Resultado:

```json
{
  "parchado_resultado": {
    "timestamp": "2025-01-24T10:30:00Z",
    "servidor": "servidor01",
    "tipo_os": "windows",
    "sistema_operativo": "Windows",
    "configuracion_windows": {
      "patching_mode": "wsus",
      "target_environment": "DES", 
      "wsus_server": "ibmwsusvp01",
      "selected_category": ["CriticalUpdates", "SecurityUpdates"]
    },
    "configuracion_linux": "N/A",
    "estado": "Completado",
    "return_code": "2000"
  }
}
```

---

## Prerequisitos

### Windows:
- WinRM habilitado y configurado
- PowerShell 3.0+
- Usuario con permisos de administrador local
- Conectividad a servidor WSUS/SCCM
- Espacio suficiente en disco

### Linux:
- SSH configurado
- Usuario con permisos sudo
- Espacio suficiente en `/boot` (256MB+)
- Repositorios configurados según `patch_source`
- Python 2.7+ o 3.6+

### Colecciones Ansible:
```bash
ansible-galaxy collection install community.windows
ansible-galaxy collection install ansible.windows  
ansible-galaxy collection install community.general
```

---

## Integración con main_router.yml

Para integrar con el sistema existente, agregar en `main_router.yml`:

```yaml
- name: Ejecutar parchado del sistema
  ansible.builtin.include_role:
    name: parchado
  when: actions == 'parchado'
```

Y agregar `parchado` a la lista de `valid_actions`.

---

## Soporte y Contacto

**Desarrollador**: Wilber Ticllasuca  
**Empresa**: Kyndryl  
**Licencia**: Kyndryl Intellectual Property

Para soporte técnico, consultar la documentación interna de Kyndryl o contactar al equipo de Infrastructure Automation.