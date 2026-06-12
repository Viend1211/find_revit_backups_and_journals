# find_revit_backups_and_journals.ps1

$DocumentsPath = [Environment]::GetFolderPath("MyDocuments")
$LocalAppData  = [Environment]::GetFolderPath("LocalApplicationData")

$ReportPath = Join-Path $DocumentsPath "Revit_Backup_Report.csv"

# Статистика
$FoundBackups    = 0
$FoundRvt        = 0
$DeletedBackups  = 0
$SkippedBackups  = 0
$FailedBackups   = 0

$FoundJournals   = 0
$DeletedJournals = 0
$FailedJournals  = 0

$Results = @()

Write-Host "Поиск backup папок..." -ForegroundColor Cyan

# Поиск backup папок
$BackupFolders = Get-ChildItem `
    -Path $DocumentsPath `
    -Directory `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -like "*_backup" -and
        $_.Name -ne "_backup"
    }

$FoundBackups = $BackupFolders.Count

foreach ($BackupFolder in $BackupFolders) {

    $ModelName = $BackupFolder.Name -replace "_backup$",""

    if ([string]::IsNullOrWhiteSpace($ModelName)) {
        $SkippedBackups++
        continue
    }

    $ParentFolder = $BackupFolder.Parent.FullName

    $RvtFile = Get-ChildItem `
        -Path $ParentFolder `
        -Filter "*.rvt" `
        -File `
        -ErrorAction SilentlyContinue |
        Where-Object {

            $_.BaseName -eq $ModelName -or
            $_.BaseName -like "$ModelName*" -or
            $ModelName -like "$($_.BaseName)*"

        } |
        Select-Object -First 1

    if ($RvtFile) {

        $FoundRvt++

        try {

            Remove-Item `
                -Path $BackupFolder.FullName `
                -Recurse `
                -Force `
                -ErrorAction Stop

            $DeletedBackups++

            Write-Host "Удалена backup папка: $($BackupFolder.FullName)" -ForegroundColor Green

            $Results += [PSCustomObject]@{
                Type    = "Backup"
                Path    = $BackupFolder.FullName
                Related = $RvtFile.FullName
                Status  = "Deleted"
            }
        }
        catch {

            $FailedBackups++

            Write-Host "Ошибка удаления: $($BackupFolder.FullName)" -ForegroundColor Red

            $Results += [PSCustomObject]@{
                Type    = "Backup"
                Path    = $BackupFolder.FullName
                Related = $RvtFile.FullName
                Status  = "Delete Failed"
            }
        }
    }
    else {

        $SkippedBackups++

        Write-Host "Пропущена (RVT не найден): $($BackupFolder.FullName)" -ForegroundColor Yellow

        $Results += [PSCustomObject]@{
            Type    = "Backup"
            Path    = $BackupFolder.FullName
            Related = ""
            Status  = "RVT Not Found"
        }
    }
}

# ==========================
# Удаление журналов Revit
# ==========================

Write-Host ""
Write-Host "Поиск журналов Revit..." -ForegroundColor Cyan

$JournalFiles = Get-ChildItem `
    -Path $LocalAppData\Autodesk\Revit `
    -Recurse `
    -File `
    -ErrorAction SilentlyContinue |
    Where-Object {

        $_.Name -match '^journal.*\.(txt|log)$' -or
        $_.Name -match '^journal.*worker.*\.log$'

    }

$FoundJournals = $JournalFiles.Count

foreach ($Journal in $JournalFiles) {

    try {

        Remove-Item `
            -Path $Journal.FullName `
            -Force `
            -ErrorAction Stop

        $DeletedJournals++

        Write-Host "Удален журнал: $($Journal.Name)" -ForegroundColor Green

        $Results += [PSCustomObject]@{
            Type    = "Journal"
            Path    = $Journal.FullName
            Related = ""
            Status  = "Deleted"
        }
    }
    catch {

        $FailedJournals++

        Write-Host "Не удалось удалить: $($Journal.FullName)" -ForegroundColor Red

        $Results += [PSCustomObject]@{
            Type    = "Journal"
            Path    = $Journal.FullName
            Related = ""
            Status  = "Delete Failed"
        }
    }
}

# ==========================
# Отчет
# ==========================

$Results |
    Export-Csv `
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========== ИТОГ ==========" -ForegroundColor Cyan

Write-Host "Найдено backup папок  : $FoundBackups"
Write-Host "Найдено RVT файлов    : $FoundRvt"
Write-Host "Удалено backup папок  : $DeletedBackups"
Write-Host "Пропущено backup папок: $SkippedBackups"
Write-Host "Ошибок удаления backup: $FailedBackups"

Write-Host ""

Write-Host "Найдено журналов      : $FoundJournals"
Write-Host "Удалено журналов      : $DeletedJournals"
Write-Host "Ошибок удаления жур.  : $FailedJournals"

Write-Host ""

Write-Host "Отчет сохранен:"
Write-Host $ReportPath

Write-Host "=========================="
