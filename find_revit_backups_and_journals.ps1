# find_revit_backups_and_journals.ps1

$DocumentsPath = [Environment]::GetFolderPath("MyDocuments")
$LocalAppData  = [Environment]::GetFolderPath("LocalApplicationData")
$JournalRoot   = Join-Path $LocalAppData "Autodesk\Revit"

$ReportPath = Join-Path $DocumentsPath "Revit_Backup_Report.csv"

$FoundBackups    = 0
$FoundRvt        = 0
$DeletedBackups  = 0
$FailedDeletes   = 0
$SkippedBackups  = 0

$Results = @()

Write-Host "Поиск backup папок..." -ForegroundColor Cyan

$BackupFolders = Get-ChildItem -Path $DocumentsPath -Directory -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*_backup" }

$FoundBackups = $BackupFolders.Count

foreach ($BackupFolder in $BackupFolders) {

    $ModelName = $BackupFolder.Name -replace "_backup$", ""

    if ([string]::IsNullOrWhiteSpace($ModelName)) {
        $SkippedBackups++

        $Results += [PSCustomObject]@{
            BackupFolder = $BackupFolder.FullName
            ModelName    = ""
            ExpectedRvt  = ""
            RvtExists    = $false
            Deleted      = $false
            Status       = "Skipped: empty model name"
            Journals     = ""
        }

        continue
    }

    $ExpectedRvt = Join-Path $BackupFolder.Parent.FullName "$ModelName.rvt"
    $RvtExists = Test-Path $ExpectedRvt

    if ($RvtExists) {
        $FoundRvt++
    }

    $JournalMatches = @()

    if ($RvtExists -and (Test-Path $JournalRoot)) {

        $JournalFiles = Get-ChildItem -Path $JournalRoot -Recurse -File -Filter "*.txt" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match "\\Journals\\" }

        foreach ($Journal in $JournalFiles) {
            try {
                $FoundInJournal = Select-String `
                    -Path $Journal.FullName `
                    -Pattern $ModelName `
                    -SimpleMatch `
                    -Quiet `
                    -ErrorAction SilentlyContinue

                if ($FoundInJournal) {
                    $JournalMatches += $Journal.FullName
                }
            }
            catch {
                continue
            }
        }
    }

    $Deleted = $false
    $Status = ""

    if ($RvtExists) {
        try {
            Remove-Item -Path $BackupFolder.FullName -Recurse -Force -ErrorAction Stop
            $DeletedBackups++
            $Deleted = $true
            $Status = "Deleted"

            Write-Host "Удалена: $($BackupFolder.FullName)" -ForegroundColor Green
        }
        catch {
            $FailedDeletes++
            $Status = "Delete failed: $($_.Exception.Message)"

            Write-Host "Ошибка удаления: $($BackupFolder.FullName)" -ForegroundColor Red
        }
    }
    else {
        $SkippedBackups++
        $Status = "Skipped: RVT not found"

        Write-Host "Пропущена, RVT не найден: $($BackupFolder.FullName)" -ForegroundColor Yellow
    }

    $Results += [PSCustomObject]@{
        BackupFolder = $BackupFolder.FullName
        ModelName    = $ModelName
        ExpectedRvt  = $ExpectedRvt
        RvtExists    = $RvtExists
        Deleted      = $Deleted
        Status       = $Status
        Journals     = ($JournalMatches -join "; ")
    }
}

$Results | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "========== ИТОГ ==========" -ForegroundColor Cyan
Write-Host "Найдено backup папок : $FoundBackups"
Write-Host "Найдено RVT файлов   : $FoundRvt"
Write-Host "Удалено папок        : $DeletedBackups"
Write-Host "Пропущено папок      : $SkippedBackups"
Write-Host "Ошибок удаления      : $FailedDeletes"
Write-Host "Отчет сохранен       : $ReportPath"
Write-Host "=========================="
