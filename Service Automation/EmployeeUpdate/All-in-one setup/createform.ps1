#HelloID variables
$PortalBaseUrl = "https://CUSTOMER.helloid.com"
$apiKey = "API_KEY"
$apiSecret = "API_SECRET"
$delegatedFormAccessGroupNames = @("Users", "HID_administrators")


# Create authorization headers with HelloID API key
$pair = "$apiKey" + ":" + "$apiSecret"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$key = "Basic $base64"
$headers = @{"authorization" = $Key}
# Define specific endpoint URI
if($PortalBaseUrl.EndsWith("/") -eq $false){
    $PortalBaseUrl = $PortalBaseUrl + "/"
}


function Write-ColorOutput($ForegroundColor) {
  $fc = $host.UI.RawUI.ForegroundColor
  $host.UI.RawUI.ForegroundColor = $ForegroundColor
  
  if ($args) {
      Write-Output $args
  }
  else {
      $input | Write-Output
  }

  $host.UI.RawUI.ForegroundColor = $fc
}


$variableName = "HrmRoot"
$variableGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/automation/variables/named/$variableName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
 
    if([string]::IsNullOrEmpty($response.automationVariableGuid)) {
        #Create Variable
        $body = @{
            name = "$variableName";
            value = 'C:\ProgramData\Tools4ever\HelloID\HRM';
            secret = "false";
            ItemType = 0;
        }
 
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/automation/variable")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $variableGuid = $response.automationVariableGuid

        Write-ColorOutput Green "Variable '$variableName' created: $variableGuid"
    } else {
        $variableGuid = $response.automationVariableGuid
        Write-ColorOutput Yellow "Variable '$variableName' already exists: $variableGuid"
    }
} catch {
    Write-ColorOutput Red "Variable '$variableName'"
    $_
}
 
 

$taskName = "HRM-generate-table-departments"
$taskGetDepartmentsGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/automationtasks?search=$taskName&container=1")
    $response = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false) | Where-Object -filter {$_.name -eq $taskName}
 
    if([string]::IsNullOrEmpty($response.automationTaskGuid)) {
        #Create Task
 
        $body = @{
            name = "$taskName";
            useTemplate = "false";
            powerShellScript = @'
            try {
              if($HRMroot.EndsWith("\") -eq $false){
                  $HRMroot = $HRMroot + "\"
              }
              $jsonFile = Get-Item ($HRMroot + "config\departments.json")
              $selectedValue = $formInput.selectedEmployee.department;
              
              $data = Get-Content -Raw -LiteralPath $jsonFile.FullName | ConvertFrom-Json
              $resultCount = @($data).Count
              HID-Write-Status -Message "Result count: $resultCount" -Event Information
              HID-Write-Summary -Message "Result count: $resultCount" -Event Information
              
              
              foreach($item in $data){
                  $selected = if ($item.name -eq $selectedValue) { $True } else { $False };
                  
                  $r = @{
                      name = $item.name;
                      code = $item.code;
                      selected = $selected;
                  }
                  
                  Hid-Add-TaskResult -ResultValue $r
              }
          } catch {
              HID-Write-Status -Message "Error getting HRM Departments. Error: $($_.Exception.Message)" -Event Error
              HID-Write-Summary -Message "Error getting HRM Departments" -Event Failed
              
              Hid-Add-TaskResult -ResultValue []
          }
 
'@;
            automationContainer = "1";
            variables = @()
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskGetDepartmentsGuid = $response.automationTaskGuid

        Write-ColorOutput Green "Powershell task '$taskName' created: $taskGetDepartmentsGuid" 
    } else {
        #Get TaskGUID
        $taskGetDepartmentsGuid = $response.automationTaskGuid
        Write-ColorOutput Yellow "Powershell task '$taskName' already exists: $taskGetDepartmentsGuid"
    }
} catch {
    Write-ColorOutput Red "Powershell task '$taskName'"
    $_
} 
 
 
$dataSourceName = "HRM-generate-table-departments"
$dataSourceGetDepartmentsGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/datasource/named/$dataSourceName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
 
    if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
        #Create DataSource
        $body = @{
            name = "$dataSourceName";
            type = "3";
            model = @(@{key = "code"; type = 0}, @{key = "name"; type = 0}, @{key = "selected"; type = 0});
            automationTaskGUID = "$taskGetDepartmentsGuid";
            input = @(@{description = ""; translateDescription = "False"; inputFieldType = "1"; key = "SelectedEmployee"; type = "0"; options = "0"})
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/datasource")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
         
        $dataSourceGetDepartmentsGuid = $response.dataSourceGUID
        Write-ColorOutput Green "Task data source '$dataSourceName' created: $dataSourceGetDepartmentsGuid"
    } else {
        #Get DatasourceGUID
        $dataSourceGetDepartmentsGuid = $response.dataSourceGUID
        Write-ColorOutput Yellow "Task data source '$dataSourceName' already exists: $dataSourceGetDepartmentsGuid"
    }
} catch {
    Write-ColorOutput Red "Task data source '$dataSourceName'"
    $_
}
 
 
 
