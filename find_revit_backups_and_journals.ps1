# find_revit_backups_and_journals.ps1

$DocumentsPath = [Environment]::GetFolderPath("MyDocuments")
$LocalAppData  = [Environment]::GetFolderPath("LocalApplicationData")

$JournalRoot = Join-Path $LocalAppData "Autodesk\Revit"

$BackupFolders = Get-ChildItem -Path $DocumentsPath -Directory -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*_backup" }

$Results = foreach ($BackupFolder in $BackupFolders) {

    $ModelName = $BackupFolder.Name -replace "_backup$", ""
    $ExpectedRvt = Join-Path $BackupFolder.Parent.FullName "$ModelName.rvt"

    $JournalMatches = @()

    if (Test-Path $JournalRoot) {
        $JournalFiles = Get-ChildItem -Path $JournalRoot -Recurse -File -Filter "*.txt" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match "\\Journals\\" }

        foreach ($Journal in $JournalFiles) {
            $Found = Select-String -Path $Journal.FullName -Pattern ([regex]::Escape($ModelName)) -SimpleMatch -ErrorAction SilentlyContinue

            if ($Found) {
                $JournalMatches += $Journal.FullName
            }
        }
    }

    [PSCustomObject]@{
        BackupFolder = $BackupFolder.FullName
        ExpectedRvt  = $ExpectedRvt
        RvtExists    = Test-Path $ExpectedRvt
        Journals     = ($JournalMatches -join "; ")
    }
}

$ReportPath = Join-Path $DocumentsPath "Revit_Backup_Report.csv"

$Results | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

Write-Host "Готово. Отчет сохранен:"
Write-Host $ReportPath
