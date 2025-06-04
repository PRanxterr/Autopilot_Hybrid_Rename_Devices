# Autopilot_Hybrid_Rename_Devices
I Joined a Org and they had autopilot Hybrid which used both intune and Local AD to manage devices.
Renaming devices in bulk was a pain in the a** as it would have to be changed in the AD and not just intune.
A service intune account wouldn't work or even a Local admin account wont work for this as it need an account with access to AD object modification access.
yes! you need a an admin account with AD access for this to work.
you need to encrypt the password using AES encryption and need a Decryption key to decrypt the password. will share link to the script on how to do it(the link which i follwed, he's a lifesaver). 
---------------------------------------------------------------------
#######This is the piece of code which encrypts your password and gives 2 text files with password and they key to decrypt it##############
$credObject = Get-Credential
$passwordSecureString = $credObject.password
$AESKeyFilePath = “c:\temp\aeskey.txt”
$credentialFilePath = “c:\temp\credpassword.txt”
$AESKey = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)
Set-Content $AESKeyFilePath $AESKey # Any existing AES Key file will be overwritten
$password = $passwordSecureString | ConvertFrom-SecureString -Key $AESKey
Add-Content $credentialFilePath $password
#########link to the above code###################
https://smbtothecloud.com/naming-hybrid-azure-ad-joined-autopilot-devices-automatically-using-a-custom-prefix-and-serial-number/
--------------------------------------------------------------------
after this step you'll have 4 files
1. credpassword.txt
2. aeskey.txt
3. hostname_map.csv (this is where you'll store all the serial numbers with the hostnames that you need for the serial number)
4. FixHostnames.ps1 (this is what will be excexuted and will take care of most of the work."remember to add your admin username inside the script, line 44").

   Pack all these into a intunewin file has add it as a win32win file.
   install command : powershell.exe -ExecutionPolicy Bypass -File ".\FixHostnames.ps1"

   and it should work!!!