$taskName = "HRM-generate-table-jobtitles"
$taskGetJobtitlesGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/automationtasks?search=$taskName&container=1")
    $response = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false) | Where-Object -filter {$_.name -eq $taskName}
 
    if([string]::IsNullOrEmpty($response.automationTaskGuid)) {
        #Create Task
 
        $body = @{
            name = "$taskName";
            useTemplate = "false";
            powerShellScript = @'
            try {
              if($HRMroot.EndsWith("\") -eq $false){
                  $HRMroot = $HRMroot + "\"
              }
              $selectedValue = $formInput.selectedEmployee.title;
              $jsonFile = Get-Item ($HRMroot + "config\jobtitles.json")
              
              $data = Get-Content -Raw -LiteralPath $jsonFile.FullName | ConvertFrom-Json
              $resultCount = @($data).Count
              HID-Write-Status -Message "Result count: $resultCount" -Event Information
              HID-Write-Summary -Message "Result count: $resultCount" -Event Information
              
              foreach($item in $data){
                  $selected = if ($item.name -eq $selectedValue) { $True } else { $False };
                  
                  $r = @{
                      name = $item.name;
                      code = $item.code;
                      selected = $selected;
                  }
                  Hid-Add-TaskResult -ResultValue $r
              }
          } catch {
              HID-Write-Status -Message "Error getting HRM Jobtitles. Error: $($_.Exception.Message)" -Event Error
              HID-Write-Summary -Message "Error getting HRM Jobtitles" -Event Failed
              
              Hid-Add-TaskResult -ResultValue []
          }
'@;
            automationContainer = "1";
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskGetJobtitlesGuid = $response.automationTaskGuid

        Write-ColorOutput Green "Powershell task '$taskName' created: $taskGetJobtitlesGuid"   
    } else {
        #Get TaskGUID
        $taskGetJobtitlesGuid = $response.automationTaskGuid
        Write-ColorOutput Yellow "Powershell task '$taskName' already exists: $taskGetJobtitlesGuid"
    }
} catch {
    Write-ColorOutput Red "Powershell task '$taskName'"
    $_
}
 
 
 
$dataSourceName = "HRM-generate-table-jobtitles"
$dataSourceGetJobtitlesGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/datasource/named/$dataSourceName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
 
    if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
        #Create DataSource
        $body = @{
            name = "$dataSourceName";
            type = "3";
            model = @(@{key = "code"; type = 0}, @{key = "name"; type = 0}, @{key = "selected"; type = 0});
            automationTaskGUID = "$taskGetJobtitlesGuid";
            input = @(@{description = ""; translateDescription = "False"; inputFieldType = "1"; key = "SelectedEmployee"; type = "0"; options = "0"})
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/datasource")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
         
        $dataSourceGetJobtitlesGuid = $response.dataSourceGUID
        Write-ColorOutput Green "Task data source '$dataSourceName' created: $dataSourceGetJobtitlesGuid"
    } else {
        #Get DatasourceGUID
        $dataSourceGetJobtitlesGuid = $response.dataSourceGUID
        Write-ColorOutput Yellow "Task data source '$dataSourceName' already exists: $dataSourceGetJobtitlesGuid"
    }
} catch {
    Write-ColorOutput Red "Task data source '$dataSourceName'"
    $_
}
 
 
 

