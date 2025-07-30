# Synopsis

This collection contains playbooks for patching related activities on linux systems.
The patch installation playbooks are designed to install missing patches like update, security, bugfix, rcp and specific package(s) on linux endpoint server(s). Currently RedHat, Suse, CentOS, Oracle Linux, Rocky Linux and Ubuntu are supported.

Please refer below sub README to get details on AIX patching:

* [aix_os_patching](AIX_OS_Patching_README.md)

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

### Important variables

Variable | Default| Comments
----------|-----------------|--------
__patch_source__ (String) | satellite | **Mandatory** Patching source. Allowed values: 'internet', 'satellite', 'reposerver', 'susemanager'. This is just to validate the patch source and not to configure it.
__patch_type__ (String) | 'update_all' | **Mandatory** This value should be one of the following depending on the patching running for (update_all, security_all, rcp_all, bugfix_all and specific package(s)). Additionally patching based on severity can be performed on RHEL OS by passing one of the following values: severity_high, severity_medium, severity_low, severity_all. Use download_only if patches need to be downloaded to a folder and install_from_folder if patches need to be installed from a folder for RHEL OS.
__package_download_location__ (String) | '' | The location to download the packages if download_only value is selected for patch_type variable or location from where patches need to be installed if install_from_folder value is selected. This is applicable only to RHEL OS. If run_pre_patch_steps is set to true then this is the location from where patches will be applied as a pre patching step.
__yum_exclude_patch_list__ (String) | '' | Comma separated list of patches to be excluded. Only works for RHEL and CentOS. An asterisk (*) can be used as a wildcard character to specify a set of patches. patch_type variable needs to be set to update_all or rcp_all for this functionality.
__backup_to_jumphost__ (Boolean) | false | **Mandatory** Save pre patching configuration to jumphost?
__jumphost_path__ (String) | '/tmp' | Path on the jumphost server where pre patching configuration would be saved.
__boot_space_threshold_mb__ (Integer) | 256 | Available space threshold for /boot file system in MB.
__yum_clean_all__ (Boolean) | false | Switch to decide whether yum clean all command needs to be run after successful patching on RHEL OS.
__reboot_required__ (Boolean) | false | **Mandatory** Switch to decide whether server reboot is required after patching. Playbook will not restart any services as part of reboot process, this has to be taken care manually.
__force_reboot__ (Boolean) | false | Switch to decide whether server still needs to be rebooted even if server is already up-to-date. reboot_required variable needs to be set to true to enable this feature.
__send_email__ (Boolean) | false | Switch to decide whether email notification is required.
__recipients__ (String Array) | [] | List of email recipients.
__smtp_host_ip__ (String) | '' | SMTP host IP address.
__smtp_port__ (Integer) | 25 | SMTP port.
__attach_config_data__ (Boolean) | false | Switch to decide whether pre and post patching config files need to be attached to the consolidated email.
__teams_notification__ (Boolean) | false | Switch to decide whether MS Teams notification is required.
__channel_webhook_url__ (String) | '' | MS Teams channel webhook url to receive notifications.
__sfs_upload__ (Boolean) | false | Switch to decide whether patching results need to be uploaded to SFS.
__service_restart_list__ (String) | '' | Comma separated list of OS services which need to be stopped before patching and started after successful patching.
__app_service_stop_script__ (String) | '' | Absolute path to the script to stop application services before patching. Do not pass any commands other than those to stop application services, playbook has no control over the content of the script and it would be run as it is passed.
__app_service_start_script__ (String) | '' | Absolute path to the script to start application services after patching. Do not pass any commands other than those to start application services, playbook has no control over the content of the script and it would be run as it is passed.

### Other variables

