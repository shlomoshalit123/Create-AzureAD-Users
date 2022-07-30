Connect-AzureAD 

$SecurityGroupName = "Varonis Assignment Group"
$GenereicUserDisplayName = 'Test User'

$GenericUserName = $GenereicUserDisplayName -replace " ",""
$Domain = (Get-AzureADDomain).name
 

Function Log-Time {
    Get-date -Format "MM/dd/yyyy HH:mm:ss"
}

$NewUsers = @()

$CreateUserCount = 1

do{

    $UserName = "$GenericUserName$($CreateUserCount)"
    $DisplayName = "$GenereicUserDisplayName $($CreateUserCount)”
    $UserPrincipalName = "$UserName@$Domain”

    #Write-Output "$(Log-Time): Creating User - $UserPrincipalName"

    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = "Password$i!"

    $retry = 0

    do {

        try {
            $NewUser = New-AzureADUser -DisplayName $DisplayName -UserPrincipalName $UserPrincipalName -MailNickName $UserName -PasswordProfile $PasswordProfile -AccountEnabled $true -ErrorAction Stop
            $CreateUserResult = "Success"
            $NewUsers += $NewUser
        }
        Catch {
            $CreateUserResult = "Failure"
            $retry++
            Start-Sleep -Seconds 2
        } 
    }
    until ($CreateUserResult -like "Success" -or $retry -eq 5)

    $CreateUserCount++
}
until ($CreateUserCount -eq 21)

$CreateGroupCouter = 1

do {

    try {
        $NewGroup = New-AzureADGroup -DisplayName $SecurityGroupName -SecurityEnabled $true -MailEnabled $false -MailNickName "NotSet" -ErrorAction Stop
        $CredGroupResult = "Success"
    }
    Catch {
        $CredGroupResult = "Failure"
        $CreateGroupCouter++
    }
}
until ($CreateGroupCouter -eq 5 -or $CredGroupResult -like "Success")

# Write-Output "$(Log-Time): Creating Group - $SecurityGroupName - $CredGroupResult"

if ($CredGroupResult -like "Success") {

    Foreach ($User in $NewUsers) {
        $AddUserToGroupCounter = 0

        do {

            try {
                $LastError = $null
                Add-AzureADGroupMember -ObjectId $NewGroup.ObjectId -RefObjectId $User.ObjectId -ErrorAction Stop
                $Result = "Success"
            }
            Catch {        
                Write-Output "$(Log-Time): Fail - reattempt in 5 seconds"
                Start-Sleep -Seconds 5
                $AddUserToGroupCounter++
                $Result = "Failure"
            }
        }
        until ($Result -like "Success" -or $AddUserToGroupCounter -eq 5)

        New-Object psobject -Property @{
            Username = $User.UserPrincipalName
            Result = $Result
            TimeStemp = Log-Time
        }
    }
}
else {
        Write-Output "$(Log-Time): Failure to create group $SecurityGroupName "
}

 

 

 

 

 

<#

Notes:

1. password for each user is not saved or logged.

 

#>