$taskName = "HRM-generate-table-employees"
$taskGetEmployeesGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/automationtasks?search=$taskName&container=1")
    $response = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false) | Where-Object -filter {$_.name -eq $taskName}
 
    if([string]::IsNullOrEmpty($response.automationTaskGuid)) {
        #Create Task
 
        $body = @{
            name = "$taskName";
            useTemplate = "false";
            powerShellScript = @'
            try {
                if($HRMroot.EndsWith("\") -eq $false){
                    $HRMroot = $HRMroot + "\"
                }
                
                $employees = Get-ChildItem $HRMroot -Filter '*.json' -File
                $resultCount = @($employees).Count
                HID-Write-Status -Message "Result count: $resultCount" -Event Information
                HID-Write-Summary -Message "Result count: $resultCount" -Event Information
                
                $persons = @();
                
                foreach($employee in $employees){
                    $e = Get-Content -Raw -LiteralPath $employee.FullName | ConvertFrom-Json
                    $person = @{
                        personNumber = $e.personNumber;
                        firstname = $e.firstname;
                        prefixLastname = $e.prefixLastname;
                        lastname = $e.lastname;
                        title = $e.title;
                        department = $e.department;
                        startDate = $e.startDate;
                        endDate = $e.endDate;
                    }
                    $persons += $person
                    
                }
                    
                Hid-Add-TaskResult -ResultValue $persons | Sort-Object -Property lastname
            } catch {
                HID-Write-Status -Message "Error getting HRM persons. Error: $($_.Exception.Message)" -Event Error
                HID-Write-Summary -Message "Error getting HRM persons" -Event Failed
                
                Hid-Add-TaskResult -ResultValue []
            }
 
'@;
            automationContainer = "1";
            variables = @()
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskGetEmployeesGuid = $response.automationTaskGuid

        Write-ColorOutput Green "Powershell task '$taskName' created: $taskGetEmployeesGuid" 
    } else {
        #Get TaskGUID
        $taskGetEmployeesGuid = $response.automationTaskGuid
        Write-ColorOutput Yellow "Powershell task '$taskName' already exists: $taskGetEmployeesGuid"
    }
} catch {
    Write-ColorOutput Red "Powershell task '$taskName'"
    $_
} 
 
 
$dataSourceName = "HRM-generate-table-employees"
$dataSourceGetEmployeesGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/datasource/named/$dataSourceName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
 
    if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
        #Create DataSource
        $body = @{
            name = "$dataSourceName";
            type = "3";
            model = @(@{key = "department"; type = 0}, @{key = "endDate"; type = 0}, @{key = "firstname"; type = 0}, @{key = "lastname"; type = 0}, @{key = "personNumber"; type = 0}, @{key = "prefixLastname"; type = 0}, @{key = "startDate"; type = 0}, @{key = "title"; type = 0});
            automationTaskGUID = "$taskGetEmployeesGuid";
            input = @()
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/datasource")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
         
        $dataSourceGetEmployeesGuid = $response.dataSourceGUID
        Write-ColorOutput Green "Task data source '$dataSourceName' created: $dataSourceGetEmployeesGuid"
    } else {
        #Get DatasourceGUID
        $dataSourceGetEmployeesGuid = $response.dataSourceGUID
        Write-ColorOutput Yellow "Task data source '$dataSourceName' already exists: $dataSourceGetEmployeesGuid"
    }
} catch {
    Write-ColorOutput Red "Task data source '$dataSourceName'"
    $_
}


