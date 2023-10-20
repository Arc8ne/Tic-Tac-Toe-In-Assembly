nasm -f win32 tic-tac-toe.asm -o bin/tic-tac-toe.o

gcc -m32 -o bin/tic-tac-toe.exe bin/tic-tac-toe.o