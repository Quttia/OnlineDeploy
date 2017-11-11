md w:\scratchdir
dism /Apply-Image /ImageFile:%1 /Index:1 /ApplyDir:W:\ /scratchdir:w:\scratchdir
W:\Windows\System32\bcdboot W:\Windows /s S: /f uefi
md R:\Recovery\WindowsRE
::xcopy /h W:\Windows\System32\Recovery\Winre.wim R:\Recovery\WindowsRE\
robocopy C:\Windows\System32\Recovery\ R:\Recovery\WindowsRE\ Winre.wim
W:\Windows\System32\Reagentc /Setreimage /Path R:\Recovery\WindowsRE /Target W:\Windows
W:\Windows\System32\Reagentc /info /Target W:\Windows
