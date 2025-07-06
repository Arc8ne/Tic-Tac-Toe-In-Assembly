call nasm src/tic-tac-toe.asm -o bin/obj/tic-tac-toe.o -f win64 -l build/tic-tac-toe.lst

call gcc bin/obj/tic-tac-toe.o -o bin/tic-tac-toe.exe
