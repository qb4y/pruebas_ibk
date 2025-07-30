# README

## Synopsis

Rol de Ansible para obtener credenciales desde un servidor HashiCorp Vault mediante API REST. Realiza la consulta del secreto, valida la respuesta, extrae las credenciales necesarias y genera registros auditables sin exponer datos sensibles. Diseñado para ser reutilizado como bloque base por otros roles que requieran acceso a secretos seguros.

---

## Variables

| Variable                          | Default                              | Comments                                                                                                                 |
| --------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| **VC_VAULT_TOKEN** (String)       | No default                           | **Mandatory** Token de autenticación válido para acceder al Vault.                                                       |
| **VC_VAULT_SECRET_PATH** (String) | `"secret/data/nessus"`               | Ruta del secreto en Vault (ejemplo: `secret/data/nessus`) se define en el cada rol que lo invoca, en la seccion de vars. |
| **VC_VAULT_URL** (String)         | `"http://host.docker.internal:8200"` | URL base del Vault (probar en desarrollo con host.docker.internal).                                                      |
| **VC_VALIDATE_CERTS** (Boolean)   | `false`                              | Define si se valida el certificado SSL del Vault.                                                                        |

---

## Results from execution

| Return Code Group | Return Code | Comments                                                                              |
| ----------------- | ----------- | ------------------------------------------------------------------------------------- |
| VAULT_CORE        | 1000        | El Vault no devolvió datos válidos. Revisar la ruta del secreto y el token.           |
| VAULT_CORE        | 1001        | Error HTTP diferente a 200. Revisar conectividad o autenticación.                     |
| VAULT_CORE        | 1002        | Fallo durante la extracción del JSON. Validar formato de respuesta del Vault.         |
| VAULT_CORE        | 2000        | El log de auditoría no pudo ser escrito. Validar permisos en el directorio `var/log`. |

---

## Procedure

Este rol ejecuta los siguientes pasos:

1. **Consulta al Vault** (`get_credentials.yml`):
   - Realiza una petición HTTP GET al endpoint del secreto.
2. **Validación de respuesta** (`validate_response.yml`):
   - Verifica que la respuesta contenga datos válidos y registra el estado general de la consulta.
3. **Parseo de JSON** (`parse_json.yml`):
   - Extrae las credenciales desde el campo `data.data`.
4. **Auditoría sin exponer secretos** (`redact_logs.yml`):
   - Guarda trazabilidad en un archivo de log, registrando fecha, host y resultado.
   - (Opcional) Puede integrarse con flujos de trazabilidad adicionales (`trace_request.yml`, actualmente comentado).

---

## Support

- Equipo de soporte: COE (Center of Excellence) Kyndryl - Interbank - Security Automation
- Canal interno: `#vault-automation-support`
- Issues en el repositorio GitHub correspondiente.

---

## Deployment

### Tower / AWX

- Proyecto: `proj-vault-core`
- Job Template: `jt-vault-core-credentials-fetch`
- Frecuencia: Ejecución on demand, previo a roles consumidores de credenciales.
- Execution Environment: `ee-rhel-latest` (o el que tenga módulos `uri` y `community.general`).
- Reutilizable como bloque base en otros roles (ejemplo: deploy_nessus, deploy_agents, etc.).

---

## Known problems and limitations

- Solo soporta secretos de tipo **KV v2** (`data.data`).
- No soporta autenticación AppRole, UserPass u otros métodos aún.
- Solo retorna los campos específicos definidos (`nessus_activation_key`, `nessus_host`, etc.).
- No implementa rotación automática de credenciales.
- El `validate_certs` está deshabilitado por defecto para entornos de desarrollo.

---

## Prerequisites

- Vault desplegado y accesible por red.
- Token de autenticación generado previamente.
- Secretos almacenados en formato KV versión 2.
- Entornos Linux (AWX o CLI) con `ansible.builtin.uri` disponible.

---

## Examples

```yaml
- name: Obtener credenciales de Vault
  hosts: localhost
  vars:
    VC_VAULT_TOKEN: "{{ lookup('env', 'VAULT_TOKEN') }}"
    VC_VAULT_SECRET_PATH: "secret/data/nessus"
    VC_VAULT_URL: "http://vault.mycompany.local:8200"
    VC_VALIDATE_CERTS: false
  roles:
    - vault_core
```
