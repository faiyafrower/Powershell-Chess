#####################################################################################
# Requires PowerShell Version 5.0
#####################################################################################
#                                                      _:_
#     =========================                       '-.-'
#    | PowerShell Chess v0.1.4 |             ()      __.'.__
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
    Version: 0.1.4
    Author: Michael Shen
    Date: 07-08-2016

.CHANGELOG
    0.1.0 - Chojiku      - 03-12-2016 - Initial Script
    0.1.1 - Michael Shen - 07-06-2016 - Overhaul into playable state
	0.1.2 - Michael Shen - 07-07-2016 - Castling
	0.1.3 - Michael Shen - 07-07-2016 - en passant
	0.1.4 - Michael Shen - 07-08-2016 - Pawn promotion

.TODO
    - Normal chess notation for moves
	- Check logic
	- Checkmate logic
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
    foreach ($pc in $CurrentWhite) {
        $board[($pc.CurrentColumn),($pc.CurrentRow)] = $pc
    }
    #Place all the black pieces
    foreach ($pc in $CurrentBlack) {
        $board[($pc.CurrentColumn),($pc.CurrentRow)] = $pc
    }

	#Check for spaces without a piece in them, then fill it with the empty placeholder.
    for ($i = 0; $i -le 7; $i++) {
        for ($j = 0; $j -le 7; $j++) {
            if ($board[$i, $j] -eq $null) {
				$board[$i, $j] = $Empty
			}
        }
    }

    #Draw the board
    Write-Host '     A    B    C   D    E    F   G    H'
    Write-Host '   -------------------------------------- '
    Write-Host ' 8 |'$board[0,7].Icon'|'$board[1,7].Icon'|'$board[2,7].Icon'|'$board[3,7].Icon'|'$board[4,7].Icon'|'$board[5,7].Icon'|'$board[6,7].Icon'|'$board[7,7].Icon'| 8'
    Write-Host '   -------------------------------------- '
    Write-Host ' 7 |'$board[0,6].Icon'|'$board[1,6].Icon'|'$board[2,6].Icon'|'$board[3,6].Icon'|'$board[4,6].Icon'|'$board[5,6].Icon'|'$board[6,6].Icon'|'$board[7,6].Icon'| 7'
    Write-Host '   -------------------------------------- '
    Write-Host ' 6 |'$board[0,5].Icon'|'$board[1,5].Icon'|'$board[2,5].Icon'|'$board[3,5].Icon'|'$board[4,5].Icon'|'$board[5,5].Icon'|'$board[6,5].Icon'|'$board[7,5].Icon'| 6'
    Write-Host '   -------------------------------------- '
    Write-Host ' 5 |'$board[0,4].Icon'|'$board[1,4].Icon'|'$board[2,4].Icon'|'$board[3,4].Icon'|'$board[4,4].Icon'|'$board[5,4].Icon'|'$board[6,4].Icon'|'$board[7,4].Icon'| 5'
    Write-Host '   -------------------------------------- '
    Write-Host ' 4 |'$board[0,3].Icon'|'$board[1,3].Icon'|'$board[2,3].Icon'|'$board[3,3].Icon'|'$board[4,3].Icon'|'$board[5,3].Icon'|'$board[6,3].Icon'|'$board[7,3].Icon'| 4'
    Write-Host '   -------------------------------------- '
    Write-Host ' 3 |'$board[0,2].Icon'|'$board[1,2].Icon'|'$board[2,2].Icon'|'$board[3,2].Icon'|'$board[4,2].Icon'|'$board[5,2].Icon'|'$board[6,2].Icon'|'$board[7,2].Icon'| 3'
    Write-Host '   -------------------------------------- '
    Write-Host ' 2 |'$board[0,1].Icon'|'$board[1,1].Icon'|'$board[2,1].Icon'|'$board[3,1].Icon'|'$board[4,1].Icon'|'$board[5,1].Icon'|'$board[6,1].Icon'|'$board[7,1].Icon'| 2'
    Write-Host '   -------------------------------------- '
    Write-Host ' 1 |'$board[0,0].Icon'|'$board[1,0].Icon'|'$board[2,0].Icon'|'$board[3,0].Icon'|'$board[4,0].Icon'|'$board[5,0].Icon'|'$board[6,0].Icon'|'$board[7,0].Icon'| 1'
    Write-Host '   -------------------------------------- '
    Write-Host '     A    B    C   D    E    F   G    H'

    if ($wK.Alive -eq $false) {
		echo "Black Wins!"
	} elseif ($bK.Alive -eq $false) {
		echo "White Wins!"
	} else {
		#Ask the player what they would like to move
		if($Player1Turn) {
			Try {
				[ValidateScript({$_.Length -eq 2})]$src = Read-Host 'White starting square'
				[Int]$cc = Get-Column $src[0]
				[Int]$cr = Get-Row $src[1]
				[ValidateScript({$_.Color -eq 'White'})]$pc = $board[$cc, $cr]
				[ValidateScript({$_.Length -eq 2})]$dst = Read-Host 'White ending square'
			} Catch {
				Write-Error "Illegal white move"
				Draw-Board
				Break
			}
		} else {
			Try {
				[ValidateScript({$_.Length -eq 2})]$src = Read-Host 'Black starting square'
				[Int]$cc = Get-Column $src[0]
				[Int]$cr = Get-Row $src[1]
				[ValidateScript({$_.Color -eq 'Black'})]$pc = $board[$cc, $cr]
				[ValidateScript({$_.Length -eq 2})]$dst = Read-Host 'Black ending square'
			} Catch {
				Write-Error "Illegal black move"
				Draw-Board
				Break
			}
		}

		Move-Piece $src $dst
	}
}

