#HelloID variables
$script:PortalBaseUrl = "https://CUSTOMER.helloid.com"
$apiKey = "API_KEY"
$apiSecret = "API_SECRET"
$delegatedFormAccessGroupNames = @("Users", "HID_administrators")
$delegatedFormCategories = @("Active Directory", "Reporting")

# Create authorization headers with HelloID API key
$pair = "$apiKey" + ":" + "$apiSecret"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$key = "Basic $base64"
$script:headers = @{"authorization" = $Key}
# Define specific endpoint URI
$script:PortalBaseUrl = $script:PortalBaseUrl.trim("/") + "/"
 
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }

    $host.UI.RawUI.ForegroundColor = $fc
}

function Invoke-HelloIDGlobalVariable {
    param(
        [parameter(Mandatory)][String]$Name,
        [parameter(Mandatory)][String][AllowEmptyString()]$Value,
        [parameter(Mandatory)][String]$Secret
    )

    try {
        $uri = ($script:PortalBaseUrl + "api/v1/automation/variables/named/$Name")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
    
        if ([string]::IsNullOrEmpty($response.automationVariableGuid)) {
            #Create Variable
            $body = @{
                name     = $Name;
                value    = $Value;
                secret   = $Secret;
                ItemType = 0;
            }    
            $body = $body | ConvertTo-Json
    
            $uri = ($script:PortalBaseUrl + "api/v1/automation/variable")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
            $variableGuid = $response.automationVariableGuid

            Write-ColorOutput Green "Variable '$Name' created: $variableGuid"
        } else {
            $variableGuid = $response.automationVariableGuid
            Write-ColorOutput Yellow "Variable '$Name' already exists: $variableGuid"
        }
    } catch {
        Write-ColorOutput Red "Variable '$Name', message: $_"
    }
}

function Invoke-HelloIDAutomationTask {
    param(
        [parameter(Mandatory)][String]$TaskName,
        [parameter(Mandatory)][String]$UseTemplate,
        [parameter(Mandatory)][String]$AutomationContainer,
        [parameter(Mandatory)][String][AllowEmptyString()]$Variables,
        [parameter(Mandatory)][String]$PowershellScript,
        [parameter()][String][AllowEmptyString()]$ObjectGuid,
        [parameter()][String][AllowEmptyString()]$ForceCreateTask,
        [parameter(Mandatory)][Ref]$returnObject
    )
    
    try {
        $uri = ($script:PortalBaseUrl +"api/v1/automationtasks?search=$TaskName&container=$AutomationContainer")
        $responseRaw = (Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false) 
        $response = $responseRaw | Where-Object -filter {$_.name -eq $TaskName}
    
        if([string]::IsNullOrEmpty($response.automationTaskGuid) -or $ForceCreateTask -eq $true) {
            #Create Task

            $body = @{
                name                = $TaskName;
                useTemplate         = $UseTemplate;
                powerShellScript    = $PowershellScript;
                automationContainer = $AutomationContainer;
                objectGuid          = $ObjectGuid;
                variables           = [Object[]]($Variables | ConvertFrom-Json);
            }
            $body = $body | ConvertTo-Json
    
            $uri = ($script:PortalBaseUrl +"api/v1/automationtasks/powershell")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
            $taskGuid = $response.automationTaskGuid

            Write-ColorOutput Green "Powershell task '$TaskName' created: $taskGuid"  
        } else {
            #Get TaskGUID
            $taskGuid = $response.automationTaskGuid
            Write-ColorOutput Yellow "Powershell task '$TaskName' already exists: $taskGuid"
        }
    } catch {
        Write-ColorOutput Red "Powershell task '$TaskName', message: $_"
    }

    $returnObject.Value = $taskGuid
}

