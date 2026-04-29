function CompactAll_Vhd {
    # check if search locations given in args, otherwise find valid local drives
    if ($args.Count -eq 0) {
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { `
          $_.Root -match '^[A-Z]:\\$' }
        $args = $drives.Root -join ' '
    }
     # find all the vhdx files using fd-find fd.exe (scoop install fd)
    $vhdpaths = fd.exe -H -a -i -tf -g *.vhdx
    foreach ($vhdfile in $vhdfiles) {
        Write-Host "Processing $vhdfile... " -NoNewLine
        if ( $(fsutil sparse queryFlag $vhdfile) -eq "This file is set as sparse" ) {
            $sparseVhds += $vhdfile + " "
            fsutil sparce setFlag $vhdfile 0
            Write-Host "unset sparse... " -NoNewLine
        }
        [int]$origSize= (Get-Item -Path $vhdfile).Length
        Optimize-Vhd -Path $vhdfile -Mode Full
        [int]$newSize= (Get-Item -Path $vhdfile).Length
        [int]$cRatio = $origSize * 100 / $newSize
        Write-Host "fin. Compression ratio $cRatio%"
    }
}