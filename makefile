# all sources
ROOT = $(subst /,\,$(abspath .))
SRC = $(subst \,/,$(subst ${ROOT}\,,$(shell dir source constraint /b /s /a:-d)))

# these are all the compilation targets, starting with "all"
.PHONY: all setup compile clean
all : setup compile

# setup the top level project
setup : .setup.done
.setup.done : $(SRC)
	mkdir project
	cmd /c "vivado -mode batch -source ./script/setup_project.tcl -log \
	./project/setup.log -jou ./project/setup.jou"

compile : .compile.done
.compile.done : .setup.done
	cmd /c "vivado -mode batch -source ./script/compile_project.tcl -log \
	./project/compile.log -jou ./project/compile.jou"
	
# delete everything generated
clean :
	del /q *.jou *.log .setup.done .compile.done
	rmdir /s /q project 
	rmdir /s /q .Xil