Variable | Default| Comments
----------|-----------------|--------
__skip_cluster_check__ (Boolean) | true | Switch to decide whether cluster check needs to be skipped so that nodes part of OS cluster can be patched as well.
__system_load_check__ (Boolean) | false | Switch to decide whether memory and cpu usage on the end server need to be checked before patching.
__filesystems_to_check__ (String Array) | [] | Filesystems (other than /var and /boot) need to be checked for required free space.
__other_fs_space_threshold_perc__ (Integer) | 25 | Available space threshold percentage for filesystems other than /var and /boot
__disable_repo__ (String) | '' | Comma separated list of yum repositories to be disabled for the patching operation on RHEL OS.
__enable_repo__ (String) | '' | Comma separated list of yum repositories to be enabled for the patching operation on RHEL OS.
__disable_gpg_check__ (Boolean) | false | Switch to decide whether to disable the GPG checking of signatures of packages being installed.
__extra_args_suse__ (String) | '' | Add additional options to zypper command using this variable.
__kernel_patching_suse__ (Boolean) | false | Switch to decide whether kernel patching needs to be performed on Suse OS.
__run_patch_scan__ (Boolean) | false | Switch to decide whether patch scanning needs to be run before and after patching.
__configure_patch_source__ (Boolean) | false | Switch to decide whether patch source needs to be configured before performing patching.
__patch_source_url__ (String) | '' | Url to configure the patch source.
__satellite_repo_activation_key__ (String) | '' | Activation key to configure satellite patch source.
__satellite_org_name__ (String) | '' | Org name to configure satellite patch source.
__reposerver_repo_name__ (String) | '' | Repository name to configure reposerver patch source.
__disable_satellite_repo__ (Boolean) | false | Switch to decide whether existing satellite repo needs to disabled while configuring reposerver patch source.
__katello_package_to_be_removed__ (String) | '' | Katello package which needs to be removed as part of disabling satellite repo. disable_satellite_repo needs to be set to true.
__ubuntu_repo_file_validation__ (Boolean) | false | Switch to decide whether repo file stability check is required for Ubuntu OS.
__ubuntu_repo_backup_path__ (String) | '/root/repo-backup' | Path on the Ubuntu end server where repo file backup would be saved
__ubuntu_repo_files__ (String) | '' | The list of comma separated repo files under /etc/apt/sources.list.d/ on Ubuntu end server which need to be kept. Rest of the files would be deleted after taking the backup.
__use_custom_repo__ (Boolean) | false | Switch to decide whether custom repositories need to be used for RHEL patching.
__rhel6_baseurl__ (String) | '' | RHEL 6 custom repo baseurl. Set use_custom_repo to true.
__rhel7_baseurl__ (String) | '' | RHEL 7 custom repo baseurl. Set use_custom_repo to true.
__rhel8_baseurl__ (String) | '' | RHEL 8 custom repo baseurl. Set use_custom_repo to true.
__async_value__ (Integer) | 0 | Set it to a non zero value to perform patching in async mode.
__poll_value__ (Integer) | 15 | This will be enabled if async_value variable is set to a non zero value.
__run_pre_patch_steps__ (Boolean) | false | Switch to decide whether a list patches need to be applied as a pre patching step.
__pre_patch_list__ (String) | '' | The comma separated list of patches which need to be applied as a pre patching step. This is only applicable to RHEL 8 version.
__fail_on_error__ (Boolean) | true | Switch to decide whether execution should fail in case of unsuccessful patching.
__change_number__ (String) | '' | Change ticket number.

## Results from execution

