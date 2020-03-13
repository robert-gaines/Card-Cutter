<# A Script Designed to Expedite Card Cutting #>

<# Author: RWG 01/29/2020 #>

#$ErrorActionPreference = "SilentlyContinue"

<#

try
{
    Set-ExecutionPolicy Bypass
}
catch
{
    Write-Host -ForegroundColor Red "[!] Failed to modify execution policy [!]"

    exit
}

#>

function LocateDirectory
{
    Get-ChildItem -Path C:\Users\KC135\Desktop\ | Foreach-Object { if($_.Name | Select-String -Pattern "CRD")
                                                                   {
                                                                    return $_.FullName
                                                                   }
                                                                 }
}

function DiscernLabel
{
    $response = LocateDirectory

    $segments = @($response.Split("\"))

    Foreach($s in $segments)
    {
        if($s | Select-String -Pattern "CRD")
        {
            $targetSegment = $s.Split()

            $targetSubSegments = $targetSegment.Split()

            $desiredLabel = $targetSubSegments[0]

            return $desiredLabel
        }
    }
}

function CheckIntegrity
{
    Write-Host -ForegroundColor Green "[*] Beginning Integrity Check [*]" ; Start-Sleep -Seconds 1

    function GenSourceHashes()
    {
        $hashValues = @()

        $sourceDirectory = LocateDirectory ; $directory = [string]$sourceDirectory

        Get-ChildItem -Path $directory | Foreach-Object {
                                                            if((Get-Item $_.FullName) -is [System.IO.DirectoryInfo])
                                                            {
                                                                 Get-ChildItem -Path $_.FullName -Recurse | Foreach-Object { 
                                                                 $hashValue = Get-FileHash -Path $_.FullName -Algorithm SHA256 ;
                                                                 $hashValues += $hashValue 
                                                            }
                                                            }
                                                            else
                                                            {  
                                                                $hashValue = Get-FileHash -Path $_.FullName -Algorithm SHA256 ;
                                                                $hashValues += $hashValue  
                                                            } 
                                                        }
        return $hashValues
    }

    $sourceHashes = GenSourceHashes

    function GenDestinationHashes()
    {
        $hashValues = @()

        $cardVolume = Get-Volume | Where-Object FileSystem -eq FAT ; $cardVolume=[string]$cardVolume.DriveLetter; $cardVolume=$cardVolume+=":\"

        Get-ChildItem -Path $cardVolume | Foreach-Object {
                                                             if((Get-Item $_.FullName) -is [System.IO.DirectoryInfo])
                                                             {
                                                                  Get-ChildItem -Path $_.FullName -Recurse | Foreach-Object { 
                                                                  $hashValue = Get-FileHash -Path $_.FullName -Algorithm SHA256 ;
                                                                  $hashValues += $hashValue  }  
                                                             }
                                                             else
                                                             { 
                                                                  $hashValue = Get-FileHash -Path $_.FullName -Algorithm SHA256 ;
                                                                  $hashValues += $hashValue   
                                                             } 
                                                          }
                                                                 
        return $hashValues
    }

    $destinationHashes = GenDestinationHashes

    for($i = 0; $i -lt $sourceHashes.Count; $i++)
    {
          $sourceFile = $sourceHashes[$i].Path ; $destinationFile = $destinationHashes[$i].Path
          $sourceHash = $sourceHashes[$i].Hash ; $destinationHash = $destinationHashes[$i].Hash
          Write-Host -BackgroundColor Black -ForegroundColor Yellow "[*] Checking   : $sourceFile <==|==> $destinationFile "
          Write-Host -BackgroundColor Black -ForegroundColor Yellow "[*] Hash Values: $sourceHash <==|==> $destinationHash "
          if($sourceHashes[$i].Hash -eq $destinationHashes[$i].Hash)
          {
              Write-Host -BackgroundColor DarkGray -ForegroundColor Green "[*] Pass [*]" ; Start-Sleep -Seconds 1 ; Clear-Host
          }
          else
          {
              Write-Host -BackgroundColor Black -ForegroundColor Red "[!] Fail [!]" ; Start-Sleep -Seconds 1 ; Clear-Host

              "[!] Error Source: $sourceFile | $destinationFile => $sourceHash != $destinationHash " | Out-File "error_capture.txt"

              Write-host -BackgroundColor Black -ForegroundColor Red "
_____________________________________
|***********************************|
-------------------------------------
| WARNING: Integrity Check Failure! |
|                                   |
|    The card preparation routine   |
|    did not function correctly.    |
|    Do not attempt to use this     |
|    card operationally.            |
_____________________________________
|***********************************|
-------------------------------------
                                     "
              Start-Sleep -Seconds 30 ; Exit
          }

      
    
    }

    Write-Host -ForegroundColor Green "
_______________________________________
|                                     |
|*************************************|
|*   File Integrity Check Complete   *|
|*************************************|
|_____________________________________|

                                      "
    
    Start-Sleep -Seconds 3 ; Clear-Host
}

function main()
{
    $volume = Get-Volume | Where-Object FileSystem -eq FAT

    if(-not $volume)
    {
        Write-Host -ForegroundColor Red "[!] Failed to locate volume [!]" ; exit
    }

    $driveLetter = [string]$volume.DriveLetter 

    Write-Host -ForegroundColor Green "[*] Located FAT Formatted Media: $driveLetter [*]"

    Write-Host -ForegroundColor Yellow "[*] Searching for staging folders..." ; Start-Sleep -Seconds 1

    $targetPath = LocateDirectory

    if(Test-Path -path $targetPath)
    {
        Write-Host -ForegroundColor Green "[*] Located card data directory [*]" ; Start-Sleep -Seconds 1
    }
    else
    {
        Write-Host -ForegroundColor Red "[!] Failed to locate target directory [!]" ; Start-Sleep -Seconds 1

        exit
    }

    $newLabel = DiscernLabel ; Write-Host -ForegroundColor Green "[*] New Volume Label: $newLabel " ; Start-Sleep -Seconds 1

    Write-Host -ForegroundColor Yellow "[*] Formatting target volume [*]" ; Start-Sleep -Seconds 1
    
    try
    {
        Format-Volume -DriveLetter $driveLetter -FileSystem FAT -NewFileSystemLabel $newLabel 
    }
    catch
    {
        Write-Host -ForegroundColor Red "[!] Failed to modify volume [!]" ; exit
    }

    Write-Host -ForegroundColor Green "[*] Volume successfully formatted and labeled [*]"

    Write-Host -ForegroundColor Yellow "[*] Beginning copy operation ... " ; Start-Sleep -Seconds 1 

    $driveLetter = $driveLetter+":\"

    Get-ChildItem -Path $targetPath | Foreach-Object {
                                                       if((Get-Item $_.FullName) -is [System.IO.DirectoryInfo])
                                                       {
                                                        Write-Host -Foregroundcolor Green "[*] Copying: $_ "; 
                                                        Copy-Item -Path $_.FullName -Recurse -Destination $driveLetter ; 
                                                        Start-Sleep -Seconds 1
                                                       }
                                                       else
                                                       { 
                                                        Write-Host -Foregroundcolor Green "[*] Copying: $_ "; 
                                                        Copy-Item -Path $_.FullName -Destination $driveLetter ; 
                                                        Start-Sleep -Seconds 1
                                                       } 
                                                     }

    Write-Host "`n"

    Clear-Host

    CheckIntegrity

    Write-Host "`n"

    Write-Host -ForegroundColor Green "
-------------------------------------
[*] Card Cutting Process Complete [*]
-------------------------------------
    " ; 
    
    explorer.exe $driveLetter ; Start-Sleep -Seconds 3 ; Clear-Host ; Exit
}

main



