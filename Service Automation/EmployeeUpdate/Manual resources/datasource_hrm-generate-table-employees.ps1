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