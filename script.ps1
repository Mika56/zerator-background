try {
    add-type @"
    using System;
    using System.Runtime.InteropServices;
    using Microsoft.Win32;
    namespace Wallpaper
    {
      public enum Style : int
      {
          Tile, Center, Stretch, NoChange, Fit
      }
 
 
      public class Setter {
         public const int SetDesktopWallpaper = 20;
         public const int UpdateIniFile = 0x01;
         public const int SendWinIniChange = 0x02;
 
         [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
         private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
     
         public static void SetWallpaper ( string path, Wallpaper.Style style ) {
            SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
       
            RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
            switch( style )
            {
               case Style.Stretch :
                  key.SetValue(@"WallpaperStyle", "2") ;
                  key.SetValue(@"TileWallpaper", "0") ;
                  break;
               case Style.Center :
                  key.SetValue(@"WallpaperStyle", "1") ;
                  key.SetValue(@"TileWallpaper", "0") ;
                  break;
               case Style.Tile :
                  key.SetValue(@"WallpaperStyle", "1") ;
                  key.SetValue(@"TileWallpaper", "1") ;
                  break;
               case Style.Fit :
                  key.SetValue(@"WallpaperStyle", "6") ;
                  key.SetValue(@"TileWallpaper", "0") ;
                  break;
               case Style.NoChange :
                  break;
            }
            key.Close();
         }
      }
    }
"@
 
    cmdlet Set-Wallpaper {
    Param(
       [Parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
       [Alias("FullName")]
       [string]
       $Path
    ,
       [Parameter(Position=1, Mandatory=$false)]
       [Wallpaper.Style]
       $Style = "NoChange"
    )
       [Wallpaper.Setter]::SetWallpaper( (Convert-Path $Path), $Style )
    }
}
catch {}


$result = Invoke-WebRequest -URI http://zerator.com/wp-json/pages/8
If ($result.StatusCode -ne 200) {
    Write-Host "Status code is {$result.StatusCode}"
    return
}
$content = $result.Content
$parsed = ConvertFrom-Json $content
$outFile = "$env:APPDATA\zerator_bg.jpg"
Invoke-WebRequest -URI $parsed.acf.thumbnail -OutFile $outFile

[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
$i = new-object System.Drawing.Bitmap $outFile
$outFile = "$env:APPDATA\zerator_bg.bmp"
$i.Save($outFile, "BMP")
$i.Dispose()

[Wallpaper.Setter]::SetWallpaper($outFile, [Wallpaper.Style]::Fit)