#Used to move pieces on the board
Function Move-Piece {
    param ([string]$src, [string]$dst)

    [bool]$Attack = $false
    [bool]$MoveSuccess = $false

	try {
        [Int]$CurrentColumn = Get-Column $src[0]
        [Int]$CurrentRow = Get-Row $src[1]
        [Int]$DesiredColumn = Get-Column $dst[0]
        [Int]$DesiredRow = Get-Row $dst[1]

        $pc = $board[$CurrentColumn, $CurrentRow]
    } catch {
        Write-Error "Out of bounds"
        Draw-Board
        break
    }

	#Moving nothing
    if ($board[$CurrentColumn, $CurrentRow] -eq $Empty) {
        Write-Error "There is nothing there."
		Draw-Board
    }
	#Moving nowhere
    if (($CurrentRow -eq $DesiredRow) -and ($CurrentColumn -eq $DesiredColumn)) {
		Write-Error "That wouldn't move anywhere."
		Draw-Board
    }
	#Moving into another one of your pieces
    if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
        if ($pc.Color -eq $board[$DesiredColumn, $DesiredRow].Color) {
			Write-Error "Collision with own team"
			Draw-Board
        }
    }

	[int]$MoveX = $DesiredColumn - $CurrentColumn
	[int]$MoveY = $DesiredRow - $CurrentRow

	#Pieces playable
    switch ($pc.GetType().Name) {
		'Pawn' {
			$MoveX = [math]::abs($MoveX)
			if (($MoveX -gt 1) -or ([math]::abs($MoveY) -gt 2)) {
				Write-Error "Illegal Pawn Move"
			} else {
				#Force pawns to only move "forward"
				if ($pc.Color -eq 'Black') {
					$MoveY *= -1
				}
				if (($MoveX -eq 0) -and ($MoveY -eq 1)) {
					if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
						Write-Error "Illegal Pawn Move 1"
					} else {
						$MoveSuccess = $true
						$pc.firstmove = $false
					}
				} elseif (($MoveX -eq 0) -and ($MoveY -eq 2)) {
					if (($pc.firstmove = $true) -and `
						(($board[$DesiredColumn, $DesiredRow] -eq $Empty) -and `
						($board[($DesiredColumn + 1), $DesiredRow] -eq $Empty))) {

						$MoveSuccess = $true
						$pc.firstmove = $false
                        $pc.inpassing = $turncounter
					} else {
						Write-Error "Illegal Pawn Move 2"
					}
				} elseif (($MoveX -eq 1) -and ($MoveY -eq 1)) {
					if ($board[$DesiredColumn, $DesiredRow] -eq $Empty) {
						$enpassant = $board[$CurrentColumn, $DesiredRow]
						if (($enpassant.GetType().Name -eq 'Pawn') -and `
							($pc.Color -ne $enpassant.Color) -and `
							($enpassant.inpassing -eq ($turncounter - 1))) {
							
							$MoveSuccess = $true
							$board[$CurrentColumn, $DesiredRow] = $Empty
							$enpassant.Alive = $false
							$enpassant.CurrentPosition = $null
							$enpassant.CurrentRow = $null
							$enpassant.CurrentColumn = $null
						} else {
							Write-Error 'Cannot capture en passant'
						}
					} else {
						$Attack = $true
						$MoveSuccess = $true
						$pc.firstmove = $false
					}
				} else {
					Write-Error "Illegal Pawn Move"
				}
			}
		}

        'Knight' {
			$MoveX = [math]::abs($MoveX)
			$MoveY = [math]::abs($MoveY)

            if ((($MoveX -eq 1) -and ($MoveY -eq 2)) -or (($MoveX -eq 2) -and ($MoveY -eq 1))) {
                $MoveSuccess = $true
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Attack = $true
				}
            } else {
                Write-Error "Illegal Knight Move"
            }
        }

        'Bishop' {
			if ([math]::abs($MoveX) -ne [math]::abs($MoveY)) {
				Write-Error "Illegal Bishop Move"
			} else {
				if ($MoveX -gt 0) {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentColumn + $i) , ($CurrentRow + $i)] -ne $Empty) {
								Write-Error "Illegal Bishop Move"
								Draw-Board
								break
							}
						}
					} else {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentColumn + $i) , ($CurrentRow - $i)] -ne $Empty) {
								Write-Error "Illegal Bishop Move"
								Draw-Board
								break
							}
						}
					}
				} else {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveY; $i++) {
							if ($board[($CurrentColumn - $i) , ($CurrentRow + $i)] -ne $Empty) {
								Write-Error "Illegal Bishop Move"
								Draw-Board
								break
							}
						}
					} else {
						for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
							if ($board[($CurrentColumn - $i) , ($CurrentRow - $i)] -ne $Empty) {
								Write-Error "Illegal Bishop Move"
								Draw-Board
								break
							}
						}
					}
				}
				$MoveSuccess = $true
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Attack = $true
				}
			}
        }

		'Rook' {
            if (([math]::abs($MoveX) -gt 0) -and ([math]::abs($MoveY) -gt 0)) {
				Write-Error "Illegal Rook Move"
			} else {
				if ($MoveX -gt 0) {
					for ($i = 1; $i -lt $MoveX; $i++) {
						if ($board[($CurrentColumn + $i), $CurrentRow] -ne $Empty) {
								Write-Error "Illegal Rook Move"
								Draw-Board
								break
						}
					}
				} elseif ($MoveX -lt 0) {
					for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
						if ($board[($CurrentColumn - $i), $CurrentRow] -ne $Empty) {
								Write-Error "Illegal Rook Move"
								Draw-Board
								break
						}
					}
				} elseif ($MoveY -gt 0) {
					for ($i = 1; $i -lt $MoveY; $i++) {
						if ($board[$CurrentColumn, ($CurrentRow + $i)] -ne $Empty) {
								Write-Error "Illegal Rook Move"
								Draw-Board
								break
						}
					}
				} else {
					for ($i = 1; $i -lt [math]::abs($MoveY); $i++) {
						if ($board[$CurrentColumn, ($CurrentRow - $i)] -ne $Empty) {
								Write-Error "Illegal Rook Move"
								Draw-Board
								break
						}
					}
				}
				$MoveSuccess = $true
				$pc.firstmove = $false
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Attack = $true
				}
			}
        }

        'King' {
			$MoveX = [math]::abs($MoveX)
			$MoveY = [math]::abs($MoveY)

            if (($MoveX -eq 1) -or ($MoveY -eq 1)) {
                $MoveSuccess = $true
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Attack = $true
				}
            } elseif (($pc.firstmove -eq $true) -and `
                      ($pc.color -eq 'White')) {
                if (($dst -eq 'G1') -and `
                    ($wHR.firstmove -eq $true)) {
                    
                    $Crk = $board[7, 0]
                    $board[7, 0] = $Empty
                    $Crk.CurrentPosition = 'F1'
                    $Crk.CurrentRow = 0
                    $Crk.CurrentColumn = 5
                    $Crk.firstmove = $false

                    $MoveSuccess = $true
                    $pc.firstmove = $false
                } elseif (($dst -eq 'C1') -and `
                          ($wAR.firstmove -eq $true)) {
                    
                    $Crk = $board[0, 0]
                    $board[0, 0] = $Empty
                    $Crk.CurrentPosition = 'D1'
                    $Crk.CurrentRow = 0
                    $Crk.CurrentColumn = 3
                    $Crk.firstmove = $false

                    $MoveSuccess = $true
                    $pc.firstmove = $false
                }
            } elseif (($pc.firstmove -eq $true) -and `
                      ($pc.color -eq 'Black')) {
                if (($dst -eq 'G8') -and `
                    ($bHR.firstmove -eq $true)) {
                    
                    $Crk = $board[7, 7]
                    $board[7, 7] = $Empty
                    $Crk.CurrentPosition = 'F8'
                    $Crk.CurrentRow = 7
                    $Crk.CurrentColumn = 5
                    $Crk.firstmove = $false

                    $MoveSuccess = $true
                    $pc.firstmove = $false
                } elseif (($dst -eq 'C8') -and `
                          ($bAR.firstmove -eq $true)) {
                    
                    $Crk = $board[0, 7]
                    $board[0, 7] = $Empty
                    $Crk.CurrentPosition = 'D8'
                    $Crk.CurrentRow = 7
                    $Crk.CurrentColumn = 3
                    $Crk.firstmove = $false

                    $MoveSuccess = $true
                    $pc.firstmove = $false
                }
            } else {
                Write-Error "Illegal King Move"
            }
        }

        'Queen' {
			if ([math]::abs($MoveX) -eq [math]::abs($MoveY)) {
				if ($MoveX -gt 0) {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentColumn + $i) , ($CurrentRow + $i)] -ne $Empty) {
								Write-Error "Illegal Queen Move"
								Draw-Board
								break
							}
						}
					} else {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentColumn + $i) , ($CurrentRow - $i)] -ne $Empty) {
								Write-Error "Illegal Queen Move"
								Draw-Board
								break
							}
						}
					}
				} else {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveY; $i++) {
							if ($board[($CurrentColumn - $i), ($CurrentRow + $i)] -ne $Empty) {
								Write-Error "Illegal Queen Move"
								Draw-Board
								break
							}
						}
					} else {
						for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
							if ($board[($CurrentColumn - $i) , ($CurrentRow - $i)] -ne $Empty) {
								Write-Error "Illegal Queen Move"
								Draw-Board
								break
							}
						}
					}
				}
				$MoveSuccess = $true
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Attack = $true
				}
			} elseif (($MoveX -ne 0 -and $MoveY -eq 0) -or `
					  ($MoveX -eq 0 -and $MoveY -ne 0)) {
				if ($MoveX -gt 0) {
					for ($i = 1; $i -lt $MoveX; $i++) {
						if ($board[($CurrentColumn + $i), $CurrentRow] -ne $Empty) {
								Write-Error "Illegal Queen Move"
								Draw-Board
								break
						}
					}
				} elseif ($MoveX -lt 0) {
					for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
						if ($board[($CurrentColumn - $i), $CurrentRow] -ne $Empty) {
								Write-Error "Illegal Queen Move"
								Draw-Board
								break
						}
					}
				} elseif ($MoveY -gt 0) {
					for ($i = 1; $i -lt $MoveY; $i++) {
						if ($board[$CurrentColumn, ($CurrentRow + $i)] -ne $Empty) {
								Write-Error "Illegal Queen Move"
								Draw-Board
								break
						}
					}
				} else {
					for ($i = 1; $i -lt [math]::abs($MoveY); $i++) {
						if ($board[$CurrentColumn, ($CurrentRow - $i)] -ne $Empty) {
								Write-Error "Illegal Queen Move"
								Draw-Board
								break
						}
					}
				}
				$MoveSuccess = $true
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Attack = $true
				}
			} else {
				Write-Error "Illegal Queen Move"
			}
		}
	}

    if ($MoveSuccess) {
		if ($Player1Turn) {
			$logstring = [string](($turncounter / 2) + 1) + " " + $pc.Icon
		} else {
			$logstring += $pc.Icon
		}

		if ($Attack) {
            $board[$DesiredColumn, $DesiredRow].Alive = $false
			$board[$DesiredColumn, $DesiredRow].CurrentPosition = $null
			$board[$DesiredColumn, $DesiredRow].CurrentRow = $null
			$board[$DesiredColumn, $DesiredRow].CurrentColumn = $null

			$logstring += 'x'
        }
        
        $board[$CurrentColumn, $CurrentRow] = $Empty
		$pc.CurrentPosition = $dst.ToUpper()
		$pc.CurrentRow = $DesiredRow
		$pc.CurrentColumn = $DesiredColumn

		#Pawn Promotion
		if (($pc.GetType().Name -eq 'Pawn') -and ($DesiredRow -eq 0)) {
			[ValidateSet('Knight', 'Bishop', 'Rook', 'Queen')]$ptype = Read-Host 'Promote black pawn to'
			
			$pc.Type = $ptype
			switch ($ptype) {
				'Knight' {$pc.Icon = '♞'}
				'Bishop' {$pc.Icon = '♝'}
				'Rook' {$pc.Icon = '♜'}
				'Queen' {$pc.Icon = '♛'}
			}
		} elseif (($pc.GetType().Name -eq 'Pawn') -and ($DesiredRow -eq 7)) {
			[ValidateSet('Knight', 'Bishop', 'Rook', 'Queen')]$ptype = Read-Host 'Promote white pawn to'
			
			$pc.Type = $ptype
			switch ($ptype) {
				'Knight' {$pc.Icon = '♘'}
				'Bishop' {$pc.Icon = '♗'}
				'Rook' {$pc.Icon = '♖'}
				'Queen' {$pc.Icon = '♕'}
			}
		}
        
		#Get arrays of all piece that are still alive
		[Array] $CurrentWhite = $WhitePieces | Where {$_.Alive -eq $true}
		[Array] $CurrentBlack = $BlackPieces | Where {$_.Alive -eq $true}
    
		#Place all the white pieces
		foreach ($pc in $CurrentWhite) {
			$board[($pc.CurrentColumn),($pc.CurrentRow)] = $pc
		}
		#Place all the black pieces
		foreach ($pc in $CurrentBlack) {
			$board[($pc.CurrentColumn),($pc.CurrentRow)] = $pc
		}

		#Check for spaces without a piece in them, then fill it with the empty placeholder.
		for ($i = 0; $i -le 7; $i++) {
			for ($j = 0; $j -le 7; $j++) {
				if ($board[$i, $j] -eq $null) {
					$board[$i, $j] = $Empty
				}
			}
		}

		$logstring += $dst

		if ($Player1Turn) {
			foreach ($pc in $CurrentWhite) {
				if ($(Check-Validmove $pc.CurrentPosition $bK.CurrentPosition)[0] -eq $true) {
					Write-Host 'Check'
					$logstring += '+'
					break
				}
			}
			$logstring += "`t`t"
		} else {
			foreach ($pc in $CurrentBlack) {
				if ($(Check-Validmove $pc.CurrentPosition $wK.CurrentPosition)[0] -eq $true) {
					Write-Host 'Check'
					$logstring += '+'
					break
				}
			}
			Add-Content -Encoding Unicode $logpath $logstring 
		}

		$turncounter += 1
        $Player1Turn = (!($Player1Turn))           
    }

    Draw-Board
}

Function Check-Validmove {
    param ([string]$src, [string]$dst)

    [bool]$Attack = $false
    [bool]$MoveSuccess = $false
	[bool[]]$Status = @($MoveSuccess, $Attack)

    try {
        [Int]$CurrentColumn = Get-Column $src[0]
        [Int]$CurrentRow = Get-Row $src[1]
        [Int]$DesiredColumn = Get-Column $dst[0]
        [Int]$DesiredRow = Get-Row $dst[1]

        $pc = $board[$CurrentColumn, $CurrentRow]
    } catch {
        Write-Error "Out of bounds"
        Draw-Board
        break
    }

	#Moving nothing
    if ($board[$CurrentColumn, $CurrentRow] -eq $Empty) {
        Write-Error "There is nothing there."
		Draw-Board
    }
	#Moving nowhere
    if (($CurrentRow -eq $DesiredRow) -and ($CurrentColumn -eq $DesiredColumn)) {
		Write-Error "That wouldn't move anywhere."
		Draw-Board
    }
	#Moving into another one of your pieces
    if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
        if ($pc.Color -eq $board[$DesiredColumn, $DesiredRow].Color) {
			Write-Error "Collision with own team"
			Draw-Board
        }
    }

	[int]$MoveX = $DesiredColumn - $CurrentColumn
	[int]$MoveY = $DesiredRow - $CurrentRow
    
	#Pieces playable
    switch ($pc.Type) {
        'Pawn' {
			$MoveX = [math]::abs($MoveX)
			if (($MoveX -gt 1) -or ([math]::abs($MoveY) -gt 2)) {
				return $Status
			} else {
				#Force pawns to only move "forward"
				if ($pc.Color -eq 'Black') {
					$MoveY *= -1
				}
				if (($MoveX -eq 0) -and ($MoveY -eq 1)) {
					if ($board[$DesiredColumn,$DesiredRow] -ne $Empty) {
						return $Status
					} else {
						$Status[0] = $true
						$pc.firstmove = $false
					}
				} elseif (($MoveX -eq 0) -and ($MoveY -eq 2)) {
					if (($pc.firstmove = $true) -and `
						(($board[$DesiredColumn, $DesiredRow] -eq $Empty) -and `
						($board[($DesiredColumn + 1), $DesiredRow] -eq $Empty))) {

						$Status[0] = $true
						$pc.firstmove = $false
                        $pc.inpassing = $turncounter
					} else {
						return $Status
					}
				} elseif (($MoveX -eq 1) -and ($MoveY -eq 1)) {
					if ($board[$DesiredColumn,$DesiredRow] -eq $Empty) {
						$enpassant = $board[$CurrentColumn, $DesiredRow]
						if (($enpassant.GetType().Name -eq 'Pawn') -and `
							($pc.Color -ne $enpassant.Color) -and `
							($enpassant.inpassing -eq ($turncounter - 1))) {
							
							$Status[0] = $true
							$board[$CurrentColumn, $DesiredRow] = $Empty
							$enpassant.Alive = $false
							$enpassant.CurrentPosition = $null
							$enpassant.CurrentRow = $null
							$enpassant.CurrentColumn = $null
						} else {
							return $Status
						}
					} else {
						$Status[1] = $true
						$Status[0] = $true
						$pc.firstmove = $false
					}
				} else {
					return $Status
				}
			}
		}

        'Knight' {
			$MoveX = [math]::abs($MoveX)
			$MoveY = [math]::abs($MoveY)

            if ((($MoveX -eq 1) -and ($MoveY -eq 2)) -or (($MoveX -eq 2) -and ($MoveY -eq 1))) {
                $Status[0] = $true
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Status[1] = $true
				}
            } else {
                return $Status
            }
        }

        'Bishop' {
			if ([math]::abs($MoveX) -ne [math]::abs($MoveY)) {
				return $Status
			} else {
				if ($MoveX -gt 0) {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentColumn + $i) , ($CurrentRow + $i)] -ne $Empty) {
								return $Status
							}
						}
					} else {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentColumn + $i) , ($CurrentRow - $i)] -ne $Empty) {
								return $Status
							}
						}
					}
				} else {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveY; $i++) {
							if ($board[($CurrentColumn - $i) , ($CurrentRow + $i)] -ne $Empty) {
								return $Status
							}
						}
					} else {
						for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
							if ($board[($CurrentColumn - $i) , ($CurrentRow - $i)] -ne $Empty) {
								return $Status
							}
						}
					}
				}
				$Status[0] = $true
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Status[1] = $true
				}
			}
        }

		'Rook' {
            if (([math]::abs($MoveX) -gt 0) -and ([math]::abs($MoveY) -gt 0)) {
				return $Status
			} else {
				if ($MoveX -gt 0) {
					for ($i = 1; $i -lt $MoveX; $i++) {
						if ($board[($CurrentColumn + $i), $CurrentRow] -ne $Empty) {
								return $Status
						}
					}
				} elseif ($MoveX -lt 0) {
					for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
						if ($board[($CurrentColumn - $i), $CurrentRow] -ne $Empty) {
								return $Status
						}
					}
				} elseif ($MoveY -gt 0) {
					for ($i = 1; $i -lt $MoveY; $i++) {
						if ($board[$CurrentColumn, ($CurrentRow + $i)] -ne $Empty) {
								return $Status
						}
					}
				} else {
					for ($i = 1; $i -lt [math]::abs($MoveY); $i++) {
						if ($board[$CurrentColumn, ($CurrentRow - $i)] -ne $Empty) {
								return $Status
						}
					}
				}
				$Status[0] = $true
				$pc.firstmove = $false
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Status[1] = $true
				}
			}
        }

		'Queen' {
			if ([math]::abs($MoveX) -eq [math]::abs($MoveY)) {
				if ($MoveX -gt 0) {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentColumn + $i) , ($CurrentRow + $i)] -ne $Empty) {
								return $Status
							}
						}
					} else {
						for ($i = 1; $i -lt $MoveX; $i++) {
							if ($board[($CurrentColumn + $i) , ($CurrentRow - $i)] -ne $Empty) {
								return $Status
							}
						}
					}
				} else {
					if ($MoveY -gt 0) {
						for ($i = 1; $i -lt $MoveY; $i++) {
							if ($board[($CurrentColumn - $i), ($CurrentRow + $i)] -ne $Empty) {
								return $Status
							}
						}
					} else {
						for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
							if ($board[($CurrentColumn - $i) , ($CurrentRow - $i)] -ne $Empty) {
								return $Status
							}
						}
					}
				}
				$Status[0] = $true
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Status[1] = $true
				}
			} elseif (($MoveX -ne 0 -and $MoveY -eq 0) -or `
					  ($MoveX -eq 0 -and $MoveY -ne 0)) {
				if ($MoveX -gt 0) {
					for ($i = 1; $i -lt $MoveX; $i++) {
						if ($board[($CurrentColumn + $i), $CurrentRow] -ne $Empty) {
								return $Status
						}
					}
				} elseif ($MoveX -lt 0) {
					for ($i = 1; $i -lt [math]::abs($MoveX); $i++) {
						if ($board[($CurrentColumn - $i), $CurrentRow] -ne $Empty) {
								return $Status
						}
					}
				} elseif ($MoveY -gt 0) {
					for ($i = 1; $i -lt $MoveY; $i++) {
						if ($board[$CurrentColumn, ($CurrentRow + $i)] -ne $Empty) {
								return $Status
						}
					}
				} else {
					for ($i = 1; $i -lt [math]::abs($MoveY); $i++) {
						if ($board[$CurrentColumn, ($CurrentRow - $i)] -ne $Empty) {
								return $Status
						}
					}
				}
				$Status[0] = $true
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Status[1] = $true
				}
			} else {
				return $Status
			}
		}

        'King' {
			$MoveX = [math]::abs($MoveX)
			$MoveY = [math]::abs($MoveY)

            if (($MoveX -le 1) -and ($MoveY -le 1)) {
                $Status[0] = $true
				if ($board[$DesiredColumn, $DesiredRow] -ne $Empty) {
					$Status[1] = $true
				}
            } elseif (($pc.firstmove -eq $true) -and `
                      ($pc.color -eq 'White')) {
                if (($dst -eq 'G1') -and `
                    ($wHR.firstmove -eq $true)) {
                    
                    $Crk = $board[7, 0]
                    $board[7, 0] = $Empty
                    $Crk.CurrentPosition = 'F1'
                    $Crk.CurrentRow = 0
                    $Crk.CurrentColumn = 5
                    $Crk.firstmove = $false

                    $Status[0] = $true
                    $pc.firstmove = $false
                } elseif (($dst -eq 'C1') -and `
                          ($wAR.firstmove -eq $true)) {
                    
                    $Crk = $board[0, 0]
                    $board[0, 0] = $Empty
                    $Crk.CurrentPosition = 'D1'
                    $Crk.CurrentRow = 0
                    $Crk.CurrentColumn = 3
                    $Crk.firstmove = $false

                    $Status[0] = $true
                    $pc.firstmove = $false
                }
            } elseif (($pc.firstmove -eq $true) -and `
                      ($pc.color -eq 'Black')) {
                if (($dst -eq 'G8') -and `
                    ($bHR.firstmove -eq $true)) {
                    
                    $Crk = $board[7, 7]
                    $board[7, 7] = $Empty
                    $Crk.CurrentPosition = 'F8'
                    $Crk.CurrentRow = 7
                    $Crk.CurrentColumn = 5
                    $Crk.firstmove = $false

                    $Status[0] = $true
                    $pc.firstmove = $false
                } elseif (($dst -eq 'C8') -and `
                          ($bAR.firstmove -eq $true)) {
                    
                    $Crk = $board[0, 7]
                    $board[0, 7] = $Empty
                    $Crk.CurrentPosition = 'D8'
                    $Crk.CurrentRow = 7
                    $Crk.CurrentColumn = 3
                    $Crk.firstmove = $false

                    $Status[0] = $true
                    $pc.firstmove = $false
                }
            } else {
                return $Status
            }
        }
	}

    return $Status
}

