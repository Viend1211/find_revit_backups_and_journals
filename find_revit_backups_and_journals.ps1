# find_revit_backups_and_journals.ps1

$DocumentsPath = [Environment]::GetFolderPath("MyDocuments")
$LocalAppData  = [Environment]::GetFolderPath("LocalApplicationData")
$JournalRoot   = Join-Path $LocalAppData "Autodesk\Revit"
$ReportPath    = Join-Path $DocumentsPath "Revit_Backup_Report.csv"

$FoundBackups     = 0
$FoundRvt         = 0
$DeletedBackups   = 0
$SkippedBackups   = 0
$FailedBackups    = 0

$FoundJournals    = 0
$DeletedJournals  = 0
$FailedJournals   = 0

$Results = @()

Write-Host "Поиск backup папок..." -ForegroundColor Cyan

$BackupFolders = Get-ChildItem -Path $DocumentsPath -Directory -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*_backup" -and $_.Name -ne "_backup" }

$FoundBackups = $BackupFolders.Count

foreach ($BackupFolder in $BackupFolders) {

    $ModelName = $BackupFolder.Name -replace "_backup$", ""

    if ([string]::IsNullOrWhiteSpace($ModelName)) {
        $SkippedBackups++
        continue
    }

    $ParentFolder = $BackupFolder.Parent.FullName
    $ExactRvt = Join-Path $ParentFolder "$ModelName.rvt"

    $RvtFile = $null

    if (Test-Path $ExactRvt) {
        $RvtFile = Get-Item $ExactRvt
    }
    else {
        $RvtFile = Get-ChildItem -Path $ParentFolder -File -Filter "*.rvt" -ErrorAction SilentlyContinue |
            Where-Object {
                $_.BaseName -like "$ModelName*" -or
                $ModelName -like "$($_.BaseName)*" -or
                $_.BaseName.Contains($ModelName) -or
                $ModelName.Contains($_.BaseName)
            } |
            Select-Object -First 1
    }

    $RvtExists = $null -ne $RvtFile

    if ($RvtExists) {
        $FoundRvt++

        try {
            Remove-Item -Path $BackupFolder.FullName -Recurse -Force -ErrorAction Stop
            $DeletedBackups++
            $Status = "Backup deleted"
            Write-Host "Удалена backup папка: $($BackupFolder.FullName)" -ForegroundColor Green
        }
        catch {
            $FailedBackups++
            $Status = "Backup delete failed: $($_.Exception.Message)"
            Write-Host "Ошибка удаления backup: $($BackupFolder.FullName)" -ForegroundColor Red
        }
    }
    else {
        $SkippedBackups++
        $Status = "Skipped: RVT not found"
        Write-Host "Пропущена backup папка, RVT не найден: $($BackupFolder.FullName)" -ForegroundColor Yellow
    }

    $Results += [PSCustomObject]@{
        Type         = "BackupFolder"
        Path         = $BackupFolder.FullName
        RelatedRvt   = if ($RvtFile) { $RvtFile.FullName } else { "" }
        Deleted      = $RvtExists
        Status       = $Status
    }
}

Write-Host ""
Write-Host "Поиск Revit journals..." -ForegroundColor Cyan

if (Test-Path $JournalRoot) {
    $JournalFiles = Get-ChildItem -Path $JournalRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DirectoryName -match "\\Journals$" -and
            ($_.Name -like "journal*.txt" -or $_.Name -like "journal*.log")
        }

    $FoundJournals = $JournalFiles.Count

    foreach ($Journal in $JournalFiles) {
        try {
            Remove-Item -Path $Journal.FullName -Force -ErrorAction Stop
            $DeletedJournals++

            Write-Host "Удален journal: $($Journal.FullName)" -ForegroundColor Green

            $Results += [PSCustomObject]@{
                Type         = "Journal"
                Path         = $Journal.FullName
                RelatedRvt   = ""
                Deleted      = $true
                Status       = "Journal deleted"
            }
        }
        catch {
            $FailedJournals++

            Write-Host "Ошибка удаления journal: $($Journal.FullName)" -ForegroundColor Red

            $Results += [PSCustomObject]@{
                Type         = "Journal"
                Path         = $Journal.FullName
                RelatedRvt   = ""
                Deleted      = $false
                Status       = "Journal delete failed: $($_.Exception.Message)"
            }
        }
    }
}

$Results | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "========== ИТОГ ==========" -ForegroundColor Cyan
Write-Host "Найдено backup папок  : $FoundBackups"
Write-Host "Найдено RVT файлов    : $FoundRvt"
Write-Host "Удалено backup папок  : $DeletedBackups"
Write-Host "Пропущено backup папок: $SkippedBackups"
Write-Host "Ошибок backup удаления: $FailedBackups"
Write-Host ""
Write-Host "Найдено journal файлов: $FoundJournals"
Write-Host "Удалено journal файлов: $DeletedJournals"
Write-Host "Ошибок journal удален.: $FailedJournals"
Write-Host ""
Write-Host "Отчет сохранен        : $ReportPath"
Write-Host "=========================="
