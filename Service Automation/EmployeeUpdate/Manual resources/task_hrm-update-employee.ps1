try {
    if($HRMroot.EndsWith("\") -eq $false){
        $HRMroot = $HRMroot + "\"
    }
                
    if ($hasEndDate -eq "true") {
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