$taskName = "HRM-generate-table-employee-details"
$taskGetEmployeeDetailsGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/automationtasks?search=$taskName&container=1")
    $response = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false) | Where-Object -filter {$_.name -eq $taskName}
 
    if([string]::IsNullOrEmpty($response.automationTaskGuid)) {
        #Create Task
 
        $body = @{
            name = "$taskName";
            useTemplate = "false";
            powerShellScript = @'
            try {
                if($HRMroot.EndsWith("\") -eq $false){
                    $HRMroot = $HRMroot + "\"
                }
                
                $employee = Get-Item ($HRMroot + "$($forminput.selectedEmployee.personNumber).json")
                
                Hid-Write-Summary -Message $employee -Event Information
                
                $e = Get-Content -Raw -LiteralPath $employee.FullName | ConvertFrom-Json
                $hasEndDate = $True
                if($e.endDate -eq $null){
                    $hasEndDate = $False
                }
                
                $person = @{
                    personNumber = $e.personNumber;
                    firstname = $e.firstname;
                    prefixLastname = $e.prefixLastname;
                    lastname = $e.lastname;
                    title = $e.title;
                    department = $e.department;
                    startDate = $e.startDate;
                    endDate = $e.endDate;
                    hasEndDate = $hasEndDate;
                }
                
                Hid-Add-TaskResult -ResultValue $person
            
            } catch {
                HID-Write-Status -Message "Error getting HRM person details. Error: $($_.Exception.Message)" -Event Error
                HID-Write-Summary -Message "Error getting HRM person details" -Event Failed
                
                Hid-Add-TaskResult -ResultValue []
            }
 
'@;
            automationContainer = "1";
            variables = @()
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskGetEmployeeDetailsGuid = $response.automationTaskGuid

        Write-ColorOutput Green "Powershell task '$taskName' created: $taskGetEmployeeDetailsGuid" 
    } else {
        #Get TaskGUID
        $taskGetEmployeeDetailsGuid = $response.automationTaskGuid
        Write-ColorOutput Yellow "Powershell task '$taskName' already exists: $taskGetEmployeeDetailsGuid"
    }
} catch {
    Write-ColorOutput Red "Powershell task '$taskName'"
    $_
} 
 
 
$dataSourceName = "HRM-generate-table-employee-details"
$dataSourceGetEmployeeDetailsGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/datasource/named/$dataSourceName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
 
    if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
        #Create DataSource
        $body = @{
            name = "$dataSourceName";
            type = "3";
            model = @(@{key = "department"; type = 0}, @{key = "endDate"; type = 0}, @{key = "firstname"; type = 0}, @{key = "lastname"; type = 0}, @{key = "personNumber"; type = 0}, @{key = "prefixLastname"; type = 0}, @{key = "startDate"; type = 0}, @{key = "title"; type = 0}, @{key = "hasEndDate"; type = 0});
            automationTaskGUID = "$taskGetEmployeeDetailsGuid";
            input = @(@{description = ""; translateDescription = "False"; inputFieldType = "1"; key = "selectedEmployee"; type = "0"; options = "1"})
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/datasource")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
         
        $dataSourceGetEmployeeDetailsGuid = $response.dataSourceGUID
        Write-ColorOutput Green "Task data source '$dataSourceName' created: $dataSourceGetEmployeeDetailsGuid"
    } else {
        #Get DatasourceGUID
        $dataSourceGetEmployeeDetailsGuid = $response.dataSourceGUID
        Write-ColorOutput Yellow "Task data source '$dataSourceName' already exists: $dataSourceGetEmployeeDetailsGuid"
    }
} catch {
    Write-ColorOutput Red "Task data source '$dataSourceName'"
    $_
}

 
 
$formName = "HRM - Update employee"
$formGuid = ""
 