Function Get-Column {
    param ([ValidatePattern('[A-H]')][string]$Col)
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
	param ([ValidateRange(1,8)][string]$row)

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
    [bool]$Alive=$true
	[string]$Type
    [string]$Icon
    [ValidateSet('White', 'Black')][String]$Color
    [String]$CurrentPosition
    [ValidateRange(0,7)][Int]$CurrentRow
    [ValidateRange(0,7)][Int]$CurrentColumn
}

Class Pawn : ChessPiece {
    [bool]$firstmove = $true
	[int]$inpassing = 0
	[string]$Type = $this.GetType().Name
    Pawn([string]$Position, [string]$color) {
        $this.Color = $color
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

        if ($color -eq 'White') {
            $this.Icon = '♙'
        } elseif ($color -eq 'Black') {
            $this.Icon = '♟'
        }
    }
}

Class Rook : ChessPiece {
	[bool]$firstmove = $true
	[string]$Type = $this.GetType().Name
    Rook([string]$Position, [string]$color) {
		$this.Color = $color
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

        if ($color -eq 'White') {
            $this.Icon = '♖'
        } elseif ($color -eq 'Black') {
            $this.Icon = '♜'
        }
    }
}

Class Knight : ChessPiece {
	[string]$Type = $this.GetType().Name
    Knight([string]$Position, [string]$color) {
		$this.Color = $color
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

        if ($color -eq 'White') {
            $this.Icon = '♘'
        } elseif ($color -eq 'Black') {
            $this.Icon = '♞'
        }
    }
}

