global _main
extern _printf
extern _scanf
extern _malloc
extern _getchar
extern _ExitProcess@4

%define NEWLINE 10
%define EOF -1
%define START_NEW_GAME_MAIN_MENU_OPTION_NUMBER 1
%define SETTINGS_MAIN_MENU_OPTION_NUMBER 2
%define EXIT_MAIN_MENU_OPTION_NUMBER 3
%define SELECT_A_ROW_IN_GAME_OPTION_NUMBER 1
%define SELECT_A_COLUMN_IN_GAME_OPTION_NUMBER 2
%define PUT_MARK_IN_GAME_OPTION_NUMBER 3
%define SAVE_IN_GAME_OPTION_NUMBER 4
%define RETURN_TO_MAIN_MENU_IN_GAME_OPTION_NUMBER 5
%define EXIT_IN_GAME_OPTION_NUMBER 6
%define NUM_ROWS_IN_A_BOARD 3
%define NUM_COLUMNS_IN_A_BOARD 3
%define NUM_CELLS_IN_A_BOARD NUM_ROWS_IN_A_BOARD * NUM_COLUMNS_IN_A_BOARD
%define CELL_EMPTY_VALUE 0
%define CELL_CIRCLE_VALUE 1
%define CELL_CROSS_VALUE 2
%define SUCCESS_EXIT_CODE 0
%define ERROR_EXIT_CODE -1
%define ZERO_ASCII_CODE 48
%define CELL_CIRCLE_CHAR 'O'
%define CELL_CROSS_CHAR 'X'

%macro init_stack 0
    push ebp
    mov ebp, esp
%endmacro
%macro restore_stack 0
    mov esp, ebp
    pop ebp
%endmacro
%macro return 1
    mov eax, %1
    ret
%endmacro
; This macro should be used after a restore_stack macro, it will increment the stack pointer by 4 bytes
; to skip the return address stored on the stack when a function is called, thus causing the stack
; pointer to stop pointing to the return address.
%macro cancel_return 0
    add esp, 4
%endmacro
; This macro causes the current process (of the program) to exit with the provided exit code, it
; requires the ExitProcess@4 external function and is only meant to be used on Windows.
%macro exit_on_windows 1
    push %1
    call _ExitProcess@4
%endmacro

section .data
headerText DB "The Tic Tac Toe CLI",10,0
programEndedText DB 10,"Program execution completed. Press the ENTER key to exit the program...",10,0
defaultStringFormatString DB "%s"
mainMenuText DB "Main Menu",10,"(1) New Game",10,"(2) Settings",10,"(3) Exit",10,"Choose an option: ",0
defaultIntegerFormatString DB "%i"
thanksText DB "Thank you for playing this game.",10,0
startingNewGameText DB "Starting a new game...",10,0
goingtoSettingsText DB "Going to Settings...",10,0
invalidMainMenuOptionText DB "[ERROR] An invalid main menu option was selected. Please try again.",10,0
defaultCharFormatString DB "%c"
endCharFormatString DB "%c"
inGameStatsText DB "Selected row: %i",10,"Selected column: %i",10,0
inGameOptionsText DB "(1) Select a row",10,"(2) Select a column",10,"(3) Put down a mark in the cell at the selected row and column",10,"(4) Save",10,"(5) Return to main menu",10,"(6) Exit",10,"Select an option: ",0
selectARowText DB "Select a row (1, 2 or 3) to fill in: ",0
selectAColumnText DB "Select a column (1, 2, or 3) to fill in: ",0
savedSuccessfullyText DB "Current game saved successfully.",10,0
invalidOptionSelectedText DB "[ERROR] An invalid option was selected. Please try again.",10,0
ticTacToeBoardAsText DB "     |     |     ",10,"  %c  |  %c  |  %c  ",10,"_____|_____|_____",10,"     |     |     ",10,"  %c  |  %c  |  %c  ",10,"_____|_____|_____",10,"     |     |     ",10,"  %c  |  %c  |  %c  ",10,"     |     |     ",10,0
defaultByteFormatString DB 10,"%c"
invalidRowSelectedText DB "[ERROR] An invalid row was selected.",10,0
invalidColumnSelectedText DB "[ERROR] An invalid column was selected.",10,0

section .text
_main:
    init_stack
    push headerText
    call _printf
