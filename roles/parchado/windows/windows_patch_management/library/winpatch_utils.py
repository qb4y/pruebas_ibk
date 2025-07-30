#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Windows Patch Management Utility Functions
Following Kyndryl Ansible Role Development Standards
"""

import json
import re
from ansible.module_utils.basic import AnsibleModule


def validate_patching_mode(mode):
    """Validate patching mode parameter"""
    valid_modes = ['wsus', 'sccm']
    if mode not in valid_modes:
        return False, f"Invalid patching mode '{mode}'. Must be one of: {', '.join(valid_modes)}"
    return True, ""


def validate_update_categories(categories):
    """Validate update categories"""
    valid_categories = ['CriticalUpdates', 'SecurityUpdates', 'UpdateRollups', 'Updates', 'DefinitionUpdates']
    if not isinstance(categories, list):
        return False, "Update categories must be a list"
    
    for category in categories:
        if category not in valid_categories:
            return False, f"Invalid update category '{category}'. Must be one of: {', '.join(valid_categories)}"
    
    return True, ""


def validate_update_code(update_code):
    """Validate update code format"""
    if update_code == 'ALL':
        return True, ""
    
    if not update_code:
        return True, ""
    
    # Check format: KB123456 or KB123456,KB789012
    pattern = r'^(KB\d+(,KB\d+)*)?$'
    if not re.match(pattern, update_code):
        return False, f"Invalid update code format '{update_code}'. Must be 'ALL' or comma-separated KB codes"
    
    return True, ""


def validate_environment(environment):
    """Validate environment parameter"""
    valid_environments = ['PROD', 'TEST', 'DEV', 'STAGE']
    if environment not in valid_environments:
        return False, f"Invalid environment '{environment}'. Must be one of: {', '.join(valid_environments)}"
    return True, ""


def validate_domain_name(domain_name):
    """Validate domain name format"""
    pattern = r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if not re.match(pattern, domain_name):
        return False, f"Invalid domain name format '{domain_name}'"
    return True, ""


def validate_logs_path(logs_path):
    """Validate logs path format"""
    pattern = r'^[A-Za-z]:\\\.*$'
    if not re.match(pattern, logs_path):
        return False, f"Invalid logs path format '{logs_path}'. Must be Windows path format (e.g., C:\\temp\\logs)"
    return True, ""


def get_return_code(operation, success=True, error_type=None):
    """Get standardized return code"""
    if success:
        if operation == 'install':
            return 2000
        elif operation == 'download':
            return 2002
        else:
            return 2001
    else:
        error_codes = {
            'validation': 3000,
            'wsus_missing_vars': 3001,
            'sccm_missing_vars': 3002,
            'wsus_connectivity': 3003,
            'sccm_connectivity': 3004,
            'disk_space': 3005,
            'service_failure': 3006,
            'installation_failure': 3007,
            'reboot_failure': 3008,
            'ou_registration': 3009,
            'wsus_config': 3010,
            'rescue_failure': 3011,
            'service_restoration': 3012
        }
        return error_codes.get(error_type, 3000)


def format_return_message(code, details=""):
    """Format standardized return message"""
    messages = {
        2000: "Updates installed successfully",
        2001: "No updates available",
        2002: "Updates downloaded only",
        3000: "Invalid patching mode specified",
        3001: "Missing required variables for WSUS mode",
        3002: "Missing required variables for SCCM mode",
        3003: "WSUS server connectivity failure",
        3004: "SCCM connectivity failure",
        3005: "Insufficient disk space for updates",
        3006: "Windows Update service failure",
        3007: "Update installation failed",
        3008: "System reboot failed",
        3009: "AD OU registration failed",
        3010: "WSUS client configuration failed",
        3011: "Rescue procedures failed",
        3012: "Service restoration failed"
    }
    
    base_message = messages.get(code, "Unknown error")
    if details:
        return f"{base_message}: {details}"
    return base_message


def main():
    """Main function for testing"""
    module = AnsibleModule(
        argument_spec=dict(
            operation=dict(type='str', required=True),
            mode=dict(type='str', required=True),
            environment=dict(type='str', required=True),
            domain_name=dict(type='str', required=True),
            categories=dict(type='list', required=False),
            update_code=dict(type='str', required=False),
            logs_path=dict(type='str', required=False)
        )
    )
    
    operation = module.params['operation']
    mode = module.params['mode']
    environment = module.params['environment']
    domain_name = module.params['domain_name']
    categories = module.params.get('categories', [])
    update_code = module.params.get('update_code', 'ALL')
    logs_path = module.params.get('logs_path', 'C:/temp/patch_logs')
    
    # Validate all parameters
    valid, msg = validate_patching_mode(mode)
    if not valid:
        module.fail_json(msg=msg)
    
    valid, msg = validate_environment(environment)
    if not valid:
        module.fail_json(msg=msg)
    
    valid, msg = validate_domain_name(domain_name)
    if not valid:
        module.fail_json(msg=msg)
    
    if categories:
        valid, msg = validate_update_categories(categories)
        if not valid:
            module.fail_json(msg=msg)
    
    valid, msg = validate_update_code(update_code)
    if not valid:
        module.fail_json(msg=msg)
    
    valid, msg = validate_logs_path(logs_path)
    if not valid:
        module.fail_json(msg=msg)
    
    # Return success
    return_code = get_return_code(operation, success=True)
    return_message = format_return_message(return_code)
    
    module.exit_json(
        changed=False,
        return_code=return_code,
        return_message=return_message,
        validated=True
    )


if __name__ == '__main__':
    main() 