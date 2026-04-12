Add-Type -AssemblyName System.Drawing
$path = 'A:\College\FPGA-Acceleration-for-Huffman-Coding\screenshots\'
$files = @('waveform_encoder.png','waveform_deocder.png','waveform_full_test.png','waveform_full_test_300ns_to_600ns.png','waveform_full_test_600ns_to_800ns.png')
foreach ($f in $files) {
    $img = [System.Drawing.Image]::FromFile($path + $f)
    Write-Host ($f + ' : ' + $img.Width + ' x ' + $img.Height)
    $img.Dispose()
}