_main_menu:
    push mainMenuText
    call _printf
    push 4
    call _malloc
    mov [ebp - 4], eax
    push eax
    push defaultIntegerFormatString
    call _scanf
    mov ebx, [ebp - 4]
    mov ebx, [ebx]
    cmp ebx, START_NEW_GAME_MAIN_MENU_OPTION_NUMBER
    jz _on_new_game_option_selected
    cmp ebx, SETTINGS_MAIN_MENU_OPTION_NUMBER
    jz _on_settings_option_selected
    cmp ebx, EXIT_MAIN_MENU_OPTION_NUMBER
    jz _on_exit_option_selected
    jmp _on_invalid_main_menu_option_selected
_main_exit:
    push programEndedText
    call _printf
    call _clean_stdin_buffer
    call _getchar
    restore_stack
    exit_on_windows SUCCESS_EXIT_CODE
; The _init_board function is responsible for initializing all 9 cells of the board to have a value
; of 0.
; Function signature: _init_board(cellArrayStartAddress)
_init_board:
    init_stack
    ; EBX will store the current index into the array.
    mov ebx, 0
    ; ECX will store the address to the start of the cell array.
    mov ecx, [ebp + 8]
    jmp _init_board_br_1
_init_board_exit:
    restore_stack
    ret
_init_board_br_1:
    cmp ebx, NUM_CELLS_IN_A_BOARD
    jge _init_board_exit
    mov byte [ecx + ebx], CELL_EMPTY_VALUE
    add ebx, 1
    jmp _init_board_br_1
; The _print_board function.
; Function signature: _print_board(cellArrayStartAddress)
_print_board:
    init_stack
    mov ebx, NUM_CELLS_IN_A_BOARD - 1
    mov ecx, [ebp + 8]
    jmp _print_board_br_2
_print_board_br_1:
    push ticTacToeBoardAsText
    call _printf
    restore_stack
    ret
_print_board_br_2:
    cmp ebx, 0
    jl _print_board_br_1
    mov edx, [ecx + ebx]
    cmp edx, CELL_CIRCLE_VALUE
    je _print_board_br_cell_circle_value
    cmp edx, CELL_CROSS_VALUE
    je _print_board_br_cell_cross_value
_print_board_br_3:
    push edx
    sub ebx, 1
    jmp _print_board_br_2
_print_board_br_cell_circle_value:
    mov edx, CELL_CIRCLE_CHAR
    jmp _print_board_br_3
_print_board_br_cell_cross_value:
    mov edx, CELL_CROSS_CHAR
    jmp _print_board_br_3
_on_new_game_option_selected:
    ; push startingNewGameText
    ; call _printf
    call _main_game_loop
    jmp _main_exit
_on_settings_option_selected:
    push goingtoSettingsText
    call _printf
    jmp _main_exit
_on_exit_option_selected:
    push thanksText
    call _printf
    jmp _main_exit
_on_invalid_main_menu_option_selected:
    push invalidMainMenuOptionText
    call _printf
    jmp _main_exit
; The _clean_stdin_buffer function. This function clears all characters in the stdin buffer until
; a newline character or an EOF character is found.
_clean_stdin_buffer:
    init_stack
    jmp _clean_stdin_buffer_br_1
_clean_stdin_buffer_exit:
    restore_stack
    ret
_clean_stdin_buffer_br_1:
    call _getchar
    cmp eax, NEWLINE
    jz _clean_stdin_buffer_exit
    cmp eax, EOF
    jz _clean_stdin_buffer_exit
    jmp _clean_stdin_buffer_br_1
; The _main_game_loop function.
; [ebp - 1] Selected option (Size: 1 byte).
; [ebp - 2] Selected row (Size: 1 byte).
; [ebp - 3] Selected column (Size: 1 byte).
; [ebp - 4] Array of cells (9 cells => Each cell takes up 1 byte => Total size needed: 9 bytes)
; where [ebp - 12] is where the array starts and [ebp - 4] is where the array ends.
; [ebp - 13] Player mark symbol (Can be either a circle or a cross)
; [ebp - 14] Computer (opponent) mark symbol (Can be either a circle or a cross)
_main_game_loop:
    init_stack
    sub esp, 12
    mov byte [ebp - 1], 0
    mov byte [ebp - 2], 0
    mov byte [ebp - 3], 0
    mov byte [ebp - 13], CELL_CIRCLE_VALUE
    mov byte [ebp - 14], CELL_CROSS_VALUE
    lea ebx, [ebp - 12]
    push ebx
    call _init_board
    jmp _main_game_loop_br_1
