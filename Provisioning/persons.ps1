$config = ConvertFrom-Json $configuration
$path = $config.path
$employees = Get-ChildItem $path -Filter '*.json' -File

foreach($employee in $employees){
    $person = Get-Content -Raw -LiteralPath $employee.FullName | ConvertFrom-Json

    $contracts = @();
    $contracts += @{
        title = $person.title;
        titleCode = $person.titleCode;
        department = $person.department;
        departmentCode = $person.departmentCode;
        startDate = $person.startDate;
        endDate = $person.endDate;
    }

    $person | Add-Member -Name "ExternalId" -MemberType NoteProperty -Value $person.personNumber;
    $person | Add-Member -Name "DisplayName" -MemberType NoteProperty -Value "$($person.firstName + ' '+ $person.prefixLastName + ' ' + $person.lastName)";
    
    $person | Add-Member -Name "Contracts" -MemberType NoteProperty -Value $contracts;
    Write-Output $person | ConvertTo-Json -Depth 2
}

Write-Verbose -Verbose "Person import completed";