try
{
    try {
        $uri = ($PortalBaseUrl +"api/v1/forms/$formName")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
    } catch {
        $response = $null
    }
 
    if(([string]::IsNullOrEmpty($response.dynamicFormGUID)) -or ($response.isUpdated -eq $true))
    {
        #Create Dynamic form
        $form = @"
        [{
            "label": "Select Employee",
            "fields": [{
                "key": "employee",
                "templateOptions": {
                    "label": "Employees",
                    "required": true,
                    "grid": {
                        "columns": [{
                            "headerName": "Firstname",
                            "field": "firstname"
                          },
                          {
                            "headerName": "Lastname",
                            "field": "lastname"
                          },
                          {
                            "headerName": "Prefix Lastname",
                            "field": "prefixLastname"
                          },
                          {
                            "headerName": "Person Number",
                            "field": "personNumber"
                          },
                          {
                            "headerName": "Department",
                            "field": "department"
                          },
                          {
                            "headerName": "Title",
                            "field": "title"
                          },
                          {
                            "headerName": "Start Date",
                            "field": "startDate"
                          },
                          {
                            "headerName": "End Date",
                            "field": "endDate"
                          }],
                        "height": 300,
                        "rowSelection": "single"
                    },
                    "dataSourceConfig": {
                        "dataSourceGuid": "$dataSourceGetEmployeesGuid",
                        "input": {
                            "propertyInputs": []
                        }
                    },
                    "useFilter": true
                },
                "type": "grid",
                "summaryVisibility": "Hide element",
                "requiresTemplateOptions": true
            }]
        }, {
            "label": "Update Employee",
            "fields": [{
                "key": "firstname",
                "templateOptions": {
                  "label": "Givenname",
                  "useDependOn": true,
                  "dependOn": "employee",
                  "dependOnProperty": "firstname",
                  "placeholder": "John",
                  "required": true
                },
                "type": "input",
                "summaryVisibility": "Show",
                "requiresTemplateOptions": true
              },
              {
                "key": "prefixLastname",
                "templateOptions": {
                  "label": "prefix Lastname",
                  "useDependOn": true,
                  "dependOn": "employee",
                  "dependOnProperty": "prefixLastname"
                },
                "type": "input",
                "summaryVisibility": "Show",
                "requiresTemplateOptions": true
              },
              {
                "key": "lastname",
                "templateOptions": {
                  "label": "Lastname",
                  "useDependOn": true,
                  "dependOn": "employee",
                  "dependOnProperty": "lastname",
                  "placeholder": "Do",
                  "required": true
                },
                "type": "input",
                "summaryVisibility": "Show",
                "requiresTemplateOptions": true
              }, {
                "templateOptions": {},
                "type": "markdown",
                "summaryVisibility": "Show",
                "body": "---",
                "requiresTemplateOptions": false
            }, {
                "key": "startDate",
                "templateOptions": {
                    "label": "Start date",
                    "dateOnly": true,
                    "useDataSource": true,
                    "displayField": "startDate",
                    "dataSourceConfig": {
                        "dataSourceGuid": "$dataSourceGetEmployeeDetailsGuid",
                        "input": {
                            "propertyInputs": [{
                                "propertyName": "selectedEmployee",
                                "otherFieldValue": {
                                    "otherFieldKey": "employee"
                                }
                            }]
                        }
                    },
                    "useFilter": false
                },
                "type": "datetime",
                "summaryVisibility": "Show",
                "requiresTemplateOptions": true
            }, {
                "key": "hasEndDate",
                "templateOptions": {
                    "label": "Has end date",
                    "useSwitch": true,
                    "checkboxLabel": "Person has an end date",
                    "useDataSource": true,
                    "displayField": "hasEndDate",
                    "dataSourceConfig": {
                        "dataSourceGuid": "$dataSourceGetEmployeeDetailsGuid",
                        "input": {
                            "propertyInputs": [{
                                "propertyName": "selectedEmployee",
                                "otherFieldValue": {
                                    "otherFieldKey": "employee"
                                }
                            }]
                        }
                    },
                    "useFilter": false
                },
                "type": "boolean",
                "defaultValue": false,
                "summaryVisibility": "Show",
                "requiresTemplateOptions": true
            }, {
                "key": "endDate",
                "templateOptions": {
                    "label": "End date",
                    "dateOnly": true,
                    "useDataSource": true,
                    "displayField": "endDate",
                    "dataSourceConfig": {
                        "dataSourceGuid": "$dataSourceGetEmployeeDetailsGuid",
                        "input": {
                            "propertyInputs": [{
                                "propertyName": "selectedEmployee",
                                "otherFieldValue": {
                                    "otherFieldKey": "employee"
                                }
                            }]
                        }
                    },
                    "useFilter": false
                },
                "hideExpression": "!model[\\"hasEndDate\\"]",
                "type": "datetime",
                "summaryVisibility": "Show",
                "requiresTemplateOptions": true
            }, {
                "key": "department",
                "templateOptions": {
                    "label": "Department",
                    "required": false,
                    "useObjects": false,
                    "useDataSource": true,
                    "useFilter": false,
                    "options": ["Option 1", "Option 2", "Option 3"],
                    "valueField": "code",
                    "textField": "name",
                    "dataSourceConfig": {
                        "dataSourceGuid": "$dataSourceGetDepartmentsGuid",
                        "input": {
                            "propertyInputs": [{
                                "propertyName": "SelectedEmployee",
                                "otherFieldValue": {
                                    "otherFieldKey": "employee"
                                }
                            }]
                        }
                    },
                    "useDefault": true,
                    "defaultSelectorProperty": "selected"
                },
                "type": "dropdown",
                "summaryVisibility": "Show",
                "textOrLabel": "text",
                "requiresTemplateOptions": true
            }, {
                "key": "title",
                "templateOptions": {
                    "label": "Job title",
                    "required": false,
                    "useObjects": false,
                    "useDataSource": true,
                    "useFilter": false,
                    "options": ["Option 1", "Option 2", "Option 3"],
                    "valueField": "code",
                    "textField": "name",
                    "dataSourceConfig": {
                        "dataSourceGuid": "$dataSourceGetJobtitlesGuid",
                        "input": {
                            "propertyInputs": [{
                                "propertyName": "SelectedEmployee",
                                "otherFieldValue": {
                                    "otherFieldKey": "employee"
                                }
                            }]
                        }
                    },
                    "useDefault": true,
                    "defaultSelectorProperty": "selected"
                },
                "type": "dropdown",
                "summaryVisibility": "Show",
                "textOrLabel": "text",
                "requiresTemplateOptions": true
            }]
        }]
"@
 
        $body = @{
            Name = "$formName";
            FormSchema = $form
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/forms")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
 
        $formGuid = $response.dynamicFormGUID
        Write-ColorOutput Green "Dynamic form '$formName' created: $formGuid"
    } else {
        $formGuid = $response.dynamicFormGUID
        Write-ColorOutput Yellow "Dynamic form '$formName' already exists: $formGuid"
    }
} catch {
    Write-ColorOutput Red "Dynamic form '$formName'"
    $_
} 
 
 
$delegatedFormAccessGroupGuids = @()

foreach($group in $delegatedFormAccessGroupNames) {
    try {
        $uri = ($PortalBaseUrl +"api/v1/groups/$group")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
        $delegatedFormAccessGroupGuid = $response.groupGuid
        $delegatedFormAccessGroupGuids += $delegatedFormAccessGroupGuid
        
        Write-ColorOutput Green "HelloID (access)group '$group' successfully found: $delegatedFormAccessGroupGuid"
    } catch {
        Write-ColorOutput Red "HelloID (access)group '$group'"
        $_
    }
}
 
 
 
$delegatedFormName = "HRM - Update employee"
$delegatedFormGuid = ""
$delegatedFormCreated = $false
 
try {
    try {
        $uri = ($PortalBaseUrl +"api/v1/delegatedforms/$delegatedFormName")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
    } catch {
        $response = $null
    }
 
    if([string]::IsNullOrEmpty($response.delegatedFormGUID)) {
        #Create DelegatedForm
        $body = @{
            name = "$delegatedFormName";
            dynamicFormGUID = "$formGuid";
            isEnabled = "True";
            accessGroups = $delegatedFormAccessGroupGuids;
            useFaIcon = "True";
            faIcon = "fa fa-pencil-square-o";
        }   
 
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/delegatedforms")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
 
        $delegatedFormGuid = $response.delegatedFormGUID
        Write-ColorOutput Green "Delegated form '$delegatedFormName' created: $delegatedFormGuid"
        $delegatedFormCreated = $true
    } else {
        #Get delegatedFormGUID
        $delegatedFormGuid = $response.delegatedFormGUID
        Write-ColorOutput Yellow "Delegated form '$delegatedFormName' already exists: $delegatedFormGuid"
    }
} catch {
    Write-ColorOutput Red "Delegated form '$delegatedFormName'"
    $_
}
 
 
 
$taskActionName = "hrm-update-employee"
$taskActionGuid = ""
 
try {
    if($delegatedFormCreated -eq $true) {  
        #Create Task
 
        $body = @{
            name = "$taskActionName";
            useTemplate = "false";
            powerShellScript = @'
            try {
                $checkExists = $True
                if($HRMroot.EndsWith("\") -eq $false){
                    $HRMroot = $HRMroot + "\"
                }
                            
                if ($hasEndDate){
                    $ed = ([Datetime]$endDate).ToString("o")
                }else{
                    $ed = $null
                }
                
                if([string]::IsNullOrEmpty($personNumber) -eq $false) { 
                            
                    $person = @{
                        personNumber = $personNumber;
                        firstname = $firstname;
                        prefixLastname = $prefixLastname;
                        lastname = $lastname;
                        title = $title;
                        titleCode = $titleCode;
                        department = $department;
                        departmentCode = $departmentCode;
                        startDate = ([Datetime]$startDate).ToString("o");
                        endDate = $ed;
                    }
                            
                    HID-Write-status -message ($person | ConvertTo-Json) -Event information
                            
                    Write-Output $person | ConvertTo-Json | Out-File ($HRMroot + "$personNumber.json")
                        
                    HID-Write-Status -Message "HRM person [$firstname $lastname ($personNumber)] updated successfully" -Event Success
                    HID-Write-Summary -Message "HRM person [$firstname $lastname ($personNumber)] updated successfully" -Event Success
                } else {
            
                }                
            } catch {
                HID-Write-Status -Message "Error updating HRM person [$firstname $lastname ($personNumber)]. Error: $($_.Exception.Message)" -Event Error
                HID-Write-Summary -Message "Error updating HRM person [$firstname $lastname ($personNumber)]" -Event Failed
            }
'@;
            automationContainer = "8";
            objectGuid = "$delegatedFormGuid";
            variables = @(@{name = "department"; value = "{{form.department.name}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "departmentCode"; value = "{{form.department.code}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "endDate"; value = "{{form.endDate}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "firstname"; value = "{{form.firstname}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "hasEndDate"; value = "{{form.hasEndDate}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "lastname"; value = "{{form.lastname}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "personNumber"; value = "{{form.employee.personNumber}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "prefixLastname"; value = "{{form.prefixLastname}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "startDate"; value = "{{form.startDate}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "title"; value = "{{form.title.name}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "titleCode"; value = "{{form.title.code}}"; typeConstraint = "string"; secret = "False"});
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskActionGuid = $response.automationTaskGuid

        Write-ColorOutput Green "Delegated form task '$taskActionName' created: $taskActionGuid" 
    } else {
        Write-ColorOutput Yellow "Delegated form '$delegatedFormName' already exists. Nothing to do with the Delegated Form task..."
    }
} catch {
    Write-ColorOutput Red "Delegated form task '$taskActionName'"
    $_
}