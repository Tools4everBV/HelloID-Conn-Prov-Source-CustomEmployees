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