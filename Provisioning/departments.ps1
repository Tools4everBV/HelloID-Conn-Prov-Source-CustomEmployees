$config = ConvertFrom-Json $configuration
$path = $config.path
$departmentsFile = Get-Item $("$path\config\departments.json")

$departments = Get-Content -Raw -LiteralPath $departmentsFile.FullName | ConvertFrom-Json

foreach($department in $departments){

    $d =@{
        DisplayName=$department.name;
        Name=$department.name;
        ExternalId=$department.code;
        ManagerExternalId=$department.managerID;
    }
    Write-Output $d
}