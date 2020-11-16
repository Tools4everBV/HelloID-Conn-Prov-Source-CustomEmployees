# HelloID-Conn-SA-Full-HRM-EmployeeManagement
HelloID Service Automation Delegated Form for managing custom HRM employees as additional source for HelloID provisioning


<!-- Description -->
## Description
This repository contains a set of two HelloID Service Automation Delegated Form provides an Active Directory report containing the user accounts that have failed logins. The following options are available:
 1. Overview of AD user accounts that match this report
 2. Export data to a local CSV file on the HelloID Agent server (optional)
 
<!-- TABLE OF CONTENTS -->
## Table of Contents
* [Description](#description)
* [All-in-one PowerShell setup script](#all-in-one-powershell-setup-script)
  * [Getting started](#getting-started)
* [Post-setup configuration](#post-setup-configuration)


## All-in-one PowerShell setup script
The PowerShell script "createform.ps1" contains a complete PowerShell script using the HelloID API to create the complete Form including user defined variables, tasks and data sources.

### Getting started
 1. Download the script "createform.ps1"
 2. Open the script in your favorite PowerShell console / editor
 3. Open your HelloID portal
 4. Get or create your own [API Key and Secret](https://docs.helloid.com/hc/en-us/articles/360002008873-API-Keys-Overview)
 5. Update the following connection details in the all-in-one PowerShell script
 <table>
  <tr><td><strong>Line</strong></td><td><strong>Variable</strong></td><td><strong>Example</strong></td><td><strong>Description</strong></td></tr>
  <tr><td>2</td><td>$PortalBaseUrl</td><td>https://customer01.helloid.com</td><td>Your own HelloID portal URL</td></tr>
  <tr><td>3</td><td>$apiKey</td><td></td><td>Your own HelloID API Key</td></tr>
  <tr><td>4</td><td>$apiSecret</td><td></td><td>Your own HelloID API Secret</td></tr>
  <tr><td>5</td><td>$delegatedFormAccessGroupNames</td><td>@("Users", "HID_administrators")</td><td>Array of local HelloID group name giving access to this new Delegated Form</td></tr>
</table>
 6. Run the all-in-one PowerShell script
 
 _Please note that this script asumes none of the required resources do exists within HelloID. The script does not contain versioning or source control_

## Post-setup configuration
After the all-in-one PowerShell script has run and created all the required resources. The following items need to be configured according to your own environment
 1. Update the following [user defined variables](https://docs.helloid.com/hc/en-us/articles/360014169933-How-to-Create-and-Manage-User-Defined-Variables)
<table>
  <tr><td><strong>Variable name</strong></td><td><strong>Example value</strong></td><td><strong>Description</strong></td></tr>
  <tr><td>HIDreportFolder</td><td>C:\HIDreports\</td><td>Local folder on HelloID Agent server for exporting CSV reports</td></tr>
  <tr><td>ADusersReportOU</td><td>[{ "OU": "OU=Employees,OU=Users,OU=Enyoi,DC=enyoi-media,DC=local"},{ "OU": "OU=Disabled,OU=Users,OU=Enyoi,DC=enyoi-media,DC=local"},{"OU": "OU=External,OU=Users,OU=Enyoi,DC=enyoi-media,DC=local"}]</td><td>Array of Active Directory OUs for scoping shown AD user accounts in this report</td></tr>
</table>
