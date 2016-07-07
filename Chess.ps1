#####################################################################################
# Requires PowerShell Version 5.0
#####################################################################################
#                                                      _:_
#     =========================                       '-.-'
#    | PowerShell Chess v0.1.1 |             ()      __.'.__
#     =========================           .-:--:-.  |_______|
#                                  ()      \____/    \=====/
#                                  /\      {====}     )___(
#                       (\=,      //\\      )__(     /_____\
#       __    |'-'-'|  //  .\    (    )    /____\     |   |
#      /  \   |_____| (( \_  \    )__(      |  |      |   |
#      \__/    |===|   ))  `\_)  /____\     |  |      |   |
#     /____\   |   |  (/     \    |  |      |  |      |   |
#      |  |    |   |   | _.-'|    |  |      |  |      |   |
#      |__|    )___(    )___(    /____\    /____\    /_____\
#     (====)  (=====)  (=====)  (======)  (======)  (=======)
#     }===={  }====={  }====={  }======{  }======{  }======={
#    (______)(_______)(_______)(________)(________)(_________)
#################################################################


<#
.SYNOPSIS
    Multiplayer chess game in PowerShell. No AI.

.DESCRIPTION
    Started off of code from https://github.com/bhassen99/POSH-Chess, which was very
much incomplete. I kept the board shape, but have changed everything else.
The unicode chess pieces unfortunately do not render in the base PowerShell console, 
they only appear when run in PowerShell ISE.

.NOTES
    Name: Chess.ps1
    Version: 0.1.0
    Author: Michael Shen
    Date: 07-06-2016

.CHANGELOG
    0.1.0 - Chojiku      - 03-12-2016 - Initial Script
    0.1.1 - faiyafrower  - 07-06-2016 - Overhaul into playable state

.TODO
	- castling logic
	- en passant logic
	- pawn promotion logic
    - Normal chess notation for moves
	- check and checkmate logic
    - Outsource AI to some engine?
#>

