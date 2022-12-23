Add-Type -AssemblyName System.Windows.Forms;
#Add-Type -AssemblyName System.Drawing;

$ErrorActionPreference = "Stop"
$Factor = "2"; # TODO Select scale -----------------------------
# Images 2, 4, 8.
# Videos 2, 3.
try {
  function Get-NewFile([IO.FileInfo]$File, [String]$Append){
    return ([IO.FileInfo]($File.Directory.FullName + '\' + $File.BaseName + $Append + $File.Extension));
  }
  function Get-FPS([String]$videoFile){
      $rawFPS = ffprobe -v 0 -of csv=p=0 -select_streams v:0 -show_entries stream=r_frame_rate $videoFile
      $index = $rawFPS.IndexOf('/');
      $subFPS = [Int]$rawFPS.Substring(0, $index);
      $subSEC = [Int]$rawFPS.Substring($index+1, $rawFPS.length - $index-1);
      return ($subFPS / $subSEC);
    }

  Write-Host "Selecting file.."
  $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
      InitialDirectory = [Environment]::GetFolderPath('Desktop')
      Filter = 'Media Files(*.PNG;*.JPG;*.JPEG;*.mp4;*.webm;)|*.PNG;*.JPG;*.JPEG;*.mp4;*.webm;|Image Files(*.PNG;*.JPG;*.JPEG;)|*.PNG;*.JPG;*.JPEG;|Video Files(*.mp4;*.webm;)|*.mp4;*.webm;|All files (*.*)|*.*'
      Title = 'Input'
      Multiselect = $true
  }
  $null = $FileBrowser.ShowDialog();
  echo $FileBrowser
  $FileBrowser.FileNames | foreach {

    $File = ([IO.FileInfo]$_)
    $OutFile = [IO.FileInfo](Get-NewFile -File $File -Append "_${Factor}x");

    Write-Host "Scaling $($File.Name) by ${Factor}x..";

    If ($File.Extension -in @(".PNG", ".JPG", ".JPEG;")) {
      If (!$OutFile.Exists) {
        isr --factor $Factor --input $File.FullName --output $OutFile.FullName | Out-Null;
      }
    } Else {
      $TempFile = [IO.FileInfo](Get-NewFile -File $OutFile -Append "tmp");
      If (!$TempFile.Exists) {
        vsr --factor $Factor --input $File.FullName --output $TempFile.FullName | Out-Null;
      }

      Write-Host "Reading source FPS.."
      $fps = Get-FPS -videoFile $File.FullName;
      $wrongFps = Get-FPS -videoFile $TempFile.FullName;
      $setpts = "setpts=" + ($wrongFps / $fps) + "*PTS";

      Write-Host "Syncing FPS.. [$fps]";
      ffmpeg -i $TempFile.FullName -filter:v $setpts -r:v $fps -loglevel quiet -stats -y $OutFile.FullName | Out-Null;

      Move-Item -Path $OutFile.FullName -Destination $TempFile.FullName -Force

      Write-Host "Applying sound to upscaled video.."
      ffmpeg -i $TempFile.FullName -i $File.FullName -c copy -map 0:0 -map 1:1 -loglevel quiet -stats -y $OutFile.FullName | Out-Null;

      Remove-Item -Path $TempFile.FullName -Force;
    }

    Write-Host "Done!";
    Write-Host "$($File.Name) upscaled by ${Factor}x";
  }
} catch {
    #ls variable:*
    Write-Host $Error[0]
    Read-Host
} finally {
  $FileBrowser.Dispose();
  #Read-Host -Prompt "Press enter to exit..."
}