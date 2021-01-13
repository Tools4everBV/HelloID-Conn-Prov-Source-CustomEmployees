try {
    if($HRMroot.EndsWith("\") -eq $false){
        $HRMroot = $HRMroot + "\"
    }
    
    $employees = Get-ChildItem $HRMroot -Filter '*.json' -File
    $resultCount = @($employees).Count
    Write-information "Result count: $resultCount"
    
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
        
    Write-output $persons | Sort-Object -Property lastname
} catch {
    Write-error "Error getting HRM persons. Error: $($_.Exception.Message)"
    return
}

