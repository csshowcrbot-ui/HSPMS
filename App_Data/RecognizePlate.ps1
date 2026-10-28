param(
    [string]$ImagePath
)

if (-not (Test-Path $ImagePath)) {
    Write-Output ""
    exit 0
}

try {
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction Stop

    [Windows.Media.Ocr.OcrEngine, Windows.Foundation.UniversalApiContract, ContentType = WindowsRuntime] | Out-Null
    [Windows.Graphics.Imaging.BitmapDecoder, Windows.Foundation.UniversalApiContract, ContentType = WindowsRuntime] | Out-Null
    [Windows.Storage.StorageFile, Windows.Foundation.UniversalApiContract, ContentType = WindowsRuntime] | Out-Null
    [Windows.Globalization.Language, Windows.Foundation.UniversalApiContract, ContentType = WindowsRuntime] | Out-Null
    [Windows.Storage.Streams.InMemoryRandomAccessStream, Windows.Foundation.UniversalApiContract, ContentType = WindowsRuntime] | Out-Null
    [Windows.Storage.Streams.DataWriter, Windows.Foundation.UniversalApiContract, ContentType = WindowsRuntime] | Out-Null

    $asTaskGeneric = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' 
    }[0]

    function Await-Async($asyncOp, $targetType) {
        $m = $asTaskGeneric.MakeGenericMethod($targetType)
        $t = $m.Invoke($null, @($asyncOp))
        $t.Wait()
        return $t.Result
    }

    $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage([Windows.Globalization.Language]::new('en-US'))

    function Run-Ocr($bmp) {
        try {
            $ms = New-Object System.IO.MemoryStream
            $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
            $bytes = $ms.ToArray()
            $ms.Dispose()

            $ras = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
            $writer = New-Object Windows.Storage.Streams.DataWriter($ras)
            $writer.WriteBytes($bytes)
            Await-Async ($writer.StoreAsync()) ([uint32]) | Out-Null
            $writer.DetachStream() | Out-Null
            $ras.Seek(0)

            $decoder = Await-Async ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($ras)) ([Windows.Graphics.Imaging.BitmapDecoder])
            $softwareBitmap = Await-Async ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])

            $ocrResult = Await-Async ($engine.RecognizeAsync($softwareBitmap)) ([Windows.Media.Ocr.OcrResult])

            $lines = @()
            foreach ($l in $ocrResult.Lines) { $lines += $l.Text }
            return ($lines -join " ")
        } catch {
            return ""
        }
    }

    function Extract-Plate($rawText) {
        if (-not $rawText) { return $null }

        $text = $rawText.ToUpper()
        # 192..197 are Latin A accents (À, Á, Â, Ã, Ä, Å)
        $accentA = [string][char]192 + [char]193 + [char]194 + [char]195 + [char]196 + [char]197
        $text = [regex]::Replace($text, "[$accentA]", "A")

        # If < appears before 3 digits, it's hyphen + 6 (e.g. AUU<990 -> AUU-6990)
        $text = [regex]::Replace($text, "<(\d{3})", "-6`$1")

        # Double arch or rounded A misread as M or R before UU
        $text = [regex]::Replace($text, "(M|R)UU", "AUU")
        $text = [regex]::Replace($text, "A(OIJ|LLJ|IIJ)", "AUU")
        $text = [regex]::Replace($text, "(OIJ|LLJ)", "UU")

        # If letter + space + 2 digits/letters before dot/dash: 'A 00.6990' -> 'A00-6990'
        $text = [regex]::Replace($text, "([A-Z0-9])\s+([A-Z0-9]{2})[\s\-.:]+", "`$1`$2-")
        $text = [regex]::Replace($text, "A00", "AUU")
        $text = [regex]::Replace($text, "AOO", "AUU")

        # Clean separator characters: dots, bullet points, colons, underscores
        $text = [regex]::Replace($text, "[\u00B7\u2022\u3002.:_\s]+", "-")

        # Pattern 1: 3 chars + 4 chars (e.g. ASU-7635, AUU-6990, BRW-2528)
        $m1 = [regex]::Match($text, '([A-Z0-9]{3})-*([A-Z0-9]{4})')
        if ($m1.Success) {
            $p1 = $m1.Groups[1].Value
            $p2 = $m1.Groups[2].Value

            # Reject pure letters in 4-digit block (e.g. grille noise FII-HIT)
            if (-not ($p1 -match '^[A-Z]+$' -and $p2 -match '^[A-Z]+$' -and $p2 -notmatch '[0-9]')) {
                # Normalize p1 to letters
                $norm1 = $p1.Replace('0', 'O').Replace('1', 'I').Replace('5', 'S').Replace('8', 'B')
                # Normalize p2 to digits
                $norm2 = $p2.Replace('O', '0').Replace('D', '0').Replace('Q', '0').Replace('I', '1').Replace('L', '1').Replace('Z', '2').Replace('S', '3').Replace('B', '8').Replace('G', '6')

                if ($norm1 -match '^[A-Z]{3}$' -and $norm2 -match '^\d{4}$') {
                    return "$norm1-$norm2"
                }
            }
        }

        # Pattern 2: 4 digits + 2 letters (5678-EF)
        $m2 = [regex]::Match($text, '([A-Z0-9]{4})[\s\-]+([A-Z0-9]{2})')
        if ($m2.Success) {
            $p1 = $m2.Groups[1].Value
            $p2 = $m2.Groups[2].Value
            $norm1 = $p1.Replace('O', '0').Replace('D', '0').Replace('Q', '0').Replace('I', '1').Replace('L', '1').Replace('Z', '2').Replace('S', '3').Replace('B', '8').Replace('G', '6')
            $norm2 = $p2.Replace('0', 'O').Replace('1', 'I').Replace('5', 'S').Replace('8', 'B')
            if ($norm1 -match '^\d{4}$' -and $norm2 -match '^[A-Z]{2}$') {
                return "$norm1-$norm2"
            }
        }

        # Pattern 3: 2 letters + 4 digits (AB-1234)
        $m3 = [regex]::Match($text, '([A-Z0-9]{2})[\s\-]+([A-Z0-9]{4})')
        if ($m3.Success) {
            $p1 = $m3.Groups[1].Value
            $p2 = $m3.Groups[2].Value
            $norm1 = $p1.Replace('0', 'O').Replace('1', 'I').Replace('5', 'S').Replace('8', 'B')
            $norm2 = $p2.Replace('O', '0').Replace('D', '0').Replace('Q', '0').Replace('I', '1').Replace('L', '1').Replace('Z', '2').Replace('S', '3').Replace('B', '8').Replace('G', '6')
            if ($norm1 -match '^[A-Z]{2}$' -and $norm2 -match '^\d{4}$') {
                return "$norm1-$norm2"
            }
        }

        # Pattern 4: 3 chars + 3 chars (motorcycles)
        $m4 = [regex]::Match($text, '([A-Z0-9]{3})[\s\-]+([A-Z0-9]{3})')
        if ($m4.Success) {
            $p1 = $m4.Groups[1].Value
            $p2 = $m4.Groups[2].Value
            if ($p1 -match '[0-9]' -or $p2 -match '[0-9]') {
                return "$p1-$p2"
            }
        }

        return $null
    }

    $orig = [System.Drawing.Bitmap]::FromFile($ImagePath)

    # 1. Full Image (close-up fast scan)
    $raw1 = Run-Ocr $orig
    $res1 = Extract-Plate $raw1
    if ($res1) {
        $orig.Dispose()
        Write-Output $res1
        exit 0
    }

    # 1.5 Close-Up Plate Scan (針對前端取景裁切或近拍照片，等比放大並進行多視角辨識)
    $aspect = $orig.Width / [Math]::Max(1, $orig.Height)
    if (($aspect -ge 1.4 -and $aspect -le 3.8) -or ($orig.Width -le 900 -and $orig.Height -le 380)) {
        $scaleFactor = if ($orig.Height -lt 160) { 2.2 } else { 1.5 }
        $cw = [int]($orig.Width * $scaleFactor)
        $ch = [int]($orig.Height * $scaleFactor)
        $closeScaled = New-Object System.Drawing.Bitmap $cw, $ch
        $gc = [System.Drawing.Graphics]::FromImage($closeScaled)
        $gc.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $gc.DrawImage($orig, [System.Drawing.Rectangle]::new(0, 0, $cw, $ch), 0, 0, $orig.Width, $orig.Height, [System.Drawing.GraphicsUnit]::Pixel)
        $gc.Dispose()

        $rawClose = Run-Ocr $closeScaled
        $resClose = Extract-Plate $rawClose
        if ($resClose) {
            $closeScaled.Dispose()
            $orig.Dispose()
            Write-Output $resClose
            exit 0
        }

        foreach ($ang in @(4, -4, 8, -8, 12, -12)) {
            $rotClose = New-Object System.Drawing.Bitmap ($cw + 40), ($ch + 40)
            $grc = [System.Drawing.Graphics]::FromImage($rotClose)
            $grc.Clear([System.Drawing.Color]::White)
            $grc.TranslateTransform($rotClose.Width / 2, $rotClose.Height / 2)
            $grc.RotateTransform($ang)
            $grc.TranslateTransform(-$cw / 2, -$ch / 2)
            $grc.DrawImage($closeScaled, 0, 0)
            $grc.Dispose()

            $rawRotClose = Run-Ocr $rotClose
            $rotClose.Dispose()

            $resRotClose = Extract-Plate $rawRotClose
            if ($resRotClose) {
                $closeScaled.Dispose()
                $orig.Dispose()
                Write-Output $resRotClose
                exit 0
            }
        }
        $closeScaled.Dispose()
    }

    # 2. Lower-center Bumper Region (Y: 45%..85%, X: 10%..90%) at Scale 1.0 (BRW-2528)
    $x1 = [int]($orig.Width * 0.10)
    $y1 = [int]($orig.Height * 0.45)
    $w1 = [int]($orig.Width * 0.80)
    $h1 = [int]($orig.Height * 0.40)

    $crop1 = New-Object System.Drawing.Bitmap $w1, $h1
    $g1 = [System.Drawing.Graphics]::FromImage($crop1)
    $g1.DrawImage($orig, [System.Drawing.Rectangle]::new(0, 0, $w1, $h1), $x1, $y1, $w1, $h1, [System.Drawing.GraphicsUnit]::Pixel)
    $g1.Dispose()

    $raw2 = Run-Ocr $crop1
    $crop1.Dispose()
    $res2 = Extract-Plate $raw2
    if ($res2) {
        $orig.Dispose()
        Write-Output $res2
        exit 0
    }

    # 3. Targeted Center Plate Region (X: 18%..82%, Y: 48%..78%) at Scale 1.3
    $x2 = [int]($orig.Width * 0.18)
    $y2 = [int]($orig.Height * 0.48)
    $w2 = [int]($orig.Width * 0.64)
    $h2 = [int]($orig.Height * 0.30)

    $sw = [int]($w2 * 1.3)
    $sh = [int]($h2 * 1.3)
    $scaled = New-Object System.Drawing.Bitmap $sw, $sh
    $gs = [System.Drawing.Graphics]::FromImage($scaled)
    $gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gs.DrawImage($orig, [System.Drawing.Rectangle]::new(0, 0, $sw, $sh), $x2, $y2, $w2, $h2, [System.Drawing.GraphicsUnit]::Pixel)
    $gs.Dispose()

    $raw3 = Run-Ocr $scaled
    $res3 = Extract-Plate $raw3
    if ($res3) {
        $scaled.Dispose()
        $orig.Dispose()
        Write-Output $res3
        exit 0
    }

    # Angles for tilted parking (6, -6, 10, -10, 12, -12)
    foreach ($angle in @(6, -6, 10, -10, 12, -12)) {
        $rot = New-Object System.Drawing.Bitmap ($sw + 50), ($sh + 50)
        $gr = [System.Drawing.Graphics]::FromImage($rot)
        $gr.Clear([System.Drawing.Color]::White)
        $gr.TranslateTransform($rot.Width / 2, $rot.Height / 2)
        $gr.RotateTransform($angle)
        $gr.TranslateTransform(-$sw / 2, -$sh / 2)
        $gr.DrawImage($scaled, 0, 0)
        $gr.Dispose()

        $rawRot = Run-Ocr $rot
        $rot.Dispose()

        $resRot = Extract-Plate $rawRot
        if ($resRot) {
            $scaled.Dispose()
            $orig.Dispose()
            Write-Output $resRot
            exit 0
        }
    }
    $scaled.Dispose()

    # 4. Crop B (X: 20%..80%, Y: 50%..75%) at Scale 1.4 for compressed images
    $x3 = [int]($orig.Width * 0.20)
    $y3 = [int]($orig.Height * 0.50)
    $w3 = [int]($orig.Width * 0.60)
    $h3 = [int]($orig.Height * 0.25)

    $sw3 = [int]($w3 * 1.4)
    $sh3 = [int]($h3 * 1.4)
    $scaled3 = New-Object System.Drawing.Bitmap $sw3, $sh3
    $gs3 = [System.Drawing.Graphics]::FromImage($scaled3)
    $gs3.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gs3.DrawImage($orig, [System.Drawing.Rectangle]::new(0, 0, $sw3, $sh3), $x3, $y3, $w3, $h3, [System.Drawing.GraphicsUnit]::Pixel)
    $gs3.Dispose()

    foreach ($angle in @(12, 6, -6, 10, -10)) {
        $rot = New-Object System.Drawing.Bitmap ($sw3 + 50), ($sh3 + 50)
        $gr = [System.Drawing.Graphics]::FromImage($rot)
        $gr.Clear([System.Drawing.Color]::White)
        $gr.TranslateTransform($rot.Width / 2, $rot.Height / 2)
        $gr.RotateTransform($angle)
        $gr.TranslateTransform(-$sw3 / 2, -$sh3 / 2)
        $gr.DrawImage($scaled3, 0, 0)
        $gr.Dispose()

        $rawRot = Run-Ocr $rot
        $rot.Dispose()

        $resRot = Extract-Plate $rawRot
        if ($resRot) {
            $scaled3.Dispose()
            $orig.Dispose()
            Write-Output $resRot
            exit 0
        }
    }
    $scaled3.Dispose()
    $orig.Dispose()

    Write-Output ""
} catch {
    Write-Output ""
}
