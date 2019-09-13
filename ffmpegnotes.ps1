Function Join-ffmpegMp4 {
    param (
        [Parameter(
            ValueFromPipeline = $true
        )]
        [ValidateScript({
            $_.Name -match '\.mp4'
        })]
        [System.IO.FileInfo[]]$Files,
        [System.IO.DirectoryInfo]$TempFolder,
        [System.IO.FileInfo]$OutputFile,
        [string]$ffmpeg = 'D:\TechSnips\Demo\ffmpeg\bin\ffmpeg.exe'
    )
    Begin{
        [string[]]$outFiles = @()
    }
    Process {
        foreach ($file in $Files){
            # Create all the tmp files
            $tmpFile = "$($TempFolder.FullName)$($file.BaseName).ts"
            & $ffmpeg -y -i "$($file.FullName)" -c copy -bsf:v h264_mp4toannexb -f mpegts $tmpFile -v quiet
            [string[]]$outFiles += $tmpFile
        }
    }
    End {
        # Join them
        $concatString = "concat:" + ($outFiles -join '|')
        & $ffmpeg -y -f mpegts -i $concatString -c copy -bsf:a aac_adtstoasc $OutputFile -v quiet
        # Clean up
        foreach ($file in $outFiles){
            Remove-Item $file -Force
        }
    }
}

$dir = 'C:\Users\Anthony\OneDrive - Howell IT\TechSnips\Courses\PSPlaybook\Edited'
$dirs = Get-ChildItem $dir -Recurse -Directory | ?{(Get-ChildItem $_.FullName).count -eq 2}
foreach ($d in $dirs) {
    $files = Get-ChildItem $d.FullName -Filter *.mp4 | Sort -Descending
    # powershell-playbook-automating-active-directory-M5-C1.mp4
    $split = $d.fullname.Split('\')
    if ($split[8] -match '^(?<m>\d\d) \- '){
        $m = $Matches.m
    }
    $c = $split[9]
    #Write-Host "m: $m, c: $c"
    Join-ffmpegMp4 -Files $files -OutputFile "$($d.fullname)\powershell-playbook-automating-active-directory-M$m-C$c.mp4"
}