Return Code Group | Return Code | Comments
------------------|-------------|---------
component_playbook | 5000 | The command to verify patching source has failed. Further investigation is required by the developer.
component_playbook | 5001 | The command to get the patch size has failed. Further investigation is required by the developer.
component_playbook | 5002 | The command to verify filesystem space usage has failed. Further investigation is required by the developer.
component_playbook | 5003 | The command to get the current CPU usage has failed. Further investigation is required by the developer.
component_playbook | 5004 | The command to get the current memory usage has failed. Further investigation is required by the developer.
component_playbook | 5005 | Fetching system diagnostic data for comparison has failed. Further investigation is required by the developer.
component_playbook | 5006 | One of the commands while running additional steps for ubuntu has failed. Further investigation is required by the developer.
component_playbook | 5007 | Fetching pre patching configuration has failed. Further investigation is required by the developer.
component_playbook | 5008 | Saving configuration data to jumphost has failed. Further investigation is required by the developer.
component_playbook | 5009 | update_all or rcp_all patching has failed. Further investigation is required by the developer.
component_playbook | 5010 | bugfix_all patching has failed. Further investigation is required by the developer.
component_playbook | 5011 | security_all patching has failed. Further investigation is required by the developer.
component_playbook | 5012 | Redhat/CentOS specific patching RHBA/RHSA has failed. Further investigation is required by the developer.
component_playbook | 5013 | Redhat/CentOS specific patching CVE has failed. Further investigation is required by the developer.
component_playbook | 5014 | Suse specific patching has failed. Further investigation is required by the developer.
component_playbook | 5015 | Ubuntu apt-get patching command has failed. Further investigation is required by the developer.
component_playbook | 5016 | Ubuntu upgrade all apt packages step has failed. Further investigation is required by the developer.
component_playbook | 5017 | One of the post patching steps for Ubuntu OS has failed. Further investigation is required by the developer.
component_playbook | 5018 | Server reboot has failed. Further investigation is required by the developer.
component_playbook | 5019 | Fetching post patching configuration has failed. Further investigation is required by the developer.
component_playbook | 5020 | Issues while running yum clean all command. Further investigation is required by the developer.
component_playbook | 5030 | Mounting remote NFS volume has failed. Further investigation is required by the developer.
component_playbook | 5034 | Unmounting remote NFS volume has failed. Further investigation is required by the developer.
component_playbook | 5053 | RHEL OS Patching based on severity has failed. Further investigation is required by the developer.
component_playbook | 5056 | Issues while uploading results to SFS. Further investigation is required by the developer.
component_playbook | 5057 | Downloading packages to a folder has failed. Further investigation is required by the developer.
component_playbook | 5058 | Applying patches as pre patching step has failed. Further investigation is required by the developer.
component_playbook | 5059 | Stopping OS services has failed. Further investigation is required by the developer.
component_playbook | 5061 | Starting OS services has failed. Further investigation is required by the developer.
component_playbook | 5062 | Configuring satellite patch source has failed. Further investigation is required by the developer.
component_playbook | 5063 | Configuring reposerver patch source has failed. Further investigation is required by the developer.
misconfiguration | 1001 | Gather facts failed for host. Fix the server connection and try again.
misconfiguration | 6000 | Unsupported value for patch_source variable. Please provide the correct value. Refer the readme for more details.
misconfiguration | 6001 | Unsupported value for patch_type variable. Please provide the correct value. Refer the readme for more details.
misconfiguration | 6002 | One or more pre check validations have failed. Please refer the failed checks and fix them before running this playbook again.
misconfiguration | 6010 | An execution for the same playbook is already running on the host. Please wait for the current execution to complete.
misconfiguration | 6011 | Issues while sending email notification. Please make sure correct SMTP host and port values are passed.
misconfiguration | 6012 | Issues while sending MS Teams notification. Please make sure correct webhook url is passed.
misconfiguration | 6013 | Stopping application services has failed. Make sure correct script details are passed and content of the script is accurate.
component_playbook | 6014 | Starting application services has failed. Make sure correct script details are passed and content of the script is accurate.

## Procedure

### List of playbooks

playbook name | playbook file | Comments
--------------|---------------|-------------
pre-patching-validation | pre_patching_validation.yml | Pre validation for all supported linux OS flavours.
linux-patching | linux_patching.yml | This will trigger pre validation, patching and post validation for all supported linux OS flavours. Individual OS flavour playbooks are not being maintained and will be removed from the collection soon.
post-patching-validation | post_patching_validation.yml | Post patching steps for all supported linux OS flavours.

### List of roles

#### pre patching validation

This playbook performs below activities:

1. Verifies whether all the pre patching prerequisites are met. This includes following checks: Patch source validation, Filesystem Space validation, CPU validation, Memory validation, Cluster validation
2. Captures system diagnostic data in a local file.
3. Save pre patching configuration of the server on the jumphost.
4. Stops OS and application services, if enabled.

#### patching playbooks

This playbook needs to be run from Ansible Tower as it needs to get organization from the Ansible Tower.
When configuring template from a project using this playbook, you need to have the following credentials:
    Credentials of type Machine to access the inventory

Extra vars in template must have __patch_type__ variable with any of the following update_all, security_all, rcp_all, bugfix_all and specific package(s).
__ex__: patch_type: 'bugfix_all'

#### post patching validation

This playbook performs below activities:

1. Reboots the server (Optional)
2. Captures system diagnostic data in a local file and compares it against the pre patching data.
3. Starts OS and application services, if enabled.

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

