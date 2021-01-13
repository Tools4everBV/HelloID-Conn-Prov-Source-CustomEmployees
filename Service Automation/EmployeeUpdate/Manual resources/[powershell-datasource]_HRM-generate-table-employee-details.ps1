try {
    if($HRMroot.EndsWith("\") -eq $false){
        $HRMroot = $HRMroot + "\"
    }
    
    $employee = Get-Item ($HRMroot + "$($datasource.selectedEmployee.personNumber).json")    
    Write-information -Message $employee
    
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
    
    Write-output $person
} catch {
    Write-error "Error getting HRM person details. Error: $($_.Exception.Message)"
    return
}