function Invoke-HelloIDDatasource {
    param(
        [parameter(Mandatory)][String]$DatasourceName,
        [parameter(Mandatory)][String]$DatasourceType,
        [parameter(Mandatory)][String][AllowEmptyString()]$DatasourceModel,
        [parameter()][String][AllowEmptyString()]$DatasourceStaticValue,
        [parameter()][String][AllowEmptyString()]$DatasourcePsScript,        
        [parameter()][String][AllowEmptyString()]$DatasourceInput,
        [parameter()][String][AllowEmptyString()]$AutomationTaskGuid,
        [parameter(Mandatory)][Ref]$returnObject
    )

    $datasourceTypeName = switch($DatasourceType) { 
        "1" { "Native data source"; break} 
        "2" { "Static data source"; break} 
        "3" { "Task data source"; break} 
        "4" { "Powershell data source"; break}
    }
    
    try {
        $uri = ($script:PortalBaseUrl +"api/v1/datasource/named/$DatasourceName")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
      
        if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
            #Create DataSource
            $body = @{
                name               = $DatasourceName;
                type               = $DatasourceType;
                model              = [Object[]]($DatasourceModel | ConvertFrom-Json);
                automationTaskGUID = $AutomationTaskGuid;
                value              = [Object[]]($DatasourceStaticValue | ConvertFrom-Json);
                script             = $DatasourcePsScript;
                input              = [Object[]]($DatasourceInput | ConvertFrom-Json);
            }
            $body = $body | ConvertTo-Json
      
            $uri = ($script:PortalBaseUrl +"api/v1/datasource")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
              
            $datasourceGuid = $response.dataSourceGUID
            Write-ColorOutput Green "$datasourceTypeName '$DatasourceName' created: $datasourceGuid"
        } else {
            #Get DatasourceGUID
            $datasourceGuid = $response.dataSourceGUID
            Write-ColorOutput Yellow "$datasourceTypeName '$DatasourceName' already exists: $datasourceGuid"
        }
    } catch {
      Write-ColorOutput Red "$datasourceTypeName '$DatasourceName', message: $_"
    }

    $returnObject.Value = $datasourceGuid
}

function Invoke-HelloIDDynamicForm {
    param(
        [parameter(Mandatory)][String]$FormName,
        [parameter(Mandatory)][String]$FormSchema,
        [parameter(Mandatory)][Ref]$returnObject
    )
    
    $FormName = $FormName + $(if ($script:duplicateForm -eq $true) { $script:duplicateFormSuffix })

    try {
        try {
            $uri = ($script:PortalBaseUrl +"api/v1/forms/$FormName")
            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
        } catch {
            $response = $null
        }
    
        if(([string]::IsNullOrEmpty($response.dynamicFormGUID)) -or ($response.isUpdated -eq $true)) {
            #Create Dynamic form
            $body = @{
                Name       = $FormName;
                FormSchema = [Object[]]($FormSchema | ConvertFrom-Json)
            }
            $body = ConvertTo-Json -InputObject $body -Depth 100
    
            $uri = ($script:PortalBaseUrl +"api/v1/forms")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
    
            $formGuid = $response.dynamicFormGUID
            Write-Information "Dynamic form '$formName' created$(if ($script:debugLogging -eq $true) { ": " + $formGuid })"
        } else {
            $formGuid = $response.dynamicFormGUID
            Write-Warning "Dynamic form '$FormName' already exists$(if ($script:debugLogging -eq $true) { ": " + $formGuid })"
        }
    } catch {
        Write-Error "Dynamic form '$FormName', message: $_"
    }

    $returnObject.Value = $formGuid
}

function Invoke-HelloIDDelegatedForm {
    param(
        [parameter(Mandatory)][String]$DelegatedFormName,
        [parameter(Mandatory)][String]$DynamicFormGuid,
        [parameter()][String][AllowEmptyString()]$AccessGroups,
        [parameter()][String][AllowEmptyString()]$Categories,
        [parameter(Mandatory)][String]$UseFaIcon,
        [parameter()][String][AllowEmptyString()]$FaIcon,
        [parameter(Mandatory)][Ref]$returnObject
    )
    $delegatedFormCreated = $false
    
    try {
        try {
            $uri = ($script:PortalBaseUrl +"api/v1/delegatedforms/$DelegatedFormName")
            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
        } catch {
            $response = $null
        }
    
        if([string]::IsNullOrEmpty($response.delegatedFormGUID)) {
            #Create DelegatedForm
            $body = @{
                name            = $DelegatedFormName;
                dynamicFormGUID = $DynamicFormGuid;
                isEnabled       = "True";
                accessGroups    = [Object[]]($AccessGroups | ConvertFrom-Json);
                useFaIcon       = $UseFaIcon;
                faIcon          = $FaIcon;
            }    
            $body = $body | ConvertTo-Json
    
            $uri = ($script:PortalBaseUrl +"api/v1/delegatedforms")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
    
            $delegatedFormGuid = $response.delegatedFormGUID
            Write-ColorOutput Green "Delegated form '$DelegatedFormName' created: $delegatedFormGuid"
            $delegatedFormCreated = $true

            $bodyCategories = $Categories
            $uri = ($script:PortalBaseUrl +"api/v1/delegatedforms/$delegatedFormGuid/categories")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $bodyCategories
            Write-ColorOutput Green "Delegated form '$DelegatedFormName' updated with categories"
        } else {
            #Get delegatedFormGUID
            $delegatedFormGuid = $response.delegatedFormGUID
            Write-ColorOutput Yellow "Delegated form '$DelegatedFormName' already exists: $delegatedFormGuid"
        }
    } catch {
        Write-ColorOutput Red "Delegated form '$DelegatedFormName', message: $_"
    }

    $returnObject.value.guid = $delegatedFormGuid
    $returnObject.value.created = $delegatedFormCreated
}
<# Begin: HelloID Global Variables #>
$tmpValue = @'
C:\ProgramData\Tools4ever\HelloID\HRM
'@ 
Invoke-HelloIDGlobalVariable -Name "HRMroot" -Value $tmpValue -Secret "False" 
<# End: HelloID Global Variables #>


