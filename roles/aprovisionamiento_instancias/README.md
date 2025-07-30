# README

## Synopsis

Este rol de Ansible automatiza el aprovisionamiento completo de máquinas virtuales (VMs) en VMware vCenter, soportando tanto sistemas operativos Windows como Linux. El rol incluye creación de VM desde templates, configuración de red estática, customización de hostname, configuración de DNS, y verificación de conectividad. Utiliza un sistema de dispatchers modulares para manejar diferentes sistemas operativos y proporciona output JSON con información de acceso.

## Variables

Variable | Default | Comments
----------|-----------------|--------
**vcenter_hostname** (String) | "" | **Mandatory** Hostname o IP del servidor vCenter
**vcenter_username** (String) | "" | **Mandatory** Usuario para autenticación en vCenter
**vcenter_password** (String) | "" | **Mandatory** Contraseña para autenticación en vCenter
**validate_certs** (Boolean) | false | Validar certificados SSL de vCenter
**vm_hostname** (String) | "" | **Mandatory** Nombre de la VM (se convierte automáticamente a formato sin guiones)
**datacenter** (String) | "" | **Mandatory** Datacenter de destino en vCenter
**vm_template** (String) | "" | **Mandatory** Template base para crear la VM
**datastore** (String) | "" | **Mandatory** Datastore para almacenar la VM
**cluster** (String) | "" | Cluster de destino (opcional)
**folder** (String) | "" | Carpeta de destino en el inventario vCenter
**vm_ostype** (String) | "windows" | **Mandatory** Tipo de sistema operativo: "windows" o "linux"
**vm_memory** (Integer) | 4096 | Memoria RAM en MB
**vm_cpu** (Integer) | 2 | Número de vCPUs
**disk_type** (String) | "thin" | Tipo de disco: "thin", "thick", "eagerzeroedthick"
**vm_nics** (Array) | [] | **Mandatory** Configuración de interfaces de red. Ver [README_network.md](README_network.md)
**dns_servers** (Array) | ["8.8.8.8", "8.8.4.4"] | Servidores DNS para la VM
**domain** (String) | "" | Dominio DNS para la VM
**operaciones_habilitadas** (Array) | ["crearVm", "vmGetInfo"] | Operaciones a ejecutar: "crearVm", "vmGetInfo", "vm_delete"
**wait_for_customization** (Boolean) | true | Esperar que VMware complete la customización
**wait_for_ip_address** (Boolean) | true | Esperar que la VM obtenga IP
**state** (String) | "powered-on" | Estado final de la VM: "powered-on", "powered-off", "present"
**annotation** (String) | "VM creada por Ansible - Rol Modularizado" | Anotación descriptiva de la VM
**timezone** (String) | "45" | Timezone para Windows (código numérico)
**timezone_linux** (String) | "America/Lima" | Timezone para Linux (formato estándar)
**hwclock_utc** (Boolean) | true | Configurar reloj hardware en UTC para Linux
**local_admin_user** (String) | "operator" | Usuario administrador local para Windows
**local_admin_password** (String) | "Bugtraq12" | Contraseña administrador local para Windows
**linux_admin_user** (String) | "root" | Usuario root para Linux
**linux_admin_password** (String) | "i20unix06b" | Contraseña root para Linux

## Results from execution

Return Code Group | Return Code | Comments
----------|--------------|---------
SUCCESS | 0 | VM creada exitosamente con IP, hostname y credenciales configuradas
VM_CREATION_FAILED | 1 | Error en la creación de VM (template no encontrado, recursos insuficientes)
CUSTOMIZATION_FAILED | 2 | Error en customización VMware (DNS incorrecto, red desconectada)
NETWORK_CONFIG_FAILED | 3 | Error en configuración de red (IP duplicada, gateway incorrecto)
VERIFICATION_TIMEOUT | 4 | Timeout en verificación de readiness (VM no responde)
VCENTER_CONNECTION_FAILED | 5 | Error de conexión a vCenter (credenciales incorrectas, red)

## Procedure

### Flujo Principal
1. **Validación de Variables**: Verifica que todas las variables obligatorias estén definidas
2. **Conexión vCenter**: Establece conexión con vCenter usando credenciales proporcionadas
3. **Dispatcher por OS**: Redirige a módulos específicos según `vm_ostype`
4. **Creación de VM**: Crea VM desde template con configuración de hardware
5. **Customización**: Aplica hostname, IP estática, DNS y configuración de red
6. **Verificación**: Espera que la VM esté completamente operativa
7. **Output JSON**: Genera resultado con IP, hostname y credenciales

### Dispatcher Modular
- **Windows**: Usa `tasks/windows/` con polling inteligente para manejar reinicios
- **Linux**: Usa `tasks/linux/` con customización VMware directa
- **Común**: Validaciones, conexión vCenter, y post-tasks compartidos

### Configuración de Red
- **IP Estática**: Configura IP, netmask, gateway desde `vm_nics`
- **DNS**: Aplica servidores DNS desde `dns_servers`
- **Hostname**: Convierte `vm_hostname` a formato sin guiones
- **Dominio**: Aplica `domain` para FQDN completo

### Verificación de Readiness
- **Power State**: Verifica que VM esté encendida
- **IP Address**: Confirma que IP asignada coincida con configuración
- **Hostname**: Verifica que hostname esté aplicado correctamente
- **Tools Status**: Confirma que VMware Tools esté funcionando (Windows)

