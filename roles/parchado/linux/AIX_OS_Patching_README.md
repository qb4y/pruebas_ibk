# Synopsis

This collection contains playbooks for patching related activities on AIX systems.

## Technical / Business Analysis

**What is the value to Kyndryl Teams?** It helps the Kyndryl in managing the accounts to keep their servers up to date with the latest patch levels.

**What is the value to the client?** It assists the accounts in maintaining their server patch levels up to date, eliminating the risk of human error.

**What kind of resource utilization does this playbook have?** Low. This playbook has very minimal resource requirements.

**How complex is it to implement this playbook?** Low. The instructions can be copied/pasted to start using it right away without further configuration.

**Does this playbook make any changes to the server?** Yes. This playbook installs/updates required patches on the servers.

**How often should I run this?** Monthly. The frequency may vary for some accounts based of their patch cycle.

## Process Diagram

![image](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_patching_unix/blob/master/images/patching_process.png)

## Variables

Variable | Default| Comments
----------|-----------------|--------
__patching_scenario__ (String) | alt_disk | **Mandatory** The patching scenario to patch the server. Available options are alt_disk, rootvg and nim_server. If a particular software/subsystem needs to be patched then the value should be software_patching. Use the value as restore if looking to restore the OS to previous maintenance level using old rootvg. Use the value as apply_efixes or remove_efixes if just the efixes need to be applied or uninstalled.
__patching_filesets_location__ (String) | '' | **Mandatory** Patching filesets location.
__efix_filesets_location__ (String) | '' | Efixes package location.
__remove_efix_list__ (String) | '' | Comma separated list of efixes which need to be uninstalled.
__free_disk__ (String) | '' | Free disk name to install alt_disk. Playbook will fetch the free disk if the value is null.
__use_old_rootvg__ (Boolean) | true | Switch to decide whether disk associated with old rootvg should be used to clone rootvg.
__fail_if_no_old_rootvg__ (Boolean) | false | Switch to decide if playbook should abort if no old rootvg is found for alt_disk and rootvg scenarios.
__free_disk_same_adaptor__ (Boolean) | false | Switch to decide whether playbook should fetch the free disk under the same parent adaptor as rootvg.
__rootvg_backup__ (String) | alt_disk | Rootvg backup method. Available options are alt_disk and snapvx
__root_vg_name__ (String) | rootvg | Set this variable if root volume group name is different than rootvg.
__reboot_required__ (Boolean) | false | **Mandatory** Switch to decide whether server reboot is required after patching. It's strongly recommended to set this to true in case of alt_disk patching method as updates will be applied in the alt_disk instead of the rootvg disk and will not take effect until the server is rebooted. Playbook will not restart any services as part of reboot process, this has to be taken care manually.
__run_shutdown_script__ (Boolean) | false | Switch to decide whether /etc/rc.shutdown script to stop all applications/DBs need to be run before patching.
__nfs_path__ (String) | '' |  Remote NFS volume to be mounted.
__nfs_mountpoint__ (String) | '' | Path to the mount point.
__unmount_nfs_after_patching__ (Boolean) | true | Switch to decide whether remote NFS volume needs to be unmounted after patching.
__mount_with_soft_option__ (Boolean) | false | Switch to decide whether remote NFS volume needs to be mounted using soft option.
__restart_ssh__ (Boolean) | false | Switch to decide whether SSH service needs to be restarted after software patching. patching_scenario variable needs to be set to software_patching.
__remove_locking_efixes__ (Boolean) | true | Switch to decide whether locking efixes need to be uninstalled before patching.
__fail_on_error__ (Boolean) | true | Switch to decide whether execution should fail in case of unsuccessful patching.
__send_email__ (Boolean) | false | Switch to decide whether email notification is required.
__recipients__ (String Array) | [] | List of email recipients.
__smtp_host_ip__ (String) | '' | SMTP host IP address.
__smtp_port__ (Integer) | 25 | SMTP port.
__teams_notification__ (Boolean) | false | Switch to decide whether MS Teams notification is required.
__channel_webhook_url__ (String) | '' | MS Teams channel webhook url to receive notifications.

## Results from execution