_main_game_loop_exit:
    restore_stack
    ret
_main_game_loop_br_1:
    lea ebx, [ebp - 12]
    push ebx
    call _print_board
    ; Reset ECX to 0 as its value might have been changed in another function.
    mov ecx, 0
    mov cl, [ebp - 3]
    push ecx
    mov cl, [ebp - 2]
    push ecx
    push inGameStatsText
    call _printf
    push inGameOptionsText
    call _printf
    lea eax, [ebp - 1]
    push eax
    push defaultIntegerFormatString
    call _scanf
    mov ebx, [ebp - 1]
    cmp ebx, SELECT_A_ROW_IN_GAME_OPTION_NUMBER
    jz _on_select_a_row_in_game_option_selected
    cmp ebx, SELECT_A_COLUMN_IN_GAME_OPTION_NUMBER
    jz _on_select_a_column_in_game_option_selected
    cmp ebx, PUT_MARK_IN_GAME_OPTION_NUMBER
    jz _on_put_mark_in_game_option_selected
    cmp ebx, SAVE_IN_GAME_OPTION_NUMBER
    jz _on_save_in_game_option_selected
    cmp ebx, RETURN_TO_MAIN_MENU_IN_GAME_OPTION_NUMBER
    jz _on_return_to_main_menu_in_game_option_selected
    cmp ebx, EXIT_IN_GAME_OPTION_NUMBER
    jz _on_exit_in_game_option_selected
    jmp _on_invalid_in_game_option_selected
_on_select_a_row_in_game_option_selected:
    push selectARowText
    call _printf
    lea ebx, [ebp - 2]
    push ebx
    push defaultByteFormatString
    call _scanf
    mov ebx, [ebp - 2]
    ; Convert from ASCII value to numeric value.
    sub byte [ebp - 2], ZERO_ASCII_CODE
    cmp byte [ebp - 2], 0
    jle _on_invalid_row_selected
    cmp byte [ebp - 2], NUM_ROWS_IN_A_BOARD
    jg _on_invalid_row_selected
    jmp _main_game_loop_br_1
_on_select_a_column_in_game_option_selected:
    push selectAColumnText
    call _printf
    lea ebx, [ebp - 3]
    push ebx
    push defaultByteFormatString
    call _scanf
    mov ebx, [ebp - 3]
    ; Convert from ASCII value to numeric value.
    sub byte [ebp - 3], ZERO_ASCII_CODE
    cmp byte [ebp - 3], 0
    jle _on_invalid_column_selected
    cmp byte [ebp - 3], NUM_COLUMNS_IN_A_BOARD
    jg _on_invalid_column_selected
    jmp _main_game_loop_br_1
_on_put_mark_in_game_option_selected:
    ; Formula for deriving the zero-based index of a cell given a row number and a column number:
    ; [(R - 1) * NCPR] + C - 1 = CLI
    ; Where R is the row number, NCPR is the number of columns per row, C is the column number and
    ; CLI is the zero-based index of the cell.
    mov ebx, 0
    mov bl, [ebp - 2]
    sub bl, 1
    imul ebx, NUM_COLUMNS_IN_A_BOARD
    add bl, [ebp - 3]
    sub bl, 1
    ; EBX will hold the zero-based index of the selected cell as derived from the selected row
    ; number and selected column number using the formula stated above.
    ; CL will be used to transfer the numeric code corresponding to the player's mark symbol to
    ; the memory location of the selected cell (which tracks whether a cell has not been marked,
    ; has been marked by the player, or has been marked by the player's opponent).
    mov cl, [ebp - 13]
    mov [ebp - 12 + ebx], cl
    jmp _main_game_loop_br_1
_on_save_in_game_option_selected:
    jmp _main_game_loop_br_1
_on_return_to_main_menu_in_game_option_selected:
    jmp _main_menu
_on_exit_in_game_option_selected:
    jmp _main_game_loop_exit
_on_invalid_in_game_option_selected:
    push invalidOptionSelectedText
    call _printf
    jmp _main_game_loop_br_1
_on_invalid_row_selected:
    push invalidRowSelectedText
    call _printf
    mov byte [ebp - 2], 1
    jmp _main_game_loop_br_1
_on_invalid_column_selected:
    push invalidColumnSelectedText
    call _printf
    mov byte [ebp - 3], 1
    jmp _main_game_loop_br_1
