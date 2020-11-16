try {
    if($HRMroot.EndsWith("\") -eq $false){
        $HRMroot = $HRMroot + "\"
    }
    
    $employee = Get-Item ($HRMroot + "$($forminput.selectedEmployee.personNumber).json")
    
    Hid-Write-Summary -Message $employee -Event Information
    
    $e = Get-Content -Raw -LiteralPath $employee.FullName | ConvertFrom-Json
    $hasEndDate = $True
    if($null -eq $e.endDate){
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