# this script not in use for his role 


# PowerShell RePRINT copy first folder, sorted on lastModified
function timestamp
{
    $ts = Get-Date -format s
    return $ts
}

$fromDirectory = "D:\_temp\copy_bat"
$toDirectory = "D:\_temp\in_dummy"
$extractGUIDdir = ""
$docTypeDir = ""

# Logging
#########
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $fromDirectory\copy_one_reprint_folder.log.txt -append
###########


Write-Host ""
Write-Host (timestamp) "Copy RePRINT extract started"
Write-Host (timestamp) "============================"

Get-ChildItem -path $fromDirectory | Where-Object{ $_.PSIsContainer } | Sort-Object CreationTime | `
    Where-Object {$_.name -ne "_copied"} | `
    Select-Object -first 1 | `
        Foreach-Object{
            Write-Host (timestamp) $_.name
            $extractGUIDdir = $_.FullName
            Get-ChildItem -path $extractGUIDdir |  Where-Object{ $_.PSIsContainer } | Where-Object {$_.Name -match "Purchase Order \(-999999997\)" -or $_.Name -match "Logistics documents \(-1000000000\)" -or $_.Name -match "Specifications \(-999999998\)"} | `
                Foreach-Object{
                    Write-Host (timestamp) "  " $_.Name
                }
            Write-Host ""

            Write-Host "These folders (document types), were also found but will not be included"
            Get-ChildItem -path $extractGUIDdir -Exclude "Logistics documents (-1000000000)", "Purchase Order (-999999997)", "Specifications (-999999998)" | ?{ $_.PSIsContainer } | `
                Foreach-Object{
                    Write-Host (timestamp) " - " $_.name
                }
            Write-Host ""

            Get-ChildItem -path $extractGUIDdir | Where-Object{ $_.PSIsContainer } | Where-Object {$_.Name -match "Purchase Order \(-999999997\)" -or $_.Name -match "Logistics documents \(-1000000000\)" -or $_.Name -match "Specifications \(-999999998\)"} | `
                Foreach-Object{
                        $temp_name = $_.FullName
                        Write-Host (timestamp) "copying files from " $_.FullName
                        Write-Host (timestamp) "                    to "  $toDirectory
                        #Copy-Item ($_.FullName)\*.* $toDirectory
                        Write-Host (timestamp) " copying meta-files..."
                        Copy-Item $temp_name\*.meta $toDirectory -Filter *.meta
                        Write-Host (timestamp) " copying pdf-files..."
                        Copy-Item $temp_name\*.pdf $toDirectory -Filter *.pdf
                        if(Test-Path $temp_name\*.* -Exclude *.meta, *.pdf)
                        {
                            Write-Host (timestamp) " WARNING/ERROR not all documents have been moved. Only PDFs was moved!"
                            Write-Host (timestamp) " Check folder for other document-types."
                        }
                }
                Move-Item $extractGUIDdir $fromDirectory\_copied
        }

Write-Host (timestamp) " DONE!"

# Stop logging
Stop-Transcript