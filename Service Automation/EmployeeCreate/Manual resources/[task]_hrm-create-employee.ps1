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