* Name: ???_project_patching_unix
* Description: linux patching Project for ???
* Organization: ???
* SCM type: Git
* SCM URL: <https://github.kyndryl.net/Continuous-Engineering/ansible_collection_patching_unix.git>
* SCM Branch: master
* SCM Credential: <git credential>

#### Sample project

![image](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_patching_unix/blob/master/images/patching_project_sample.png)

All other values can be left as default. Click Save to create project. Tower will create the project, and attempt to populate it from GitHub. Wait for the job to complete and verify that it completed successfully, indicated by a solid green circle. If it ends with a red error circle click on it to review the logs, correct any errors in the project or credentials and try again.

### Tower Job Templates

Each linux flavour of patching playbook needs to be run by separate Tower Job Template. The playbooks in patching are designed to perform on the linux OS flavour basis (RHEL/CentOS/Ubuntu/Suse).

### Create Job Template for RHEL patching

#### Create a new Job Template with the following attributes

__NOTE:__ '???' means 3 letter account code

* Name: ???_template_patching_rhel  #For redhat
* Description: redhat patching
* Job Type: Run
* Inventory: *Leave blank and select Prompt on Launch"
* Project: ???_project_patching_unix
* Playbook: redhat_pre_patch_post.yml
* Credentials: add the Tower and Jumphost credentials, and select "Prompt on Launch" to be able to add specific Machine creds later

#### Extra Vars

* patch_type, patch_source and reboot_required are mandatory variables to define values in extra vars section of job template.
* any one of values should be set for __patch_type__
    * patch_type: 'update_all'
    * patch_type: 'security_all'
    * patch_type: 'rcp_all'
    * patch_type: 'bugfix_all' (only for RHEL and CentOS)
    * patch_type: '< specific package name(s) with comma separated >' (only for RHEL, CentOS and Suse)

* any one of values should be set for __patch_source__
    * patch_source: 'satellite'
    * patch_source: 'internet'
    * patch_source: 'reposerver'
    * patch_source: 'susemanager'

* any one of values should be set for __reboot_required__
    * reboot_required: false
    * reboot_required: true

* any one of values should be set for __backup_to_jumphost__
    * backup_to_jumphost: true
    * backup_to_jumphost: false

#### Sample Template creation

![image](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_patching_unix/blob/master/images/patching_template_sample.png)

#### Sample Extra vars section

![image](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_patching_unix/blob/master/images/patching_extra_vars_sample.png)
ONLY if need to override default values, add any input variables from the lists below into "Extra Variables" attribute of Job Template, and select "Prompt on launch" if you want to be able to change these at launch time. If you have already added any of these variables in the Tower Inventory (as recommended!) then you do not need to repeat them with same values here unless you need to override their values defined in Tower Inventory.

## Known problems and limitations

The RHEL servers having VDC (Virtual Data Centre) subscription should have virt-who package installed for syncing their virtual uuid with either Red Hat Satellite or RHSM (Red Hat Subscription Manager). Package virt-who enables RHEL VM to sync their updated virtual uuid whenever that VM moves to different hypervisor in virtualized environment like VMware or RHEV. Please refer Red Hat official Solution Article for more detail: <https://access.redhat.com/solutions/3328401>

### Environments Supported

* RHEL 6 and above versions
* Suse 12 and above versions
* Ubuntu
* CentOS
* Oracle Linux
* Rocky Linux

### Environments Tested

The patch installation and pre/post playbooks has been tested only in the following environments:

* RedHat - RHEL 6,7,8 & 9
* CentOS - 7 & 8
* Ubuntu - 18
* Suse - 12 & 15
* Rocky Linux - 9
* Oracle Linux - 8
* Tested only on stand alone servers, cluster servers not supported

## Support

* For Patch Installation, please raise any requests or issues at: [COMMON REPOSITORY](https://github.kyndryl.net/Continuous-Engineering/CACM_Common_Repository/issues)

## Prerequisites

* Standard Ansible prerequisites (Python on target machine).
* Ansible Execution Environment 2.13 or above.
* Ansible Tower user(s) with the role of at least a System Auditor to be used in the credentials of the type of Ansible Tower to be passed to the template. There can be one user for the whole tower or one user for each organization or several organizations in the tower.

## Examples

Please refer files under Playbooks directory to perform patch installation.

## License

[Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