#Displays the gameboard
Function Draw-Board {
	#Clear the console
    #Clear-Host

	#Get arrays of all piece that are still alive
    [Array] $CurrentWhite = $WhitePieces | Where {$_.Alive -eq $true}
    [Array] $CurrentBlack = $BlackPieces | Where {$_.Alive -eq $true}
    
	#Place all the white pieces
    ForEach ($pc in $CurrentWhite) {
        $board[($pc.CurrentRow),($pc.CurrentColumn)] = $pc
    }
    #Place all the black pieces
    ForEach ($pc in $CurrentBlack) {
        $board[($pc.CurrentRow),($pc.CurrentColumn)] = $pc
    }

	#Check for spaces without a piece in them, then fill it with the empty placeholder.
    for($r=0; $r -le 7; $r++) {
        for($c=0; $c -le 7; $c++) {
            If ($board[$r,$c] -eq $null) {$board[$r,$c] = $Empty}
        }
    }

    #Draw the board
    Write-Host '     A    B    C   D    E    F   G    H'
    Write-Host '   -------------------------------------- '
    Write-Host ' 8 |'$board[7,0].Icon'|'$board[7,1].Icon'|'$board[7,2].Icon'|'$board[7,3].Icon'|'$board[7,4].Icon'|'$board[7,5].Icon'|'$board[7,6].Icon'|'$board[7,7].Icon'| 8'
    Write-Host '   -------------------------------------- '
    Write-Host ' 7 |'$board[6,0].Icon'|'$board[6,1].Icon'|'$board[6,2].Icon'|'$board[6,3].Icon'|'$board[6,4].Icon'|'$board[6,5].Icon'|'$board[6,6].Icon'|'$board[6,7].Icon'| 7'
    Write-Host '   -------------------------------------- '
    Write-Host ' 6 |'$board[5,0].Icon'|'$board[5,1].Icon'|'$board[5,2].Icon'|'$board[5,3].Icon'|'$board[5,4].Icon'|'$board[5,5].Icon'|'$board[5,6].Icon'|'$board[5,7].Icon'| 6'
    Write-Host '   -------------------------------------- '
    Write-Host ' 5 |'$board[4,0].Icon'|'$board[4,1].Icon'|'$board[4,2].Icon'|'$board[4,3].Icon'|'$board[4,4].Icon'|'$board[4,5].Icon'|'$board[4,6].Icon'|'$board[4,7].Icon'| 5'
    Write-Host '   -------------------------------------- '
    Write-Host ' 4 |'$board[3,0].Icon'|'$board[3,1].Icon'|'$board[3,2].Icon'|'$board[3,3].Icon'|'$board[3,4].Icon'|'$board[3,5].Icon'|'$board[3,6].Icon'|'$board[3,7].Icon'| 4'
    Write-Host '   -------------------------------------- '
    Write-Host ' 3 |'$board[2,0].Icon'|'$board[2,1].Icon'|'$board[2,2].Icon'|'$board[2,3].Icon'|'$board[2,4].Icon'|'$board[2,5].Icon'|'$board[2,6].Icon'|'$board[2,7].Icon'| 3'
    Write-Host '   -------------------------------------- '
    Write-Host ' 2 |'$board[1,0].Icon'|'$board[1,1].Icon'|'$board[1,2].Icon'|'$board[1,3].Icon'|'$board[1,4].Icon'|'$board[1,5].Icon'|'$board[1,6].Icon'|'$board[1,7].Icon'| 2'
    Write-Host '   -------------------------------------- '
    Write-Host ' 1 |'$board[0,0].Icon'|'$board[0,1].Icon'|'$board[0,2].Icon'|'$board[0,3].Icon'|'$board[0,4].Icon'|'$board[0,5].Icon'|'$board[0,6].Icon'|'$board[0,7].Icon'| 1'
    Write-Host '   -------------------------------------- '
    Write-Host '     A    B    C   D    E    F   G    H'

    if ($WhtKng.Alive -eq $false) {
		echo "Black Wins!"
	} elseif ($BlkKng.Alive -eq $false) {
		echo "White Wins!"
	} else {
		#Ask the player what they would like to move
		if($Player1Turn) {
			Try {
				[ValidateScript({$_.Length -eq 2})]$src = Read-Host 'White starting square'
				[Int]$cc = Get-Column $src[0]
				[Int]$cr = Get-Row $src[1]
				[ValidateScript({$_.Color -eq 'White'})]$pc = $board[$cr, $cc]
				[ValidateScript({$_.Length -eq 2})]$dst = Read-Host 'White ending square'
			} Catch {
				Write-Error "Illegal move"
				Draw-Board
				Break
			}
		} Else {
			Try {
				[ValidateScript({$_.Length -eq 2})]$src = Read-Host 'Black starting square'
				[Int]$cc = Get-Column $src[0]
				[Int]$cr = Get-Row $src[1]
				[ValidateScript({$_.Color -eq 'Black'})]$pc = $board[$cr, $cc]
				[ValidateScript({$_.Length -eq 2})]$dst = Read-Host 'Black ending square'
			} Catch {
				Write-Error "Illegal move"
				Draw-Board
				Break
			}
		}

		Move-Piece $src $dst
	}
}

