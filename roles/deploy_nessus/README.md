# README

## Synopsis

Este rol de Ansible despliega el agente Nessus en servidores Linux (RedHat-based) y Windows Server, automatizando los prechecks de compatibilidad, la descarga del instalador desde Tenable, la instalación y la vinculación con un servidor Nessus Manager. Facilita el despliegue masivo de agentes para monitoreo y escaneo de vulnerabilidades.

---

## Variables

| Variable                                 | Default                     | Comments                                                                                        |
| ---------------------------------------- | --------------------------- | ----------------------------------------------------------------------------------------------- |
| **DN_NESSUS_ACTIVATION_KEY** (String)    | No default                  | **Mandatory** Clave de activación del agente Nessus, obtenida desde Vault.                      |
| **DN_NESSUS_MANAGER_HOST** (String)      | No default                  | **Mandatory** Hostname o IP del servidor Nessus Manager.                                        |
| **DN_NESSUS_MANAGER_PORT** (Integer)     | `8834`                      | Puerto de conexión al Nessus Manager.                                                           |
| **DN_NESSUS_AGENT_GROUPS** (String)      | `"default"`                 | Grupos a los que se asociará el agente.                                                         |
| **DN_NESSUS_AGENT_MAP** (Dictionary)     | Definido en `vars/main.yml` | Mapa que relaciona cada OS con su instalador Nessus correspondiente.                            |
| **DN_NESSUS_DIRECT_URLS** (Dictionary)   | Definido en `vars/main.yml` | Mapa de URLs oficiales de Tenable para cada instalador.                                         |
| **DN_NESSUS_FAKE_ENVIRONMENT** (Boolean) | `false`                     | Permite simular la instalación y vinculación sin ejecutar comandos reales.                      |
| **DN_SOY_INSTALADOR** (Boolean)          | `false`                     | Define si el host actual es el encargado de descargar y compartir el instalador (solo Windows). |

---

## Results from execution

| Return Code Group | Return Code | Comments                                                           |
| ----------------- | ----------- | ------------------------------------------------------------------ |
| DEPLOY_NESSUS     | 1000        | El sistema operativo no es compatible con Nessus Agent.            |
| DEPLOY_NESSUS     | 1001        | No se encontró el instalador adecuado para el sistema.             |
| DEPLOY_NESSUS     | 1002        | El puerto 8834 ya está en uso. No se puede desplegar Nessus.       |
| DEPLOY_NESSUS     | 1003        | Ya existe una instalación previa de Nessus.                        |
| DEPLOY_NESSUS     | 2000        | Fallo la descarga del instalador desde Tenable.                    |
| DEPLOY_NESSUS     | 2001        | Error durante la instalación del agente Nessus.                    |
| DEPLOY_NESSUS     | 2002        | Fallo al vincular el agente con el Nessus Manager.                 |
| DEPLOY_NESSUS     | 3000        | El servicio Nessus Agent no está activo después de la instalación. |

---

## Procedure

Este rol realiza los siguientes pasos:

### Prechecks Linux:

- Verificación de OS soportado (RedHat, CentOS, Rocky, AlmaLinux, Oracle).
- Validación de gestor de paquetes (`yum`, `dnf`).
- Detección de instalación previa de Nessus.
- Validación de conectividad con la URL de descarga oficial.
- Chequeo de espacio libre en `/tmp` y disponibilidad del puerto 8834.
- Validación de que SELinux esté en modo `Permissive` o `Disabled`.

### Prechecks Windows:

- Validación del tipo y versión del OS Windows Server.
- Comprobación de si Nessus Agent ya está instalado.
- Validación de la URL de descarga oficial.
- Chequeo de permisos de escritura en `C:\Temp`.

### Instalación y Vinculación:

- Descarga del instalador desde Tenable.
- Instalación del agente Nessus.
- Enlace con el Nessus Manager usando la activation key y el grupo especificado.
- Verificación del estado del servicio Nessus Agent.

---

## Support

- Equipo de soporte: COE (Center of Excellence) Kyndryl - Interbank - Security Automation
- Canal interno: `#nessus-deploy-support`
- Gestión de issues en el repositorio GitHub de `deploy_nessus`.

---

## Deployment

### Tower

- Proyecto: `proj-deploy-nessus`
- Job Template: `jt-deploy-nessus-agent`
- Frecuencia: On demand, cada vez que se aprovisiona un nuevo servidor.
- Execution Environment: `ee-rhel-latest`, `ee-windows-latest`.
- Reutilizable en automatizaciones de seguridad, hardening y monitoreo.

---

## Known problems and limitations

- Solo soporta RHEL/CentOS/Rocky/Alma/Oracle Linux 7/8/9 y Windows Server 2012 en adelante.
- No valida certificados SSL en la conexión a Nessus Manager.
- Requiere acceso a Internet para descargar el instalador desde Tenable.
- El agente solo es compatible con puertos TCP/8834.

---

## Prerequisites

- Acceso al Vault con las credenciales de Nessus (`vault_core` debe ejecutarse previamente).
- Servidores Linux con `dnf` o `yum`.
- Windows Server con PowerShell y permisos de administrador.
- Requiere collections: `ansible.windows`, `community.general`, `ansible.posix`.

---

## Examples

```yaml
- name: Desplegar Nessus Agent en servidores Linux y Windows
  hosts: all
  vars:
    DN_NESSUS_ACTIVATION_KEY: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=secret/nessus:nessus_activation_key') }}"
    DN_NESSUS_MANAGER_HOST: "nessus.manager.local"
    DN_NESSUS_MANAGER_PORT: 8834
    DN_NESSUS_AGENT_GROUPS: "Datacenter-Agents"
  roles:
    - deploy_nessus
```
