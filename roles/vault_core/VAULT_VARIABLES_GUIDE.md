# Vault Core Role - Guía de Variables

## Problema Resuelto

El error `vault_token is defined` ocurría porque había inconsistencia en los nombres de las variables entre diferentes archivos.

## Variables Corregidas

### Para uso con `vault_config.yml` (local):
```yaml
# vault_config.yml
vault_token: "root"
vault_api_url: "http://10.11.252.58:30485"
```

### Para uso desde AWX (Extra Variables):
```yaml
# En AWX Extra Variables
vault_token: "your-vault-token"
vault_url: "https://vault.example.com:8200"
```

## Playbooks Disponibles

### 1. `test-crowdstrike-debug.yml`
- Usa `vault_config.yml` local
- Para desarrollo y pruebas locales

### 2. `test-crowdstrike-awx.yml`
- Usa variables de AWX Extra Variables
- Para ejecución desde AWX

## Uso desde AWX

1. **Extra Variables requeridas:**
```yaml
vault_token: "your-vault-token"
vault_url: "https://vault.example.com:8200"
CS_ENV: "uat"  # opcional, por defecto "uat"
```

2. **Seleccionar playbook:** `playbooks/test-crowdstrike-awx.yml`

## Uso desde línea de comandos

```bash
# Con vault_config.yml
ansible-playbook -i inventory/inventory.yml playbooks/test-crowdstrike-debug.yml

# Con variables en línea de comandos
ansible-playbook -i inventory/inventory.yml playbooks/test-crowdstrike-awx.yml \
  -e vault_token="your-token" \
  -e vault_url="https://vault.example.com:8200" \
  -e CS_ENV="uat"
```

## Validaciones Agregadas

- ✅ Validación de variables requeridas
- ✅ Debug de conexión a Vault (sin mostrar token completo)
- ✅ Validación de respuesta de Vault
- ✅ Timeout en peticiones HTTP
- ✅ Mensajes de error más descriptivos

## Estructura de Variables

```
vault_config.yml (local) → vault_token, vault_api_url
                    ↓
test-crowdstrike-debug.yml → mapea vault_api_url a vault_url
                    ↓
crowdstrike role → usa vault_token, vault_url
                    ↓
vault_core role → usa VC_VAULT_TOKEN, VC_VAULT_URL
```
