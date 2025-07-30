# README

## Synopsis

Este rol de Ansible registra automáticamente servidores Linux y Windows en AWX/Ansible Tower, creando inventarios y grupos dinámicamente según el sistema operativo detectado. Integra `vault_core` para credenciales seguras y automatiza completamente el proceso de onboarding de hosts, incluyendo detección de facts del sistema, creación de inventarios si no existen, asignación automática a grupos por OS y configuración de variables del host.

---

## Variables

| Variable                          | Default                 | Comments                                                                                      |
| --------------------------------- | ----------------------- | --------------------------------------------------------------------------------------------- |
| **ambiente** (String)             | **Requerido**           | **Required** Ambiente del servidor (dev/qa/prod). Debe proporcionarse como variable de AWX.  |
| **inventory** (String)            | "inventario de hosts"   | **Auto** Nombre del inventario AWX donde se registrará el host.                              |
| **group** (String)                | Auto-detectado          | **Auto** Grupo basado en OS family ("linux" o "windows").                                   |
| **awx_hostname** (String)         | ansible_fqdn            | **Auto** Hostname del servidor, detectado automáticamente.                                   |
| **awx_ip_address** (String)       | ansible_default_ipv4.ip | **Auto** Dirección IP del servidor, detectada automáticamente.                               |

---

## Internal Variables (Managed Automatically)

| Variable                    | Type     | Comments                                                                           |
| --------------------------- | -------- | ---------------------------------------------------------------------------------- |
| **awx_url** (String)        | URL      | **Auto** URL del servidor AWX, obtenida desde `vault_all_secrets.awx`.            |
| **awx_token** (String)      | Token    | **Auto** Token de autenticación AWX, obtenido desde Vault.                        |
| **awx_verify_ssl** (Bool)   | Boolean  | **Auto** Verificación SSL para conexiones AWX, configurada desde Vault.           |
| **awx_timeout** (Integer)   | Segundos | **Auto** Timeout para llamadas API AWX, configurado desde Vault.                  |
| **awx_system_info** (Dict)  | Dict     | **Auto** Información del sistema (OS family, distribución, versión).              |
| **inventory_id** (Integer)  | ID       | **Auto** ID del inventario AWX (existente o recién creado).                       |
| **group_id** (Integer)      | ID       | **Auto** ID del grupo AWX (existente o recién creado).                            |
| **host_id** (Integer)       | ID       | **Auto** ID del host AWX después del registro.                                    |

---

## Results from execution

| Return Code Group | Return Code | Comments                                                                     |
| ----------------- | ----------- | ---------------------------------------------------------------------------- |
| AWX_REGISTER      | 4000        | La variable 'ambiente' es requerida pero no fue proporcionada.              |
| AWX_REGISTER      | 4001        | No se pudieron obtener las credenciales AWX desde Vault.                    |
| AWX_REGISTER      | 4002        | Error de conectividad con el servidor AWX.                                  |
| AWX_REGISTER      | 4003        | No se pudo detectar información del sistema (hostname/IP).                  |
| AWX_REGISTER      | 5000        | Error al crear o verificar el inventario en AWX.                            |
| AWX_REGISTER      | 5001        | Error al crear o verificar el grupo en AWX.                                 |
| AWX_REGISTER      | 5002        | Error al crear o actualizar el host en AWX.                                 |
| AWX_REGISTER      | 5003        | Error al asociar el host al grupo correspondiente.                          |
| AWX_REGISTER      | 6000        | El host se registró pero no se pudo verificar la asociación al grupo.       |
| AWX_REGISTER      | 6001        | Timeout durante las operaciones con la API de AWX.                          |

---

## Procedure

Este rol realiza los siguientes pasos:

### Validación y Autenticación:

- Validación de variables requeridas (especialmente `ambiente`).
- Obtención de credenciales AWX desde Vault via `vault_core`.
- Verificación de conectividad con el servidor AWX.
- Recolección de facts del sistema (hostname, IP, OS family).

### Gestión de Inventario:

- Verificación de existencia del inventario "inventario de hosts".
- Creación automática del inventario si no existe.
- Configuración con organización por defecto de AWX.

### Gestión de Grupos:

- Detección automática del sistema operativo (Linux/Windows).
- Verificación de existencia del grupo correspondiente ("linux" o "windows").
- Creación automática del grupo si no existe en el inventario.

### Registro de Host:

- Verificación si el host ya existe en el inventario.
- Creación de nuevo host con variables del sistema si no existe.
- Actualización de host existente con información actualizada.
- Configuración de variables: IP, ambiente, fecha de actualización, OS info.

### Asociación al Grupo:

- Múltiples métodos de asociación host-grupo con fallbacks.
- Verificación final de que el host esté correctamente asignado al grupo.
- Reporte de estado final del registro.

---

## Supported Operating Systems

| OS Family          | Versions        | Group Assignment | Status |
| ------------------ | --------------- | ---------------- | ------ |
| **Linux**          | Todas las distros | `linux`         | ✅     |
| **Windows**        | Server/Desktop   | `windows`        | ✅     |
| **RedHat**         | 6, 7, 8, 9      | `linux`          | ✅     |
| **CentOS**         | 6, 7, 8         | `linux`          | ✅     |
| **Ubuntu**         | Todas           | `linux`          | ✅     |
| **SLES**           | Todas           | `linux`          | ✅     |
| **Windows Server** | 2012+           | `windows`        | ✅     |

---

## Support

- Equipo de soporte: COE (Center of Excellence) Kyndryl - Interbank - Infrastructure Automation
- Canal interno: `#awx-register-support`
- Gestión de issues en el repositorio GitHub de `awx_register`.

---

## Deployment

### Tower/AWX

- Proyecto: `proj-infrastructure-automation`
- Job Template: `jt-register-host-awx`
- Frecuencia: On demand, cada vez que se aprovisiona un nuevo servidor.
- Variables requeridas en template: `ambiente` (survey prompt).
- Reutilizable en workflows de provisioning y onboarding automatizado.

### Example Playbook

```yaml
---
- name: Registrar servidor en AWX
  hosts: all
  gather_facts: yes
  roles:
    - role: awx_register
      vars:
        ambiente: "{{ ambiente }}"  # Variable desde AWX template
```

---

## Known problems and limitations

- Requiere variable `ambiente` obligatoria desde el template de AWX.
- Solo soporta inventario fijo "inventario de hosts" (no configurable).
- Grupos limitados a "linux" y "windows" basados en `ansible_os_family`.
- Requiere conectividad con AWX y acceso a Vault para credenciales.
- La asociación host-grupo puede fallar en algunas versiones específicas de AWX.
- No valida permisos específicos del usuario/token en AWX.

---

## Prerequisites

- Acceso al Vault con credenciales AWX configuradas.
- Conectividad con servidor AWX/Ansible Tower (puerto 443/80).
- Rol dependiente: `vault_core` (para credenciales).
- Facts de Ansible recolectados correctamente (`gather_facts: yes`).
- Token AWX con permisos para crear inventarios, grupos y hosts.
- Collections requeridas: `ansible.builtin`, `community.general`.

---

## File Structure

```
awx_register/
├── tasks/
│   ├── main.yml         # Validaciones y flujo principal
│   ├── awx_auth.yml     # Autenticación con AWX via Vault
│   ├── facts.yml        # Recolección de facts del sistema
│   └── awx_register.yml # Registro completo en AWX
├── vars/
│   └── main.yml         # Variables por defecto
├── meta/
│   └── main.yml         # Dependencias del rol
└── README.md            # Esta documentación
```

---

## Migration Notes

### Para Nuevos Usuarios:

- **Configuración mínima**: Solo requiere variable `ambiente` en el job template.
- **Automático**: Detección de sistema, creación de inventarios y grupos automática.
- **Idempotente**: Ejecutable múltiples veces sin problemas.

### Beneficios:

- ✅ **Onboarding automático**: Registro completo sin intervención manual
- ✅ **Gestión dinámica**: Crea inventarios y grupos según necesidad
- ✅ **Integración Vault**: Credenciales seguras sin hardcoding
- ✅ **Multi-OS**: Soporte completo Linux y Windows
- ✅ **Información rica**: Variables del sistema automáticamente configuradas
- ✅ **Workflow-ready**: Integrable en pipelines de provisioning

---

## Example Variables in AWX Job Template

```yaml
---
# Survey Variables (User Input)
ambiente: "{{ ambiente }}"  # Prompt: "qa", "dev", "prod"

# Optional Overrides (Advanced)
inventory: "inventario de hosts"  # Default value
awx_verify_ssl: true             # Default from Vault
awx_timeout: 30                  # Default from Vault
```