## Support

### Contacto de Desarrollo
- **Support Contact**: Equipo de Automatización Interbank
- **Support URL**: [Repositorio Interno](https://github.kyndryl.net/Continuous-Engineering/aprovisionamiento_instancias)
- **Email**: automation-team@interbank.com.pe

### Governance
- **Project Lead**: Arquitecto de Automatización
- **Goals**: Estandarización de aprovisionamiento de VMs en entorno VMware
- **Roadmap**: Soporte para templates adicionales y configuraciones avanzadas

### Onboarding
- Documentación completa en `/docs`
- Ejemplos de uso en `/examples`
- Guías de troubleshooting en `/troubleshooting`

## Deployment

### Ansible Tower Configuration
- **Project**: `aprovicionamiento_instancias`
- **SCM Branch**: `main` (versión específica: 1.0.0)
- **Job Template**: `VM_Provisioning_Windows_Linux`
- **Job Frequency**: On-demand (ejecución manual)
- **Execution Environment**: `ee-vmware-2.17.12`

### Variables de Tower
```yaml
# Credenciales vCenter (vault)
vcenter_hostname: "{{ vault_vcenter_hostname }}"
vcenter_username: "{{ vault_vcenter_username }}"
vcenter_password: "{{ vault_vcenter_password }}"

# Configuración VM
vm_hostname: "{{ vm_name }}"
vm_ostype: "{{ os_type }}"
vm_template: "{{ template_name }}"
```

### Framework Integration
Este rol es un componente genérico reutilizable que puede integrarse en cualquier colección de Ansible. Ver sección [Examples](#examples) para ejemplos de integración.

## Known problems and limitations

### Limitaciones de Plataforma
- **Soportado**: VMware vCenter 6.7+, ESXi 6.7+
- **No Soportado**: Hyper-V, KVM, AWS, Azure
- **Templates**: Requiere templates pre-configurados con VMware Tools

### Limitaciones de Red
- **IP Duplicada**: No maneja automáticamente conflictos de IP
- **Red Desconectada**: Requiere que la red esté conectada en vCenter
- **DNS**: Requiere servidores DNS accesibles desde la VM

### Limitaciones de Customización
- **Windows**: Puede requerir reinicios adicionales para aplicar cambios
- **Linux**: Algunos templates pueden no soportar customización completa
- **Hostname**: Limitado a caracteres alfanuméricos y guiones

## Prerequisites

### Entorno Requerido
- **Ansible**: 2.17.12 o superior
- **Python**: 3.8+ con módulos VMware
- **vCenter**: Acceso de red y credenciales válidas
- **Templates**: Templates pre-configurados con VMware Tools

### Execution Environment
- **Base Image**: `ee-vmware-2.17.12`
- **Python Dependencies**: `pyvmomi`, `requests`, `cryptography`
- **Ansible Collections**: `community.vmware`, `ansible.builtin`

### Permisos vCenter
- **VM**: Create, Delete, Power On/Off
- **Network**: Assign IP, Configure DNS
- **Template**: Clone, Customize
- **Datastore**: Allocate Space

## Examples

### Ejemplo Básico - Windows
```yaml
---
- name: "Aprovisionar VM Windows"
  hosts: localhost
  gather_facts: true
  connection: local
  
  vars:
    vm_hostname: "test_windows_01"
    vm_ostype: "windows"
    vm_template: "Windows_Server_2019_Template"
    datacenter: "DC01"
    cluster: "Cluster01"
    datastore: "DS01"
    vm_nics:
      - vm_port_group: "VLAN100"
        vm_ip_address: "192.168.1.100"
        vm_netmask: "255.255.255.0"
        vm_gateway: "192.168.1.1"
    dns_servers:
      - "8.8.8.8"
      - "8.8.4.4"
    domain: "company.local"
    
  roles:
    - aprovisionamiento_instancias
```

### Ejemplo Básico - Linux
```yaml
---
- name: "Aprovisionar VM Linux"
  hosts: localhost
  gather_facts: true
  connection: local
  
  vars:
    vm_hostname: "test_linux_01"
    vm_ostype: "linux"
    vm_template: "RHEL8_Template"
    datacenter: "DC01"
    cluster: "Cluster01"
    datastore: "DS01"
    vm_nics:
      - vm_port_group: "VLAN200"
        vm_ip_address: "192.168.2.100"
        vm_netmask: "255.255.255.0"
        vm_gateway: "192.168.2.1"
    dns_servers:
      - "8.8.8.8"
      - "8.8.4.4"
    domain: "company.local"
    timezone_linux: "America/Lima"
    
  roles:
    - aprovisionamiento_instancias
```

### Integración en Colección
```yaml
---
- name: "Workflow de Aprovisionamiento Completo"
  hosts: localhost
  gather_facts: true
  
  tasks:
    - name: "Validar requisitos"
      include_role:
        name: validation_requirements
        
    - name: "Aprovisionar VM"
      include_role:
        name: aprovisionamiento_instancias
      vars:
        vm_hostname: "{{ vm_name }}"
        vm_ostype: "{{ os_type }}"
        vm_template: "{{ template_name }}"
        
    - name: "Configurar aplicaciones"
      include_role:
        name: application_deployment
      when: vm_provisioned.changed
```

## License

[Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)