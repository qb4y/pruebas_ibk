# README

## Synopsis

Este rol de Ansible automatiza la creación de usuarios y grupos en servidores Linux (RedHat-based) y Windows Server. Permite definir estructuras complejas de usuarios con diferentes niveles de permisos mediante un sistema de categorización numérica, facilitando el despliegue masivo y estandarizado de cuentas de usuario en infraestructuras híbridas. El rol genera contraseñas aleatorias automáticamente para mejorar la seguridad.

---

## Variables

| Variable                                 | Default                     | Comments                                                            |
| ---------------------------------------- | --------------------------- | --------------------------------------------------------------------|
| **CU_GRUPOS** (List)                     | `[]`                        | **Mandatory** Lista de grupos a crear con sus usuarios y permisos.  |
| **CU_PERMISSION_MAP** (Dictionary)       | Definido internamente       | Mapeo de códigos numéricos a permisos específicos por OS.           |
| **CU_FAKE_ENVIRONMENT** (Boolean)        | `false`                     | Permite simular la creación sin ejecutar comandos reales.           |
| **CU_FORCE_PASSWORD_CHANGE** (Boolean)   | `true`                      | Fuerza cambio de contraseña en primer login (Windows).              |
| **CU_DEFAULT_SHELL** (String)            | `/bin/bash`                 | Shell por defecto para usuarios Linux.                              |
| **CU_HOME_BASE_PATH** (String)           | `/home` (Linux), `C:\Users` (Windows) | Ruta base para directorios home de usuarios.              |

### Estructura de CU_GRUPOS

```yaml
CU_GRUPOS:
  - nombre: "dba"
    usuarios:
      - nombre: "pepito"
        permisos: 1  # Administrador
      - nombre: "carlitos"
        permisos: 2  # Usuario estándar
  - nombre: "contenedores"
    usuarios:
      - nombre: "docker_admin"
        permisos: 3  # Operador especializado
```

### Códigos de Permisos (CU_PERMISSION_MAP)

| Código | Linux                          | Windows                        | Descripción                    |
| ------ | ------------------------------ | ------------------------------ | ------------------------------ |
| 1      | wheel                          | Administrators                 | Administrador completo         |
| 2      | users                          | Users                          | Usuario estándar               |
| 3      | wheel                          | Power Users                    | Operador especializado         |
| 4      | users                          | Guests                         | Solo lectura/invitado          |
| 5      | users                          | Backup Operators               | Operador de respaldos          |

---

## Results from execution

| Return Code Group | Return Code | Comments                                             |
| ----------------- | ----------- | -----------------------------------------------------|
| CREATE_USERS      | 1000        | El sistema operativo no es compatible con este rol.  |
| CREATE_USERS      | 1001        | Variables CU_GRUPOS no definidas o vacías.           |
| CREATE_USERS      | 1002        | Código de permiso no válido o no mapeado.            |
| CREATE_USERS      | 1003        | Error al crear grupo del sistema.                    |
| CREATE_USERS      | 2000        | Error al crear usuario del sistema.                  |
| CREATE_USERS      | 2001        | Error al asignar permisos a usuario.                 |
| CREATE_USERS      | 2002        | Error al crear directorio home del usuario.          |
| CREATE_USERS      | 3000        | Usuario o grupo ya existe (informativo).             |
| CREATE_USERS      | 3001        | Validación post-creación falló.                      |

---

## Procedure

Este rol realiza los siguientes pasos:

### Validaciones Iniciales:
- Verificación de compatibilidad del sistema operativo.
- Validación de estructura de variables CU_GRUPOS.
- Comprobación de códigos de permisos válidos.
- Verificación de existencia previa de usuarios/grupos.

### Creación en Linux:
- Creación de grupos del sistema usando `group` module.
- Generación automática de contraseñas aleatorias de 12 caracteres.
- Creación de usuarios con `user` module.
- Asignación a grupos principales y secundarios.
- Configuración de shell y directorio home.
- Aplicación de permisos sudo según mapeo.
- Configuración para forzar cambio de contraseña en primer login.

### Creación en Windows:
- Creación de grupos locales usando `win_group`.
- Generación automática de contraseñas aleatorias de 12 caracteres.
- Creación de usuarios con `win_user`.
- Asignación a grupos locales de Windows.
- Configuración de políticas de contraseña.
- Aplicación de membresías a grupos del sistema.

### Validaciones Post-Creación:
- Verificación de existencia de usuarios y grupos.
- Confirmación de membresías correctas.
- Validación de permisos aplicados.
- Generación de reporte de creación.
- Output de contraseñas generadas automáticamente.

---

## Support

- Equipo de soporte: COE (Center of Excellence) Kyndryl - Interbank - Identity Management
- Canal interno: `#user-creation-support`
- Gestión de issues en el repositorio GitHub de `crear_usuarios`.

---

## Deployment

### Tower

- Proyecto: `proj-identity-management`
- Job Template: `jt-create-users-groups`
- Frecuencia: On demand, durante aprovisionamiento o cambios organizacionales.
- Execution Environment: `ee-rhel-latest`, `ee-windows-latest`.
- Reutilizable en automatizaciones de onboarding, offboarding y restructuración.

---

## Known problems and limitations

- Solo soporta RHEL/CentOS/Rocky/Alma/Oracle Linux 7/8/9 y Windows Server 2012+.
- No maneja contraseñas automáticas (se generan automáticamente y se muestran al final).
- Los permisos sudo en Linux requieren configuración adicional de sudoers.
- No valida políticas de naming conventions específicas de la organización.
- Limitado a grupos locales en Windows (no AD).

---

## Prerequisites

- Privilegios administrativos en hosts destino (sudo/Administrator).
- Python 3.6+ en controlador Ansible.
- PowerShell 5.0+ en hosts Windows.
- Requiere collections: `ansible.windows`, `community.general`, `ansible.posix`.
- Acceso de escritura a directorios home base.

---

## Examples

```yaml
# Ejemplo básico - Crear grupos DBA y Contenedores
- name: Crear usuarios y grupos del proyecto
  hosts: all
  vars:
    CU_GRUPOS:
      - nombre: "dba"
        usuarios:
          - nombre: "pepito"
            permisos: 1  # Administrador
          - nombre: "carlitos"
            permisos: 2  # Usuario estándar
      - nombre: "contenedores"
        usuarios:
          - nombre: "docker_admin"
            permisos: 3  # Operador especializado
          - nombre: "docker_user"
            permisos: 2  # Usuario estándar
  roles:
    - crear_usuarios

# Ejemplo avanzado - Configuración personalizada
- name: Crear usuarios con configuración específica
  hosts: linux_servers
  vars:
    CU_GRUPOS:
      - nombre: "backup_operators"
        usuarios:
          - nombre: "backup_admin"
            permisos: 5  # Operador de backup
    CU_DEFAULT_SHELL: "/bin/zsh"
    CU_HOME_BASE_PATH: "/data/users"
    CU_FAKE_ENVIRONMENT: false
  roles:
    - crear_usuarios

# Ejemplo solo Windows - Grupos de aplicación
- name: Crear usuarios Windows para aplicaciones
  hosts: windows_servers
  vars:
    CU_GRUPOS:
      - nombre: "app_admins"
        usuarios:
          - nombre: "app_service"
            permisos: 3  # Power User
      - nombre: "app_users"
        usuarios:
          - nombre: "readonly_user"
            permisos: 4  # Guest/ReadOnly
    CU_FORCE_PASSWORD_CHANGE: true
  roles:
    - crear_usuarios
```