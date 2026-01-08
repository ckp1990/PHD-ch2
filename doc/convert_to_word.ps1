param (
    [string]$htmlPath,
    [string]$docxPath
)

$ErrorActionPreference = "Stop"

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    
    Write-Host "Opening $htmlPath..."
    $doc = $word.Documents.Open($htmlPath)
    
    Write-Host "Saving as $docxPath..."
    # 16 = wdFormatDocumentDefault (docx)
    $doc.SaveAs($docxPath, 16)
    
    $doc.Close()
    Write-Host "Conversion complete."
}
catch {
    Write-Error "Error during conversion: $_"
    exit 1
}
finally {
    if ($word) {
        $word.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    }
}