<# Begin: HelloID Data sources #>
<# Begin: DataSource "HRM-generate-table-jobtitles" #>
$tmpPsScript = @'
try {
    if($HRMroot.EndsWith("\") -eq $false){
        $HRMroot = $HRMroot + "\"
    }
    $selectedValue = $formInput.selectedEmployee.title;
    $jsonFile = Get-Item ($HRMroot + "config\jobtitles.json")
    
    $data = Get-Content -Raw -LiteralPath $jsonFile.FullName | ConvertFrom-Json
    $resultCount = @($data).Count
    Write-information "Result count: $resultCount"
    
    foreach($item in $data){
        $selected = if ($item.name -eq $selectedValue) { $True } else { $False };
        
        $r = @{
            name = $item.name;
            code = $item.code;
            selected = $selected;
        }
        Write-output $r
    }
} catch {
    Write-error "Error getting HRM Jobtitles. Error: $($_.Exception.Message)"
    return
}
'@ 
$tmpModel = @'
[{"key":"name","type":0},{"key":"code","type":0},{"key":"selected","type":0}]
'@ 
$tmpInput = @'
{"description":"","translateDescription":false,"inputFieldType":1,"key":"SelectedEmployee","type":0,"options":0}
'@ 
$dataSourceGuid_1 = [PSCustomObject]@{} 
Invoke-HelloIDDatasource -DatasourceName "HRM-generate-table-jobtitles" -DatasourceType "4" -DatasourceInput $tmpInput -DatasourcePsScript $tmpPsScript -DatasourceModel $tmpModel -returnObject ([Ref]$dataSourceGuid_1) 
<# End: DataSource "HRM-generate-table-jobtitles" #>

<# Begin: DataSource "HRM-generate-table-departments" #>
$tmpPsScript = @'
try {
    if($HRMroot.EndsWith("\") -eq $false){
        $HRMroot = $HRMroot + "\"
    }
    $jsonFile = Get-Item ($HRMroot + "config\departments.json")
    $selectedValue = $datasource.selectedEmployee.department;

    $data = Get-Content -Raw -LiteralPath $jsonFile.FullName | ConvertFrom-Json
    $resultCount = @($data).Count
    Write-information "Result count: $resultCount"    
    
    foreach($item in $data){
        $selected = if ($item.name -eq $selectedValue) { $True } else { $False };
        
        $r = @{
            name = $item.name;
            code = $item.code;
            selected = $selected;
        }
        
        Write-output $r
    }
} catch {
    Write-error "Error getting HRM Departments. Error: $($_.Exception.Message)"
    return
}

'@ 
$tmpModel = @'
[{"key":"selected","type":0},{"key":"code","type":0},{"key":"name","type":0}]
'@ 
$tmpInput = @'
{"description":"","translateDescription":false,"inputFieldType":1,"key":"SelectedEmployee","type":0,"options":0}
'@ 
$dataSourceGuid_0 = [PSCustomObject]@{} 
Invoke-HelloIDDatasource -DatasourceName "HRM-generate-table-departments" -DatasourceType "4" -DatasourceInput $tmpInput -DatasourcePsScript $tmpPsScript -DatasourceModel $tmpModel -returnObject ([Ref]$dataSourceGuid_0) 
<# End: DataSource "HRM-generate-table-departments" #>
<# End: HelloID Data sources #>

<# Begin: Dynamic Form "HRM - Create Employee" #>
$tmpSchema = @"
[{"key":"firstname","templateOptions":{"label":"Givenname","required":true,"placeholder":"John"},"type":"input","summaryVisibility":"Show","requiresTemplateOptions":true},{"key":"prefixLastname","templateOptions":{"label":"prefix Lastname"},"type":"input","summaryVisibility":"Show","requiresTemplateOptions":true},{"key":"lastname","templateOptions":{"label":"Lastname","required":true,"placeholder":"Do"},"type":"input","summaryVisibility":"Show","requiresTemplateOptions":true},{"templateOptions":{},"type":"markdown","summaryVisibility":"Show","body":"---","requiresTemplateOptions":false},{"key":"startDate","templateOptions":{"label":"Start date","dateOnly":true},"type":"datetime","summaryVisibility":"Show","requiresTemplateOptions":true},{"key":"hasEndDate","templateOptions":{"label":"Has end date","useSwitch":true,"checkboxLabel":"Person has an end date"},"type":"boolean","defaultValue":false,"summaryVisibility":"Show","requiresTemplateOptions":true},{"key":"endDate","templateOptions":{"label":"End date","dateOnly":true},"hideExpression":"!model[\"hasEndDate\"]","type":"datetime","summaryVisibility":"Show","requiresTemplateOptions":true},{"key":"department","templateOptions":{"label":"Department","required":true,"useObjects":false,"useDataSource":true,"useFilter":true,"options":["Option 1","Option 2","Option 3"],"valueField":"code","textField":"name","dataSourceConfig":{"dataSourceGuid":"$dataSourceGuid_0","input":{"propertyInputs":[{"propertyName":"SelectedEmployee","staticValue":{}}]}}},"type":"dropdown","summaryVisibility":"Show","textOrLabel":"text","requiresTemplateOptions":true},{"key":"title","templateOptions":{"label":"Job title","required":true,"useObjects":false,"useDataSource":true,"useFilter":false,"options":["Option 1","Option 2","Option 3"],"valueField":"code","textField":"name","dataSourceConfig":{"dataSourceGuid":"$dataSourceGuid_1","input":{"propertyInputs":[{"propertyName":"SelectedEmployee","staticValue":{}}]}}},"type":"dropdown","summaryVisibility":"Show","textOrLabel":"text","requiresTemplateOptions":true}]
"@ 

$dynamicFormGuid = [PSCustomObject]@{} 
Invoke-HelloIDDynamicForm -FormName "HRM - Create Employee" -FormSchema $tmpSchema  -returnObject ([Ref]$dynamicFormGuid) 
<# END: Dynamic Form #>

<# Begin: Delegated Form Access Groups and Categories #>
$delegatedFormAccessGroupGuids = @()
foreach($group in $delegatedFormAccessGroupNames) {
    try {
        $uri = ($script:PortalBaseUrl +"api/v1/groups/$group")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
        $delegatedFormAccessGroupGuid = $response.groupGuid
        $delegatedFormAccessGroupGuids += $delegatedFormAccessGroupGuid
        
        Write-ColorOutput Green "HelloID (access)group '$group' successfully found: $delegatedFormAccessGroupGuid"
    } catch {
        Write-ColorOutput Red "HelloID (access)group '$group', message: $_"
    }
}
$delegatedFormAccessGroupGuids = ($delegatedFormAccessGroupGuids | ConvertTo-Json -Compress)

$delegatedFormCategoryGuids = @()
foreach($category in $delegatedFormCategories) {
    try {
        $uri = ($script:PortalBaseUrl +"api/v1/delegatedformcategories/$category")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
        $tmpGuid = $response.delegatedFormCategoryGuid
        $delegatedFormCategoryGuids += $tmpGuid
        
        Write-ColorOutput Green "HelloID Delegated Form category '$category' successfully found: $tmpGuid"
    } catch {
        Write-ColorOutput Yellow "HelloID Delegated Form category '$category' not found"
        $body = @{
            name = @{"en" = $category};
        }
        $body = $body | ConvertTo-Json

        $uri = ($script:PortalBaseUrl +"api/v1/delegatedformcategories")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
        $tmpGuid = $response.delegatedFormCategoryGuid
        $delegatedFormCategoryGuids += $tmpGuid

        Write-ColorOutput Green "HelloID Delegated Form category '$category' successfully created: $tmpGuid"
    }
}
$delegatedFormCategoryGuids = ($delegatedFormCategoryGuids | ConvertTo-Json -Compress)
<# End: Delegated Form Access Groups and Categories #>

<# Begin: Delegated Form #>
$delegatedFormRef = [PSCustomObject]@{guid = $null; created = $null} 
Invoke-HelloIDDelegatedForm -DelegatedFormName "HRM - Create Employee" -DynamicFormGuid $dynamicFormGuid -AccessGroups $delegatedFormAccessGroupGuids -Categories $delegatedFormCategoryGuids -UseFaIcon "True" -FaIcon "fa fa-user-plus" -returnObject ([Ref]$delegatedFormRef) 
<# End: Delegated Form #>

<# Begin: Delegated Form Task #>
if($delegatedFormRef.created -eq $true) { 
	$tmpScript = @'
            try {
              $checkExists = $True
              if($HRMroot.EndsWith("\") -eq $false){
                  $HRMroot = $HRMroot + "\"
              }
              
              #generate unique random personNumber
              do {
                  [string]$personNumber = Get-Random -Minimum 1000 -Maximum 9999
                  if(!(Test-Path "$($HRMroot + $personNumber).json")){
                      $checkExists = $False
                  }
                  
              } while($checkExists)
              
              if ($hasEndDate) {
                  $ed = ([Datetime]$endDate).ToString("o")
              } else {
                  $ed = $null
              }
              
              $person = @{
                  personNumber = $personNumber;
                  firstname = $firstname;
                  prefixLastname = $prefixLastname;
                  lastname = $lastname;
                  title = $title;
                  titleCode = $titleCode;
                  department = $department;
                  departmentCode = $departmentCode;
                  startDate = ([Datetime]$startDate).ToString("o")
                  endDate = $ed;
              }
              
              Write-Output $person | ConvertTo-Json | Out-File "$($HRMroot + $personNumber).json"
          
              HID-Write-Status -Message "HRM person [$firstname $lastname ($personNumber)] created successfully" -Event Success
              HID-Write-Summary -Message "HRM person [$firstname $lastname ($personNumber)] created successfully" -Event Success
              
          } catch {
              HID-Write-Status -Message "Error creating HRM person [$firstname $lastname ($personNumber)]. Error: $($_.Exception.Message)" -Event Error
              HID-Write-Summary -Message "Error creating HRM person [$firstname $lastname ($personNumber)]" -Event Failed
          }
'@; 

	$tmpVariables = @'
[{"name":"department","value":"{{form.department.name}}","secret":false,"typeConstraint":"string"},{"name":"departmentCode","value":"{{form.department.code}}","secret":false,"typeConstraint":"string"},{"name":"endDate","value":"{{form.endDate}}","secret":false,"typeConstraint":"string"},{"name":"firstname","value":"{{form.firstname}}","secret":false,"typeConstraint":"string"},{"name":"hasEndDate","value":"{{form.hasEndDate}}","secret":false,"typeConstraint":"string"},{"name":"lastname","value":"{{form.lastname}}","secret":false,"typeConstraint":"string"},{"name":"prefixLastname","value":"{{form.prefixLastname}}","secret":false,"typeConstraint":"string"},{"name":"startDate","value":"{{form.startDate}}","secret":false,"typeConstraint":"string"},{"name":"title","value":"{{form.title.name}}","secret":false,"typeConstraint":"string"},{"name":"titleCode","value":"{{form.title.code}}","secret":false,"typeConstraint":"string"}]
'@ 

	$delegatedFormTaskGuid = [PSCustomObject]@{} 
	Invoke-HelloIDAutomationTask -TaskName "hrm-create-employee" -UseTemplate "False" -AutomationContainer "8" -Variables $tmpVariables -PowershellScript $tmpScript -ObjectGuid $delegatedFormRef.guid -ForceCreateTask $true -returnObject ([Ref]$delegatedFormTaskGuid) 
} else {
	Write-ColorOutput Yellow "Delegated form 'HRM - Create Employee' already exists. Nothing to do with the Delegated Form task..." 
}
<# End: Delegated Form Task #>
