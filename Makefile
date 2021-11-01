.PHONY: install clean

default: trash clean install

product:=TeXBridge
target_scheme:=${product}
target_app:=${HOME}/Library/Application\ Support/mi3/mode/TEX/${product}.app

trash:
	trash ${target_app}

install: trash clean
	xcodebuild install DSTROOT=${HOME}

clean:
	xcodebuild -scheme ${target_scheme} clean

release:
	xcodebuild -scheme ${target_scheme} -configuration release build