Return Code Group | Return Code | Comments
------------------|-------------|---------
component_playbook | 5021 | One of the commands to validate disk space has failed. Further investigation is required by the developer.
component_playbook | 5022 | One of the commands to validate filesystem space has failed. Further investigation is required by the developer.
component_playbook | 5023 | Disabling altinst_rootvg has failed. Further investigation is required by the developer.
component_playbook | 5024 | Uninstall locking efix command has failed. Further investigation is required by the developer.
component_playbook | 5025 | OS update through alt_disk or rootvg method has failed. Further investigation is required by the developer.
component_playbook | 5026 | bootlist addition command has failed. Further investigation is required by the developer.
component_playbook | 5027 | Backing up of sendmail.cf and inetd.conf files has failed. Further investigation is required by the developer.
component_playbook | 5028 | One of the commands to validate installed filesets consistency has failed. Further investigation is required by the developer.
component_playbook | 5029 | Pre patching script execution has failed. Further investigation is required by the developer.
component_playbook | 5030 | Mounting remote NFS volume has failed. Further investigation is required by the developer.
component_playbook | 5031 | Restoring sendmail.cf and inetd.conf files failed. Further investigation is required by the developer.
component_playbook | 5032 | Server reboot has failed. Further investigation is required by the developer.
component_playbook | 5033 | Post patch script execution has failed. Further investigation is required by the developer.
component_playbook | 5034 | Unmounting remote NFS volume has failed. Further investigation is required by the developer.
component_playbook | 5035 | Alt disk cleanup has failed. Further investigation is required by the developer.
component_playbook | 5036 | OS update preview command for NIM server method has failed. Further investigation is required by the developer.
component_playbook | 5037 | OS update through NIM server method has failed. Further investigation is required by the developer.
component_playbook | 5038 | rootvg cloning has failed. Further investigation is required by the developer.
component_playbook | 5039 | Software update has failed. Further investigation is required by the developer.
component_playbook | 5040 | Applying efixes has failed. Further investigation is required by the developer.
component_playbook | 5041 | SSH service restart has failed. Further investigation is required by the developer.
misconfiguration | 1001 | Gather facts failed for host. Fix the server connection and try again.
misconfiguration | 6002 | One or more pre check validations have failed. Please refer the failed checks and fix them before running this playbook again.
misconfiguration | 6003 | Unsupported value for patching_scenario variable. Please provide the correct value. Refer the readme for more details.
misconfiguration | 6004 | OS update pre-installation verification for NIM server method has failed.
misconfiguration | 6005 | No free disk found to clone the rootvg.
misconfiguration | 6006 | No old rootvg found to restore the OS to previous maintenance level.
misconfiguration | 6007 | Rootvg cloning has been aborted either because correct EMC version is not installed or there are multiple rootvg configured on the server.
misconfiguration | 6008 | No old rootvg found which can be used to create a fresh rootvg clone after the cleanup. Make sure there is an old rootvg available or use different rootvg backup method or set fail_if_no_old_rootvg to false.
misconfiguration | 6009 | No root volume group with the provided name found. Please provide a valid value.
misconfiguration | 6010 | An execution for the same playbook is already running on the host. Please wait for the current execution to complete.
misconfiguration | 6011 | Issues while sending email notification. Please make sure correct SMTP host and port values are passed.
misconfiguration | 6012 | Issues while sending MS Teams notification. Please make sure correct webhook url is passed.

## Procedure

### List of playbooks

playbook name | playbook file | Comments
--------------|---------------|-------------
aix-patching | aix_patching.yml | this will trigger patching steps for AIX servers.

### List of roles

#### aix_patching

This playbook performs below activities:

1. Cleans up existing alt disk, if required.
2. Validates disk space requirements.
3. Validates filesystem space requirements.
4. Executes pre patching scripts.
5. Uninstalls locking efix.
6. Mounts the remote NFS volume to fetch the filesets.
7. Updates the OS.
8. Reboots the server. (Optional)
9. Executes post patching scripts.
10. Unmounts the remote NFS volume.

## Deployment

### Patching code versioning principles

* master branch of repository will always contain the latest release of patching
* separate release branches (i.e. branches "3.0.0", "3.1.2") contain specific release version with latest bugfixes
* each bugfix release will be also tagged separately (i.e. releases "3.0.1", "3.0.2") to provide highest code versioning granularity for specific release version up to specific bugfix.

### Tower Project

This patching project requires one ansible project to be created in ansible tower. All patching Job Templates are entirely managed by this tower project.

When creating/managing patching project, required to specify the branch name of the GitHub repository to get playbooks from.

To create a project click on "Projects" on the left hand navigation menu in Tower, and then click on the green plus icon on the right.

Having created patching project, need to grant access permissions to the appropriate team(s) in Tower Organization. Contact Tower Account Administrator for assistance with this.

### Create Tower Project for patching

#### Create a project using the following attributes

__NOTE:__ '???' means 3 letter account code

* Name: ???_project_patching_aix
* Description: AIX patching Project for ???
* Organization: ???
* SCM type: Git
* SCM URL: <https://github.kyndryl.net/Continuous-Engineering/ansible_collection_patching_unix.git>
* SCM Branch: master
* SCM Credential: <git credential>

#### Sample project

![image](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_patching_unix/blob/master/images/patching_project_sample.png)

All other values can be left as default. Click Save to create project. Tower will create the project, and attempt to populate it from GitHub. Wait for the job to complete and verify that it completed successfully, indicated by a solid green circle. If it ends with a red error circle click on it to review the logs, correct any errors in the project or credentials and try again.

### Tower Job Templates for AIX patching

#### Create a new Job Template with the following attributes

__NOTE:__ '???' means 3 letter account code

* Name: ???_template_patching_aix
* Description: AIX patching
* Job Type: Run
* Inventory: *Leave blank and select Prompt on Launch"
* Project: ???_project_patching_aix
* Playbook: aix_patching.yml
* Credentials: add the Tower and Jumphost credentials, and select "Prompt on Launch" to be able to add specific Machine creds later

#### Sample Template creation

![image](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_patching_unix/blob/master/images/patching_template_sample.png)

ONLY if need to override default values, add any input variables from the lists below into "Extra Variables" attribute of Job Template, and select "Prompt on launch" if you want to be able to change these at launch time. If you have already added any of these variables in the Tower Inventory (as recommended!) then you do not need to repeat them with same values here unless you need to override their values defined in Tower Inventory.

## Known problems and limitations

### Environments Supported

* AIX

### Environments Tested

The patch installation playbook has been tested only in the following environments:

* AIX 7.1
* Tested only on stand alone servers, cluster servers not supported

## Prerequisites

* Standard Ansible prerequisites (Python on target machine).
* Ansible Execution Environment 2.13 or above.
* Ansible Tower user(s) with the role of at least a System Auditor to be used in the credentials of the type of Ansible Tower to be passed to the template. There can be one user for the whole tower or one user for each organization or several organizations in the tower.

## License

[Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