#Used to move pieces on the board
Function Move-Piece {
    Param ([String]$src,[String]$dst)

    [bool]$Attack = $false
    [bool]$MoveSuccess = $false

    Try {
		#Validate input
        [Int]$CurrentColumn = Get-Column $src[0]
        [Int]$CurrentRow = Get-Row $src[1]
        [ValidateRange(0,7)][Int]$DesiredColumn = Get-Column $dst[0]
        [ValidateRange(0,7)][Int]$DesiredRow = Get-Row $dst[1]

        #Get the piece that is in the source space
        $pc = $board[$CurrentRow, $CurrentColumn]

        #Is this the first time that the piece is moving?
        [bool]$firstmove = $pc.CurrentPosition -eq $pc.StartingPosition 
    } Catch {
        #You messed up, try again
        Write-Error "Out of bounds"
        Draw-Board
        Break
    }

    #Moving nothing
    if ($board[$CurrentRow, $CurrentColumn] -eq $Empty) {
        Write-Error "There is nothing there."
		Draw-Board
    }
	#Moving nowhere
    if (($CurrentRow -eq $DesiredRow) -and ($CurrentColumn -eq $DesiredColumn)) {
		Write-Error "That wouldn't move anywhere."
		Draw-Board
    }
	#Moving into another one of your pieces
    if ($board[$DesiredRow, $DesiredColumn] -ne $Empty) {
        if ($pc.Color -eq $board[$DesiredRow, $DesiredColumn].Color) {
			Write-Error "Illegal Move"
			Draw-Board
		}
    }

	#castling logic
	[int]$MoveX = $DesiredColumn - $CurrentColumn
	[int]$MoveY = $DesiredRow - $CurrentRow
    
	#Pieces playable
    switch ($pc.GetType().Name) {
		'Pawn' {
			if ($pc.color -eq 'Black') {
				$MoveX *= -1
				$MoveY *= -1
			}
			$MoveX = [math]::abs($MoveX)
			if ($MoveX -gt 1 -or $MoveY -gt 2 -or $MoveY -le 0) {
				Write-Error "Illegal Move"
			} else {
				if (($MoveX -eq 0) -and ($MoveY -eq 1)) {
					if ($board[$DesiredRow,$DesiredColumn] -ne $Empty) {
						Write-Error "Illegal Move"
					} else {
						$MoveSuccess = $true
						$pc.firstmove = $false
					}
				} elseif (($MoveX -eq 0) -and ($MoveY -eq 2)) {
					if (($pc.firstmove = $true) -and `
						(($board[$DesiredRow, $DesiredColumn] -eq $Empty) -and `
						($board[($DesiredRow + 1), $DesiredColumn] -eq $Empty))) {

						$MoveSuccess = $true
						$pc.firstmove = $false
                        $pc.inpassing = $true
					} else {
						Write-Error "Illegal Move"
					}
				} elseif (($MoveX -eq 1) -and ($MoveY -eq 1)) {
					if ($board[$DesiredRow,$DesiredColumn] -eq $Empty) {
						#en passant logic
						Write-Error "Illegal Move"
					} else {
						$Attack = $true
						$MoveSuccess = $true
						$pc.firstmove = $false
					}
				} else {
					Write-Error "Illegal Move"
				}
			}
		}

        'Rook' {
            if (([math]::abs($MoveX) -gt 0) -and ([math]::abs($MoveY) -gt 0)) {
				Write-Error "Illegal Move"
			} else {
				if ($MoveX -gt 0) {
					for ($i = 1; $i -lt $MoveX; $i++) {
						if ($board[$CurrentRow, ($CurrentColumn + $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
						}
					}
				} elseif ($MoveX -lt 0) {
					for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
						if ($board[$CurrentRow, ($CurrentColumn - $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
						}
					}
				} elseif ($MoveY -gt 0) {
					for ($i = 1; $i -lt $MoveY; $i++) {
						if ($board[($CurrentRow + $i), $CurrentColumn] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
						}
					}
				} else {
					for ($i = 1; $i -lt [math]::abs($MoveY); $i++) {
						if ($board[($CurrentRow - $i), $CurrentColumn] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
						}
					}
				}
				$MoveSuccess = $true
				$pc.firstmove = $false
				if ($board[$DesiredRow, $DesiredColumn] -ne $Empty) {
					$Attack = $true
				}
			}
        }

        'Knight' {
			$MoveX = [math]::abs($MoveX)
			$MoveY = [math]::abs($MoveY)

            if ((($MoveX -eq 1) -and ($MoveY -eq 2)) -or (($MoveX -eq 2) -and ($MoveY -eq 1))) {
                $MoveSuccess = $true
				if ($board[$DesiredRow, $DesiredColumn] -ne $Empty) {
					$Attack = $true
				}
            } else {
                Write-Error "Illegal Move"
            }
        }

        'Bishop' {
			if ([math]::abs($MoveX) -ne [math]::abs($MoveY)) {
				Write-Error "Illegal Move"
			} else {
				if ($MoveX -gt 0) {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentRow + $i) , ($CurrentColumn + $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
							}
						}
					} else {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentRow - $i) , ($CurrentColumn + $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
							}
						}
					}
				} else {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveY; $i++) {
							if ($board[($CurrentRow + $i) , ($CurrentColumn - $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
							}
						}
					} else {
						for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
							if ($board[($CurrentRow - $i) , ($CurrentColumn - $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
							}
						}
					}
				}
				$MoveSuccess = $true
				if ($board[$DesiredRow, $DesiredColumn] -ne $Empty) {
					$Attack = $true
				}
			}
        }

        'King' {
			$MoveX = [math]::abs($MoveX)
			$MoveY = [math]::abs($MoveY)

			#castling logic
            if (($MoveX -eq 1) -or ($MoveY -eq 1)) {
                $MoveSuccess = $true
				if ($board[$DesiredRow, $DesiredColumn] -ne $Empty) {
					$Attack = $true
				}
            } Else {
                Write-Error "Illegal Move"
            }
        }

        'Queen' {
			if ([math]::abs($MoveX) -eq [math]::abs($MoveY)) {
				if ($MoveX -gt 0) {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentRow + $i) , ($CurrentColumn + $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
							}
						}
					} else {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentRow - $i) , ($CurrentColumn + $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
							}
						}
					}
				} else {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveY; $i++) {
							if ($board[($CurrentRow + $i) , ($CurrentColumn - $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
							}
						}
					} else {
						for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
							if ($board[($CurrentRow - $i) , ($CurrentColumn - $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
							}
						}
					}
				}
				$MoveSuccess = $true
				if ($board[$DesiredRow, $DesiredColumn] -ne $Empty) {
					$Attack = $true
				}
			} elseif (($MoveX -ne 0 -and $MoveY -eq 0) -or `
					  ($MoveX -eq 0 -and $MoveY -ne 0)) {
				if ($MoveX -gt 0) {
					for ($i = 1; $i -lt $MoveX; $i++) {
						if ($board[$CurrentRow, ($CurrentColumn + $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
						}
					}
				} elseif ($MoveX -lt 0) {
					for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
						if ($board[$CurrentRow, ($CurrentColumn - $i)] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
						}
					}
				} elseif ($MoveY -gt 0) {
					for ($i = 1; $i -lt $MoveY; $i++) {
						if ($board[($CurrentRow + $i), $CurrentColumn] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
						}
					}
				} else {
					for ($i = 1; $i -lt [math]::abs($MoveY); $i++) {
						if ($board[($CurrentRow - $i), $CurrentColumn] -ne $Empty) {
								Write-Error "Illegal Move"
								Draw-Board
								break
						}
					}
				}
				$MoveSuccess = $true
				if ($board[$DesiredRow, $DesiredColumn] -ne $Empty) {
					$Attack = $true
				}
			} else {
				Write-Error "Illegal Move"
			}
		}
	}

    if ($MoveSuccess) {
		if ($Attack) {
            $board[$DesiredRow,$DesiredColumn].Alive = $false
			$board[$DesiredRow,$DesiredColumn].CurrentPosition = $null
			$board[$DesiredRow,$DesiredColumn].CurrentRow = $null
			$board[$DesiredRow,$DesiredColumn].CurrentColumn = $null
        }
        
        $board[$CurrentRow,$CurrentColumn] = $Empty
        $pc.CurrentPosition = $dst.ToUpper()
        $pc.CurrentRow = $DesiredRow
        $pc.CurrentColumn = $DesiredColumn 
        
        $Player1Turn = (!($Player1Turn))           
    }
    Draw-Board
}

Function Get-Column {
    Param ([String]$Col)
    switch ($Col) {
        "A" {Return "0"}
        "B" {Return "1"}
        "C" {Return "2"}
        "D" {Return "3"}
        "E" {Return "4"}
        "F" {Return "5"}
        "G" {Return "6"}
        "H" {Return "7"}
    }
}

Function Get-Row {
	Param ([string]$row)

	return ($row - 1)
}

###########################
#endregion: Functions
####################################################


####################################################
#region: Classes
###########################

#Gives all classes that inherit(:) this class the base properties
Class ChessPiece {
    [Boolean]$Alive=$true;
    [String]$Icon;
    [String]$Color;
    [String]$StartingPosition;
    [Int]$StartingRow;
    [Int]$StartingColumn;
    [String]$CurrentPosition;
    [ValidateRange(0,7)][Int]$CurrentRow;
    [ValidateRange(0,7)][Int]$CurrentColumn;
}

Class Pawn : ChessPiece {
    [bool]$firstmove = $true
	[bool]$inpassing = $false
    Pawn([String]$Position) {
        $this.StartingPosition = $Position
        $this.StartingRow = Get-Row $Position[1] 
        $this.StartingColumn = Get-Column $Position[0]
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

        If ($(Get-Row $Position[1]) -eq '1') {
            $this.Icon = '♙'
            $this.Color = 'White'
        } ElseIf ($(Get-Row $Position[1]) -eq '6') {
            $this.Icon = '♟'
            $this.Color = 'Black'
        }
    }
}

Class Rook : ChessPiece {
	[bool]$firstmove = $true
    Rook([String]$Position) {
        $this.StartingPosition = $Position
        $this.StartingRow = Get-Row $Position[1] 
        $this.StartingColumn = Get-Column $Position[0]
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

        If ($this.StartingRow -eq '0') {
            $this.Icon = '♖'
            $this.Color = 'White'
        } ElseIf ($this.StartingRow -eq '7') {
            $this.Icon = '♜'
            $this.Color = 'Black'
        }
    }
}

Class Knight : ChessPiece {
    Knight([String]$Position) {
        $this.StartingPosition = $Position
        $this.StartingRow = Get-Row $Position[1] 
        $this.StartingColumn = Get-Column $Position[0]
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

        If ($this.StartingRow -eq '0') {
            $this.Icon = '♘'
            $this.Color = 'White'
        } ElseIf ($this.StartingRow -eq '7') {
            $this.Icon = '♞'
            $this.Color = 'Black'
        }
    }
}

Class Bishop : ChessPiece {
    Bishop([String]$Position) {
        $this.StartingPosition = $Position
        $this.StartingRow = Get-Row $Position[1] 
        $this.StartingColumn = Get-Column $Position[0]
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

        If ($this.StartingRow -eq '0') {
            $this.Icon = '♗'
            $this.Color = 'White'
        } ElseIf ($this.StartingRow -eq '7') {
            $this.Icon = '♝'
            $this.Color = 'Black'
        }
    }
}

Class Queen : ChessPiece {
    Queen([String]$Position) {
        $this.StartingPosition = $Position
        $this.StartingRow = Get-Row $Position[1] 
        $this.StartingColumn = Get-Column $Position[0]
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

        If ($this.StartingRow -eq '0') {
            $this.Icon = '♕'
            $this.Color = 'White'
        } ElseIf ($this.StartingRow -eq '7') {
            $this.Icon = '♛'
            $this.Color = 'Black'
        }
    }
}

Class King : ChessPiece {
	[bool]$firstmove = $true
	King([String]$Position) {
        $this.StartingPosition = $Position
        $this.StartingRow = Get-Row $Position[1] 
        $this.StartingColumn = Get-Column $Position[0]
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

        If ($this.StartingRow -eq '0') {
            $this.Icon = '♔'
            $this.Color = 'White'
        } ElseIf ($this.StartingRow -eq '7') {
            $this.Icon = '♚'
            $this.Color = 'Black'
        }
    }
}

Class Blank {
    [String]$Icon='     '
}

###########################
#endregion: Classes
####################################################

#Creates the game board
[Object]$Script:board = New-Object 'object[,]' 8,8

#Creates a turn status
[bool]$Script:Player1Turn = $true

$WhtPwn1 = [Pawn]::New('A2');$WhtPwn2 = [Pawn]::New('B2');$WhtPwn3 = [Pawn]::New('C2');$WhtPwn4 = [Pawn]::New('D2');
$WhtPwn5 = [Pawn]::New('E2');$WhtPwn6 = [Pawn]::New('F2');$WhtPwn7 = [Pawn]::New('G2');$WhtPwn8 = [Pawn]::New('H2');
$WhtRk1 = [Rook]::New('A1');$WhtRk2 = [Rook]::New('H1');$whtKnght1 = [Knight]::New('B1');$whtKnght2 = [Knight]::New('G1');
$WhtBshp1 = [Bishop]::New('C1');$WhtBshp2 = [Bishop]::New('F1');$WhtQn = [Queen]::New('D1');$WhtKng = [King]::New('E1')

$BlkPwn1 = [Pawn]::New('A7');$BlkPwn2 = [Pawn]::New('B7');$BlkPwn3 = [Pawn]::New('C7');$BlkPwn4 = [Pawn]::New('D7');
$BlkPwn5 = [Pawn]::New('E7');$BlkPwn6 = [Pawn]::New('F7');$BlkPwn7 = [Pawn]::New('G7');$BlkPwn8 = [Pawn]::New('H7');
$BlkRk1 = [Rook]::New('A8');$BlkRk2 = [Rook]::New('H8');$BlkKnght1 = [Knight]::New('B8');$BlkKnght2 = [Knight]::New('G8');
$BlkBshp1 = [Bishop]::New('C8');$BlkBshp2 = [Bishop]::New('F8');$BlkQn = [Queen]::New('D8');$BlkKng = [King]::New('E8')

$Empty = [Blank]::New()

[Array] $Script:WhitePieces = @(
    $WhtPwn1,$WhtPwn2,$WhtPwn3,$WhtPwn4,
    $WhtPwn5,$WhtPwn6,$WhtPwn7,$WhtPwn8,
    $WhtRk1,$WhtRk2,$whtKnght1,$whtKnght2,
    $WhtBshp1,$WhtBshp2,$WhtQn,$WhtKng
)

[Array] $Script:BlackPieces = @(
    $BlkPwn1,$BlkPwn2,$BlkPwn3,$BlkPwn4,
    $BlkPwn5,$BlkPwn6,$BlkPwn7,$BlkPwn8,
    $BlkRk1,$BlkRk2,$BlkKnght1,$BlkKnght2,
    $BlkBshp1,$BlkBshp2,$BlkQn,$BlkKng
)

Draw-Board