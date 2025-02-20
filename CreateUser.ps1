#Script to create users from csv file

#Path to the CSV file on your local machine
$csvFilePath = "C:\Automatisering\users.csv"

#Credentials for the remote domain controller
$domainController = "10.14.2.219"
$domainAdminUser = "Administrator"
$domainAdminPassword = ConvertTo-SecureString "Kode1234!" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($domainAdminUser, $domainAdminPassword)

# Import the CSV file
$users = Import-Csv -Path $csvFilePath


# Debugging: Print out the first few rows of the users array to check the format
$users | Select-Object -First 5

# Serialize the users list to a JSON string
$usersJson = $users | ConvertTo-Json -Depth 10

# Check if the CSV is loaded correctly and contains data
if ($users.Count -eq 0) {
    Write-Host "No users found in the CSV file." -ForegroundColor Red
    exit
}


$scriptBlock = {
    param ($usersJson)

    # Deserialize the users JSON string back into an object
    $usersList = $usersJson | ConvertFrom-Json

    # Check the length of the users list remotely
    Write-Host "Total number of users passed: $($usersList.Count)"
    
    foreach ($user in $userslist) {

        
        Write-Host "Processing user: $($user.Username) with OUPath: $($user.OU)"

        if ([string]::IsNullOrEmpty($user.OU)) {
            Write-Warning "OU path is missing for user $($user.Username). Skipping user."
            continue  # Skip this user
        }

        # Check if the user already exists in Active Directory
        $userExists = Get-ADUser -Identity $user.Username

        if ($userExists) {
            Write-Warning "User $($user.Username) already exists. Skipping user creation."
            continue
        }

        # Check if the OU exists, and create it if not
        $OUPath = $user.OU
        try {
            # Check if OU exists
            $OUExists = Get-ADOrganizationalUnit -Filter {DistinguishedName -eq $OUPath}
            if (-not $OUExists) {
                Write-Host "OU $OUPath does not exist. Creating it now."
                New-ADOrganizationalUnit -Name $OUPath.Split(',').Split('=')[1] -Path "DC=jens,DC=jon"
                Write-Host "Created the OU: $($OUPath)"
            }
        } catch {
            Write-Host "Error checking or creating OU" -ForegroundColor Red
            continue
        }


        #Define some user properties
        $userPrincipalName = "$($user.Username)@jens.jon"
        $displayName = "$($user.FirstName) $($user.LastName)"
        $password = ConvertTo-SecureString $user.Password -AsPlainText -Force

        try{
            # Create the user in Active Directory
            New-ADUser -SamAccountName $user.Username `
                    -UserPrincipalName $userPrincipalName `
                    -Name $displayName `
                    -GivenName $user.FirstName `
                    -Surname $user.LastName `
                    -DisplayName $displayName `
                    -AccountPassword $password `
                    -Enabled $true `
                    -Path $oupath 

            Write-Host "User $($user.Username) created successfully."
        }catch{Write-Host "Error creating user $($user.Username): $_" -ForegroundColor Red}    
    }
}

#Invoke-Command to process all users
try {
    # Print users data for debugging (so we can ensure it's being passed)
    Write-Host "Processing $($users.Count) users from CSV..." -ForegroundColor Green

    Invoke-Command -ComputerName $domainController -Credential $cred -ScriptBlock $scriptBlock -ArgumentList $usersJson
    Write-Host "All users created successfully."
} catch {
    Write-Host "An error occurred while creating users: $_" -ForegroundColor Red
}
