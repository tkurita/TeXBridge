property isChangeBackground : true
property backgroundColor : {42858, 43841, 65535}
property terminalOpaqueness : 58100
property isChangeNormalText : true
--property normalTextColor : {65535, 65535, 65535} -- white
property normalTextColor : {0, 0, 0} -- black
property isChangeBoldText : true
--property boldTextColor : {65535, 65535, 65535}
property boldTextColor : {0, 0, 0}
property isChangeCursor : false
property cursorColor : {21823, 21823, 21823}
property isChangeSelection : false
property selectionColor : {43690, 43690, 43690}

property customTitle : "TeX Console"
property stringEncoding : 4
property useLoginShell : false
property shellPath : "/bin/bash"
property useCtrlVEscapes : "YES"
property executionString : "source ~/Library/Preferences/mi/mode/TEX/initialize.sh"