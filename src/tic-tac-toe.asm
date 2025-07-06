; Key points regarding the 64-bit Windows calling convention:
; - The 1st 4 integer/pointer arguments are passed in RCX, RDX, R8, and R9.
; - Floating-point arguments are passed in XMM0, XMM1, XMM2, and XMM3.
; - Additional arguments are passed on the stack (pushed right-to-left, so the 5th argument is pushed first).
; - The caller is responsible for allocating 32 bytes of "shadow space" (also known as "home space") on the stack for the 4 register arguments, even if the function has fewer than 4 arguments.
; - The caller must ensure the stack is 16-byte aligned before the call. The shadow space allocation (32 bytes) plus any stack arguments and the return address (8 bytes) will affect alignment. Typically, we adjust the stack to be aligned by 16 at the point of the call (i.e. right after the return address has been pushed onto the stack as a result of a `call` instruction).
global main

extern printf
extern scanf
extern getchar

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
%define CELL_EMPTY_CHAR ' '

; Macros
%macro init_stack_frame 0
    push rbp
    mov rbp, rsp
%endmacro

%macro deinit_stack_frame 0
    mov rsp, rbp
    pop rbp
%endmacro

%macro return 1
    mov rax, %1
    ret
%endmacro

; This macro should be used after a restore_stack macro, it will increment the stack pointer by 4 bytes
; to skip the return address stored on the stack when a function is called, thus causing the stack
; pointer to stop pointing to the return address.
%macro cancel_return 0
    add rsp, 4
%endmacro

section .text
main:
    init_stack_frame

    ; Save used registers.
    push rcx

    mov rcx, header_text
    sub rsp, 40
    call printf

main.menu:
    mov rcx, main_menu_text
    call printf

    mov rcx, default_integer_format_string
    ; Allocate 4 bytes to save the inputted integer to and then another 4 bytes to ensure the stack is aligned.
    sub rsp, 8
    call scanf
    mov rax, [rbp]
    cmp rax, START_NEW_GAME_MAIN_MENU_OPTION_NUMBER
    jz on_new_game_option_selected
    cmp rax, SETTINGS_MAIN_MENU_OPTION_NUMBER
    jz on_settings_option_selected
    cmp rax, EXIT_MAIN_MENU_OPTION_NUMBER
    jz on_exit_option_selected
    jmp on_invalid_main_menu_option_selected

; TODO: Fix stack alignment issues (which are silently causing memory access violation errors) for calls to external functions made from this line onwards till the end of this program's executable code.
main.menu.on_new_game_option_selected:
    ; Save used registers.
    push rcx

    mov rcx, starting_new_game_text
    call printf
    call main_game_loop

    ; Restore used registers.
    pop rcx

main.exit:
    mov rcx, program_ended_text
    call printf
    call clean_stdin_buffer
    call getchar

    ; Restore used registers.
    pop rcx

    deinit_stack_frame

    xor rax, rax
    ret

print_board:
    ; Save used registers.
    push rax
    push bx
    push rcx
    push rdx
    push r8
    push r9

    mov rcx, tic_tac_toe_board_as_text
    xor rdx, rdx
    mov rax, board_cells
    mov dl, [rax]
    xor r8, r8
    mov r8b, [rax + 1]
    xor r9, r9
    mov r9b, [rax + 2]
    push word [rax + 6]
    push word [rax + 4]
    xor bx, bx
    mov bl, [rax + 3]
    push bx
    call printf

    ; Restore used registers.
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop bx
    pop rax

    ret

on_settings_option_selected:
    ; Save used registers.
    push rcx

    mov rcx, going_to_settings_text
    call printf
    
    ; Restore used registers.
    pop rcx
    
    ret

on_exit_option_selected:
    ; Save used registers.
    push rcx

    mov rcx, thanks_text
    call printf
    
    ; Restore used registers.
    pop rcx
    
    ret

on_invalid_main_menu_option_selected:
    ; Save used registers.
    push rcx

    mov rcx, invalid_main_menu_option_text
    call printf

    ; Restore used registers.
    pop rcx
    
    ret

; This function clears all characters in the stdin buffer until a newline character or an EOF character is found.
clean_stdin_buffer:
    ; Save used registers.
    push rax

clean_stdin_buffer.br_1:
    call getchar
    cmp rax, NEWLINE
    jz clean_stdin_buffer.exit
    cmp rax, EOF
    jz clean_stdin_buffer.exit
    jmp clean_stdin_buffer.br_1

clean_stdin_buffer.exit:
    ; Restore used registers.
    pop rax

    ret

; Locals:
; [rbp]: Selected option (Size: 1 byte)
; [rbp - 1]: Selected row (Size: 1 byte)
; [rbp - 2]: Selected column (Size: 1 byte)
main_game_loop:
    init_stack_frame

    ; Save used registers.
    push rax

    sub rsp, 3
    mov byte [rbp], 0
    mov byte [rbp - 1], 0
    mov byte [rbp - 2], 0

    ; Initialize the board.
    mov rax, board_cells
    mov qword [rax], CELL_EMPTY_CHAR

main_game_loop.exit:
    ; Restore used registers.
    pop rax

    deinit_stack_frame
    
    ret

