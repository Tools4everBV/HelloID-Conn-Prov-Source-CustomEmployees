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
