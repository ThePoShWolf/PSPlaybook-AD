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
Function Get-MediaFileInfo {
    Param(
        [string]$File,
        [string]$ffprobe = 'C:\Users\Anthony\Downloads\ffmpeg-20190926-87ddf9f-win64-static\ffmpeg-20190926-87ddf9f-win64-static\bin\ffprobe.exe'
    )
    (& $ffprobe -v quiet -of json -show_format -show_streams $file) -join '' | convertfrom-json
}

$dir = 'C:\Users\Anthony\OneDrive - Howell IT\TechSnips\Courses\PSPlaybook\Edited'
$dirs = Get-ChildItem $dir -Recurse -Directory | ?{(Get-ChildItem $_.FullName -File).count -eq 2}
foreach ($d in $dirs) {
    $files = Get-ChildItem $d.FullName -Filter *.mp4 | Sort -Descending
    # powershell-playbook-automating-active-directory-M5-C1.mp4
    $split = $d.fullname.Split('\')
    if ($split[8] -match '^(?<m>\d\d) \- '){
        $m = $Matches.m
    }
    $c = $split[9]
    #Write-Host $d.fullname
    #Write-Host "m: $m, c: $c"
    Join-ffmpegMp4 -Files $files -OutputFile "$($d.fullname)\powershell-playbook-automating-active-directory-M$m-C$c.mp4"
}

$dir = 'C:\Users\Anthony\OneDrive - Howell IT\TechSnips\Courses\PSPlaybook\Edited'
$dirs = Get-ChildItem $dir -Recurse -Directory -FollowSymLink | ?{(Get-ChildItem $_.FullName -File).count -eq 3}
foreach ($d in $dirs){
    $file = Get-ChildItem $d.FullName -Filter *.mp4 | ?{$_.Name -match '^powershell\-playbook\-automating\-active\-directory\-M\d\d\-C\d\d\.mp4$'}
    $info = Get-MediaFileInfo $file.FullName
    $video = $info.streams | ?{$_.codec_type -eq 'video'}
    if($video.width -ne '1280') {
        Write-Host "Converting $($file.name)"
        $file.name | Out-File .\fileupdates.txt -Append
        $outfile = "$($file.Directory)\$($file.BaseName)_720.mp4"
        #Write-Host $outfile
        & $ffmpeg -i "$($file.FullName)" -vf scale=-1:720 -c:v libx264 -crf 18 -preset veryslow -c:a copy $outfile
    }
}

$path = 'C:\Users\Anthony\OneDrive - Howell IT\TechSnips\Courses\PSPlaybook\Edited\09 - Making You Scripts Approachable\02\powershell-playbook-automating-active-directory-M09-C02.mp4'
$path = 'C:\Users\Anthony\OneDrive - Howell IT\TechSnips\Courses\PSPlaybook\Edited\08 - Extending into the Cloud\02\powershell-playbook-automating-active-directory-M08-C02.mp4'
& $ffmpeg -i "$path" -vf scale=-1:720 -c:v libx264 -crf 18 -preset veryslow -c:a copy .\test.mp4