Class Bishop : ChessPiece {
	[string]$Type = $this.GetType().Name
    Bishop([String]$Position, [string]$color) {
		$this.Color = $color
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

		if ($color -eq 'White') {
            $this.Icon = '♗'
        } elseif ($color -eq 'Black') {
            $this.Icon = '♝'
        }
    }
}

Class Queen : ChessPiece {
	[string]$Type = $this.GetType().Name
    Queen([String]$Position, [string]$color) {
		$this.Color = $color
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

		if ($color -eq 'White') {
			$this.Icon = '♕'
		} elseif ($color -eq 'Black') {
			$this.Icon = '♛'
		}
    }
}

Class King : ChessPiece {
	[bool]$firstmove = $true
	[string]$Type = $this.GetType().Name
	King([String]$Position, [string]$color) {
        $this.Color = $color
        $this.CurrentPosition = $Position
        $this.CurrentRow = Get-Row $Position[1] 
        $this.CurrentColumn = Get-Column $Position[0]

        if ($color -eq 'White') {
            $this.Icon = '♔'
        } elseif ($color -eq 'Black') {
            $this.Icon = '♚'
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
[string]$Script:logpath = 'C:\Users\z003ndjt\Desktop\Powershell\Powershell-Chess-master\log.txt'

$wAP = [Pawn]::New('A2', 'White')
$wBP = [Pawn]::New('B2', 'White')
$wCP = [Pawn]::New('C2', 'White')
$wDP = [Pawn]::New('D2', 'White')
$wEP = [Pawn]::New('E2', 'White')
$wFP = [Pawn]::New('F2', 'White')
$wGP = [Pawn]::New('G2', 'White')
$wHP = [Pawn]::New('H2', 'White')
$wAR = [Rook]::New('A1', 'White')
$wBN = [Knight]::New('B1', 'White')
$wCB = [Bishop]::New('C1', 'White')
$wQ  = [Queen]::New('D1', 'White')
$wK  = [King]::New('E1', 'White')
$wFB = [Bishop]::New('F1', 'White')
$wGN = [Knight]::New('G1', 'White')
$wHR = [Rook]::New('H1', 'White')

$bAP = [Pawn]::New('A7', 'Black')
$bBP = [Pawn]::New('B7', 'Black')
$bCP = [Pawn]::New('C7', 'Black')
$bDP = [Pawn]::New('D7', 'Black')
$bEP = [Pawn]::New('E7', 'Black')
$bFP = [Pawn]::New('F7', 'Black')
$bGP = [Pawn]::New('G7', 'Black')
$bHP = [Pawn]::New('H7', 'Black')
$bAR = [Rook]::New('A8', 'Black')
$bBN = [Knight]::New('B8', 'Black')
$bCB = [Bishop]::New('C8', 'Black')
$bQ  = [Queen]::New('D8', 'Black')
$bK  = [King]::New('E8', 'Black')
$bFB = [Bishop]::New('F8', 'Black')
$bGN = [Knight]::New('G8', 'Black')
$bHR = [Rook]::New('H8', 'Black')

$Empty = [Blank]::New()

[Array] $Script:WhitePieces = @(
    $wAP,$wBP,$wCP,$wDP,
    $wEP,$wFP,$wGP,$wHP,
    $wAR,$wHR,$wBN,$wGN,
    $wCB,$wFB,$wQ,$wK
)

[Array] $Script:BlackPieces = @(
    $bAP,$bBP,$bCP,$bDP,
    $bEP,$bFP,$bGP,$bHP,
    $bAR,$bHR,$bBN,$bGN,
    $bCB,$bFB,$bQ,$bK
)

Clear-Content $logpath
Add-Content -Encoding Unicode $logpath "  White          Black`r`n  --------------------"
[int]$Script:turncounter = 0
Draw-Board