main_game_loop.br_1:
    call print_board
    mov rcx, in_game_stats_text
    mov rdx, [rbp - 1]
    mov r8, [rbp - 2]
    call printf
    mov rcx, in_game_options_text
    call printf
    mov rcx, default_integer_format_string
    lea rdx, [rbp - 1]
    call scanf
    mov rbx, [rbp - 1]
    cmp rbx, SELECT_A_ROW_IN_GAME_OPTION_NUMBER
    jz on_select_a_row_in_game_option_selected
    cmp rbx, SELECT_A_COLUMN_IN_GAME_OPTION_NUMBER
    jz on_select_a_column_in_game_option_selected
    cmp rbx, PUT_MARK_IN_GAME_OPTION_NUMBER
    jz on_put_mark_in_game_option_selected
    cmp rbx, SAVE_IN_GAME_OPTION_NUMBER
    jz on_save_in_game_option_selected
    cmp rbx, RETURN_TO_MAIN_MENU_IN_GAME_OPTION_NUMBER
    jz main.menu
    cmp rbx, EXIT_IN_GAME_OPTION_NUMBER
    jz main_game_loop.exit

on_invalid_in_game_option_selected:
    mov rcx, invalid_option_selected_text
    call printf
    jmp main_game_loop.br_1

on_select_a_row_in_game_option_selected:
    mov rcx, select_a_row_text
    call printf
    mov rcx, default_byte_format_string
    lea rdx, [rbp - 1]
    call scanf
    mov bl, [rbp - 1]
    cmp bl, 1
    jl on_invalid_row_selected
    cmp bl, NUM_ROWS_IN_A_BOARD
    jg on_invalid_row_selected
    jmp main_game_loop.br_1

on_invalid_row_selected:
    mov rcx, invalid_row_selected_text
    call printf
    mov byte [rbp - 1], 0
    jmp main_game_loop.br_1

on_select_a_column_in_game_option_selected:
    mov rcx, select_a_column_text
    call printf
    mov rcx, default_byte_format_string
    lea rdx, [rbp - 2]
    call scanf
    mov bl, [rbp - 2]
    cmp bl, 1
    jl on_invalid_column_selected
    cmp bl, NUM_COLUMNS_IN_A_BOARD
    jg on_invalid_column_selected
    jmp main_game_loop.br_1

on_invalid_column_selected:
    mov rcx, invalid_column_selected_text
    call printf
    mov byte [rbp - 2], 0
    jmp main_game_loop.br_1

on_put_mark_in_game_option_selected:
    ; Formula for deriving the zero-based index of a cell given a row number and a column number:
    ; [(R - 1) * NCPR] + C - 1 = CLI
    ; Where R is the row number, NCPR is the number of columns per row, C is the column number and CLI is the zero-based index of the cell.
    xor rbx, rbx
    mov bl, [rbp - 2]
    sub bl, 1
    imul rbx, NUM_COLUMNS_IN_A_BOARD
    add bl, [rbp - 3]
    sub bl, 1
    ; RBX will hold the zero-based index of the selected cell as derived from the selected row number and selected column number using the formula stated above.
    mov rax, board_cells
    mov byte [rax + rbx], CELL_CROSS_CHAR
    jmp main_game_loop.br_1

; TODO: Implement this.
on_save_in_game_option_selected:
    jmp main_game_loop.br_1

section .data
board_cells:
    dq 0
    db 0

section .rodata
; Format strings
default_string_format_string: db "%s"
default_integer_format_string: db "%i"
default_char_format_string: db "%c"
default_byte_format_string: db NEWLINE, "%c"
end_char_format_string: db "%c"
; Text
header_text: db "Tic Tac Toe CLI", NEWLINE, 0
program_ended_text: db NEWLINE, "Program execution completed. Press the ENTER key to exit the program...", NEWLINE, 0
main_menu_text: db "Main Menu", NEWLINE, "(1) New Game", NEWLINE, "(2) Settings", NEWLINE, "(3) Exit", NEWLINE, "Choose an option: ", 0
thanks_text: db "Thank you for playing this game.", NEWLINE, 0
starting_new_game_text: db "Starting a new game...", NEWLINE, 0
going_to_settings_text: db "Going to Settings...", NEWLINE, 0
invalid_main_menu_option_text: db "[Error] An invalid main menu option was selected. Please try again.", NEWLINE, 0
in_game_stats_text: db "Selected row: %i", NEWLINE, "Selected column: %i", NEWLINE, 0
in_game_options_text: db "(1) Select a row", NEWLINE, "(2) Select a column", NEWLINE, "(3) Put down a mark in the cell at the selected row and column", NEWLINE, "(4) Save", NEWLINE, "(5) Return to main menu", NEWLINE, "(6) Exit", NEWLINE, "Select an option: ", 0
select_a_row_text: db "Select a row (1, 2 or 3) to fill in: ", 0
select_a_column_text: db "Select a column (1, 2, or 3) to fill in: ", 0
saved_successfully_text: db "Current game saved successfully.", NEWLINE, 0
invalid_option_selected_text: db "[Error] An invalid option was selected. Please try again.", NEWLINE, 0
tic_tac_toe_board_as_text: db "     |     |     ", NEWLINE, "  %c  |  %c  |  %c  ", NEWLINE, "_____|_____|_____", NEWLINE, "     |     |     ", NEWLINE, "  %c  |  %c  |  %c  ", NEWLINE, "_____|_____|_____", NEWLINE, "     |     |     ", NEWLINE, "  %c  |  %c  |  %c  ", NEWLINE, "     |     |     ", NEWLINE, 0
invalid_row_selected_text: db "[Error] An invalid row was selected.", NEWLINE, 0
invalid_column_selected_text: db "[Error] An invalid column was selected.", NEWLINE, 0
