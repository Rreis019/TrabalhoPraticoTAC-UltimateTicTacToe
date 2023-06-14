.8086
.MODEL SMALL
.STACK 2048

;Ultimat tic tac toe
;1 - Player vs Player
;2 - Player vs Computer


DATA SEGMENT
    IS_RUNNING DB 1
    
    ;---------------------------------------------------------------------------------------------
    GAME_VARS:
        CURRENT_GAMEMODE DB 0 ; o modo de jogo atual | 0 -> player vs player | 1 -> player vs computer
        SELECTED_TABLE DB 0; Indicate which table is selected | 96 -> select table
        CURRENT_PLAYER DB 1 ; Indicate which player is currently playing
        CURRENT_CHECK_POS DB 0,0 ; x,y indica a posição do X ao jogar 
        BOARDS db 9 dup (9 dup (' ')) ; os tabuleiros | K -> select X | L -> select O
        BOARD_WIN db 9 dup (0) ; 1 -> Red Ganhou | 2 -> Blue ganhou | 3 -> Tie | 4 -> selected
        FIRST_PLAYER_NAME DB 32 dup(0)
        SECOND_PLAYER_NAME DB 32 dup(0)
        FIRST_PLAYER_SCORE DW 0
        SECOND_PLAYER_SCORE DW 0
    ;---------------------------------------------------------------------------------------------
    FILE_VARS:
        FILE_NAME DB 32 dup(0)
        FILE_HANDLE DW ?
        FILE_NOT_FOUND DB 'O ficheiro nao foi encontrado',0
        FILE_PROMPT DB 'Digite o nome do ficheiro: ','$'
    ;---------------------------------------------------------------------------------------------

    SEED DW 0

    SEPARATOR_NAME DB ' : ',0
    COMPUTER_NAME DB '  Computer',0
    CURRENT_SCREEN_INDEX DB 0
    ;WIN_PATTERNS DB 0,1,2 , 3,4,5 , 6,7,8  ,  0,3,6 , 1,4,7 , 2,5,8  ,  0,4,8 , 2,4,6 
    ;rows | cols | diagonals
    CURRENT_ITEM_INDEX DW 0
    MENU_SELECTED DB '-> ',0
    MENU_TITLE DB 'Ultimate TicTacToe',0


    MENU_HELP DB 'Use w ou s para navegar pelo menu',0
    MENU_HELP2 DB 'Use enter para confirmar selecao',0

    INPUT_NAMES DB 'Introduza o nomes dos jogadores: ',10,13,13,"$"
    INPUT_FIRSTNAME DB '1 Jogador: ',0
    INPUT_SECONDNAME DB '2 Jogador: ',0

    STARTMENU_ITEMS:
        DB 'Novo Jogo',0
        DB 'Continuar Jogo',0
        DB 'Sair do jogo',0
    STARTMENU_SIZE DW 3

    MODE_MENU_ITEMS:
        DB 'Jogador vs Jogador',0
        DB 'Jogador vs Computador',0
        DB 'Voltar para o menu',0
    MODE_MENU_SIZE DW 3

    PAUSE_MENU_TITLE DB 'Jogo esta em pausa',0
    PAUSE_MENU_ITEMS:
        DB 'Continuar Jogar',0
        DB 'Sair do Jogo',0
        DB 'Sair e Salvar',0
    PAUSE_MENU_SIZE DW 3
DATA ENDS


CODE SEGMENT PARA 'CODE'
   ASSUME CS:CODE, DS:DATA

   

   START:
        MOV AX,DATA
        MOV DS,AX

        MOV AH,00h ;setVideoMode
        MOV AL,13h ; https://stanislavs.org/helppc/int_10-0.html
        INT 10h
 
        MOV DX,10


        ;MOV BOARD_WIN+1,2
        ;MOV BOARD_WIN+1,1

        CALL DRAW_CHECK_POS
        GAME_LOOP:
            MOV AX, 0A000h  ; Set ES to point to the video memory segment
            MOV ES, AX
            MOV DI, 0       ; Set DI to the start of the video memory
            MOV CX, 320*200 ; Set CX to the total number of pixels on the screen
            MOV AL, 0       ; Set AL to the black color index
            REP STOSB       ; Use REP STOSB to set all pixels to black

            CALL RENDER_CURRENT_SCREEN
            CMP IS_RUNNING , 1
            JE GAME_LOOP
        MOV AH,4Ch ; end program
        INT 21h



RENDER_CURRENT_SCREEN:
    MOV AL,CURRENT_SCREEN_INDEX
    CMP AL , 0
    JE S_STARTMENU

    CMP AL , 1
    JE S_GAMEMODE

    CMP AL , 2
    JE S_GAME

    CMP AL , 3
    JE S_PAUSE

    JMP RENDER_CURR_END

    S_STARTMENU:
        MOV DX, OFFSET MENU_TITLE 
        MOV SI, OFFSET STARTMENU_ITEMS
        MOV AX, STARTMENU_SIZE
        CALL MENU_RENDER
        MOV SI , STARTMENU_EVENTS
        CALL MENU_EVENTS
        JMP RENDER_CURR_END
    S_GAMEMODE:
        MOV DX, OFFSET MENU_TITLE
        MOV SI, OFFSET MODE_MENU_ITEMS
        MOV AX, MODE_MENU_SIZE
        CALL MENU_RENDER
        MOV SI , GAMEMODE_EVENTS
        CALL MENU_EVENTS
        JMP RENDER_CURR_END

    S_GAME:
        CALL GAME_RENDER
        CALL GAME_EVENTS
        JMP RENDER_CURR_END
    S_PAUSE:
        MOV DX, OFFSET PAUSE_MENU_TITLE
        MOV SI, OFFSET PAUSE_MENU_ITEMS
        MOV AX, PAUSE_MENU_SIZE
        CALL MENU_RENDER
        MOV SI , PAUSEMENU_EVENTS
        CALL MENU_EVENTS
        JMP RENDER_CURR_END
RENDER_CURR_END:
    RET

;---------------------------------------------------------------------------------
GAMEMODE_EVENTS:
    CMP CURRENT_ITEM_INDEX , 0
    JE GAMEMODE_PVP

    CMP CURRENT_ITEM_INDEX , 1
    JE GAMEMODE_PVC

    CMP CURRENT_ITEM_INDEX , 2
    JE GAMEMODE_PVC_BACK

    JMP GAMEMODE_EVENTS_END

    GAMEMODE_PVP: ; player vs player
        MOV CURRENT_GAMEMODE,0
        MOV CURRENT_SCREEN_INDEX,2
        CALL READPLAYER_NAMES
        JMP GAMEMODE_EVENTS_END
    GAMEMODE_PVC: ;  player vs computer
        MOV CURRENT_GAMEMODE,1
        MOV CURRENT_SCREEN_INDEX,2
        CALL READPLAYER_NAMES
        JMP GAMEMODE_EVENTS_END
    GAMEMODE_PVC_BACK:
        MOV CURRENT_SCREEN_INDEX,0
        JMP GAMEMODE_EVENTS_END
GAMEMODE_EVENTS_END:
    RET

;---------------------------------------------------------------------------------
STARTMENU_EVENTS:
    
    CMP CURRENT_ITEM_INDEX , 0
    JE STARTMENU_NEWGAME

    CMP CURRENT_ITEM_INDEX , 1
    JE STARTMENU_CONTINUE

    CMP CURRENT_ITEM_INDEX , 2
    JE STARTMENU_EXIT

    JMP STARTMENU_EVENTS_END

    STARTMENU_NEWGAME:
        MOV CURRENT_SCREEN_INDEX,1;muda para o menu gamemode
        MOV SELECTED_TABLE,4

        MOV CX,0
        MOV BX,2
        CALL RANDOM_NUM


        MOV AH, 02h
        MOV DL, 'A';the letter to print
        INT 21h

        CALL CLEAR_BOARDS
        CALL CLEAR_BOARD_WIN
        JMP STARTMENU_EVENTS_END
    STARTMENU_CONTINUE:
        CALL READ_FILENAME
        CALL GAME_LOAD_MATCH
        CMP AX , 0
        JE STARTMENU_EVENTS_END

        MOV CURRENT_SCREEN_INDEX, 2 ; Game screen
        JMP STARTMENU_EVENTS_END
    STARTMENU_EXIT:
        MOV IS_RUNNING,0
        MOV AH,00h ;setVideoMode
        MOV AL,02h ; https://stanislavs.org/helppc/int_10-0.html
        INT 10h
        JMP STARTMENU_EVENTS_END

STARTMENU_EVENTS_END:
    RET


;---------------------------------------------------------------------------------
PAUSEMENU_EVENTS:
    
    CMP CURRENT_ITEM_INDEX , 0
    JE PAUSEMENU_CONTINUE

    CMP CURRENT_ITEM_INDEX , 1
    JE PAUSEMENU_BACKGAME

    CMP CURRENT_ITEM_INDEX , 2
    JE PAUSEMENU_BACK_AND_SAVE

    PAUSEMENU_CONTINUE:
        MOV CURRENT_SCREEN_INDEX,2
        JMP STARTMENU_EVENTS_END

    PAUSEMENU_BACKGAME:
        MOV CURRENT_SCREEN_INDEX,0
        JMP STARTMENU_EVENTS_END

    PAUSEMENU_BACK_AND_SAVE:
        CALL READ_FILENAME
        MOV SI,OFFSET FILE_NAME+2
        CALL GAME_SAVE_MATCH
        MOV CURRENT_SCREEN_INDEX,0
        JMP STARTMENU_EVENTS_END
    RET


;--------------------------------------------------------------------------------
;Permite renderizar qualquer menu com nItems 


;Draw menu with items
;SI -> pointer items
;AX -> size items
MENU_RENDER:
    PUSH BP
    MOV BP,SP
    SUB SP,2; 
    MOV [BP-2],AX ; items size

    PUSH SI
    PUSH DX

    MOV AH,02h;Set cursor position
    MOV DH,0h;row
    MOV DL,0h;col
    INT 10h
    
    MOV BL,07h; light gray color 
    ;MOV SI,OFFSET MENU_TITLE
    POP SI
    CALL DRAW_STRING
    CALL BREAK_LINE
    CALL BREAK_LINE

    MOV CX,0
    POP SI
    ;MOV SI, OFFSET STARTMENU_ITEMS
    MOV BL,0Fh; white color
    ITEM_LOOP:
        PUSH CX
        
        CMP CX,CURRENT_ITEM_INDEX
        JNE ITEM_DRAW

        MOV BL, 02h; green color
        PUSH SI
        MOV SI,OFFSET MENU_SELECTED
        CALL DRAW_STRING
        POP SI

        ITEM_DRAW:
            CALL DRAW_STRING            
            CALL BREAK_LINE
            MOV BL,0Fh; white color 
        POP CX
        INC CX
        CMP CX, [BP-2]
        JNE ITEM_LOOP


    CALL BREAK_LINE
    MOV BL,07h; light gray color 
    MOV SI,OFFSET MENU_HELP
    CALL DRAW_STRING
    CALL BREAK_LINE

    MOV SI,OFFSET MENU_HELP2
    CALL DRAW_STRING

    ADD SP,2
    MOV SP,BP
    POP BP 
    RET

;SI pointer to function which contains functions of the menu
MENU_EVENTS:
    MOV AH, 01h;read char
    INT 21h;al 

    CMP AL, 's' 
    JE DOWN_KEY

    CMP AL, 'S'     
    JE DOWN_KEY

    CMP AL, 25
    JE DOWN_KEY

    CMP AL , 'w'
    JE UP_KEY

    CMP AL, 'W'     
    JE UP_KEY

    CMP AL, 24     
    JE UP_KEY

    CMP AL, 13     
    JE ON_CLICK_KEY

    JMP MENU_EVENTS_END
    DOWN_KEY:
        MOV DX,STARTMENU_SIZE
        DEC DX
        CMP CURRENT_ITEM_INDEX, DX
        JE MENU_EVENTS_END ; se chegou ao limite vai pro fim

        INC CURRENT_ITEM_INDEX
        JMP MENU_EVENTS_END

    UP_KEY:
        CMP CURRENT_ITEM_INDEX,0
        JE MENU_EVENTS_END

        DEC CURRENT_ITEM_INDEX
        JMP MENU_EVENTS_END
    ON_CLICK_KEY:
        CALL SI ; menu funcs
MENU_EVENTS_END:
    RET


;----------------------------------------------------------------------------
READPLAYER_NAMES:
        CALL CLEAR_SCREEN
        
        MOV AH,02h;Set cursor position
        MOV DH,0h;row
        MOV DL,0h;col
        INT 10h

        MOV DX, offset INPUT_NAMES ; print string
        MOV AH,09h
        INT 21h

        CALL BREAK_LINE

        MOV BL,0Ch; light red color 
        MOV SI,OFFSET INPUT_FIRSTNAME
        CALL DRAW_STRING


        MOV AH, 0Ah ; read string
        LEA DX, FIRST_PLAYER_NAME ; FIRST_PLAYER_NAME+0 -> size array | FIRST_PLAYER_NAME+1 -> entered characters
        MOV FIRST_PLAYER_NAME,32 ; size array
        INT 21h
        
        CMP FIRST_PLAYER_NAME+1 , 0 ; Se estiver vazio ou so com 1 volta a perguntar
        JLE READPLAYER_NAMES

        ;replace last letter with null terminator
        MOV AX,0
        ADD AL,[FIRST_PLAYER_NAME+1]
        MOV SI,OFFSET FIRST_PLAYER_NAME
        ADD SI,2
        ADD SI,AX
        MOV CX,0
        MOV [SI],CX


        CMP CURRENT_GAMEMODE , 1 ; if(CURRENT_GAMEMODE == PlayerVsComputer)
        JE READPLAYER_NAMES_PVC



        CALL BREAK_LINE

        MOV BL,09h; light blue color 
        MOV SI,OFFSET INPUT_SECONDNAME
        CALL DRAW_STRING


        MOV AH, 0Ah ; read string
        LEA DX, SECOND_PLAYER_NAME ; SECOND_PLAYER_NAME+0 -> size array | SECOND_PLAYER_NAME+1 -> entered characters
        MOV SECOND_PLAYER_NAME,32 ; size array
        INT 21h

        CMP SECOND_PLAYER_NAME+1 , 0 ; Se estiver vazio ou so com 1 volta a perguntar
        JLE READPLAYER_NAMES


        CALL BREAK_LINE

        ;replace last letter with null terminator
        MOV AX,0
        ADD AL,[SECOND_PLAYER_NAME+1]
        MOV SI,OFFSET SECOND_PLAYER_NAME
        ADD SI,2
        ADD SI,AX
        MOV CX,0
        MOV [SI],CX
    RET

READPLAYER_NAMES_PVC:
    MOV CX,10
    MOV SI, offset SECOND_PLAYER_NAME
    MOV DI, offset COMPUTER_NAME
    CALL COPY_STRING
    RET
;------------------------------------------------------------------------------------------------------

READ_FILENAME:
        CALL CLEAR_SCREEN

        MOV AH,02h;Set cursor position
        MOV DH,0h;row
        MOV DL,0h;col
        INT 10h

        MOV DX, offset FILE_PROMPT ;print
        MOV AH,09h
        INT 21h

        MOV AH, 0Ah ; read string
        LEA DX, FILE_NAME ; FILE_NAME+0 -> size array | FILE_NAME+1 -> entered characters
        MOV FILE_NAME,32 ; size array
        INT 21h
        
        CMP FILE_NAME+1 , 0
        JE READ_FILENAME

        ;replace last letter with null terminator
        MOV AX,0
        ADD AL,[FILE_NAME+1]
        MOV SI,OFFSET FILE_NAME
        ADD SI,2
        ADD SI,AX
        MOV CX,0
        MOV [SI],CX
    RET

;SI -> File Name
GAME_SAVE_MATCH:
    MOV DX, SI
    MOV AH,3Ch ; Open File
    MOV CX,0    ; Write Mode
    INT 21H

    ;JC FILE_ERROR 
    MOV FILE_HANDLE,AX

    MOV AH , 40h ; Write File
    MOV BX , FILE_HANDLE
    MOV DX , OFFSET GAME_VARS
    MOV CX , 163 ; Size
    INT 21H

    MOV AH, 3EH           ; Close file
    MOV BX, FILE_HANDLE   
    INT 21H              
    RET


;RETURN AX == 0 Failed
GAME_LOAD_MATCH:
    MOV AH, 3DH ; 
    MOV AL, 0
    MOV DX, OFFSET FILE_NAME+2
    INT 21H
    JC GAME_LOAD_FAILED  
    MOV FILE_HANDLE,AX      

    MOV AH, 3FH           ; Read file
    MOV BX, FILE_HANDLE   
    MOV DX, OFFSET GAME_VARS         
    MOV CX, 163           ; Size
    INT 21H              

    MOV AH, 3EH           ; Close file
    MOV BX, FILE_HANDLE   
    INT 21H 

GAME_LOAD_MATCH_END:
    MOV AX,1    
    RET


GAME_LOAD_FAILED:
    CALL CLEAR_SCREEN
    MOV BL,04h; red color
    MOV SI, OFFSET FILE_NOT_FOUND
    CALL DRAW_STRING

    MOV AH, 01h;read char
    INT 21h;AL
    MOV AX,0
    RET




;----------------------------------------------------------------------------

GAME_RENDER:
    MOV AH,02h;Set cursor position
    MOV DH,6h;row
    MOV DL,10h;col
    INT 10h

    MOV BL,0Ch; light red color 
    MOV SI, offset FIRST_PLAYER_NAME+2
    CALL DRAW_STRING

    MOV SI, offset SEPARATOR_NAME ; " : "
    CALL DRAW_STRING

    
    MOV AX , FIRST_PLAYER_SCORE
    CALL PRINT_NUM


    MOV AH,02h;Set cursor position
    MOV DH,8h;row
    MOV DL,10h;col
    INT 10h

    MOV BL,09h; light blue color 
    MOV SI, offset SECOND_PLAYER_NAME+2
    CALL DRAW_STRING

    MOV SI, offset SEPARATOR_NAME ; " : "
    CALL DRAW_STRING

    MOV AX , SECOND_PLAYER_SCORE
    CALL PRINT_NUM

    
    MOV CX,7 ; x
    MOV DX,7 ; y
    MOV AL,08h; dark gray color 
    MOV BX,105; width
    MOV SI,105; height
    CALL DRAW_FILL_RECT

    MOV AH,02h;Set cursor position
    MOV DH,02h;row
    MOV DL,02h;col
    INT 10h

    MOV SI,OFFSET BOARDS
    CALL DRAW_BOARDS

    RET

COMPUTER_PLAYFIRST:
    CMP CURRENT_PLAYER , 1
    JE ONPLAY_COMPUTER
    JMP GAME_EVENTS_START    

GAME_EVENTS:
    CMP CURRENT_GAMEMODE , 1 ; SE O player vs Computer
    JE COMPUTER_PLAYFIRST ; verifica se computador é primeiro a jogar

GAME_EVENTS_START:
    MOV AH, 01h;read char
    INT 21h;AL

    PUSH AX
    MOV AH, 02h     
    MOV DL, 8     ; \b -> back one line  
    INT 21h        

    ;overwrite last letter with ''
    MOV AH, 02h    
    MOV DL, ' '    
    INT 21h
    POP AX         

    MOV SI, OFFSET CURRENT_CHECK_POS  ; Carrega o endereço de memória em SI

    CMP AL,13
    JE GAME_EVENTS_ONCLICK

    CMP AL,27
    JE GAME_EVENTS_PAUSE

    




GAME_EVENTS_ARROWS: ;teclas para movimentar dentro do jogo
    CMP AL , "S"
    JE GAME_EVENTS_DOWNKEY 
    CMP AL, "s"
    JE GAME_EVENTS_DOWNKEY    

    CMP AL,"W"
    JE GAME_EVENTS_UPKEY
    CMP AL,"w"
    JE GAME_EVENTS_UPKEY

    CMP AL,"D"
    JE GAME_EVENTS_RIGHTKEY
    CMP AL,"d"
    JE GAME_EVENTS_RIGHTKEY

    CMP AL,"A"
    JE GAME_EVENTS_LEFTKEY
    CMP AL,"a"
    JE GAME_EVENTS_LEFTKEY


    JMP GAME_EVENTS_END

    GAME_EVENTS_PAUSE:
        MOV CURRENT_SCREEN_INDEX,3
        JMP GAME_EVENTS_END
    GAME_EVENTS_ONCLICK:
        CALL CAN_PLAY
        CMP AX,0
        JE GAME_EVENTS_END

        CALL ONPLAY_CELL

  

        JE GAME_EVENTS_RETURN_COMPUTER

        CMP CURRENT_GAMEMODE , 1 ; if(CURRENT_GAMEMODE == PlayerVsComputer)
        
        JE ONPLAY_COMPUTER

        GAME_EVENTS_RETURN_COMPUTER:

        ;------------------------------------------------------------------------- 

        CALL CAN_PLAY
        CMP AX , 0
        JE GAME_EVENTS_END

        CALL DRAW_CHECK_POS
        JMP GAME_EVENTS_END

    GAME_EVENTS_UPKEY:
        DEC BYTE PTR [SI+1]
        CMP BYTE PTR [SI+1], 0
        JL GE_LESS_Y
        JMP GAME_EVENTS_CLEAR

    GAME_EVENTS_DOWNKEY:
        INC BYTE PTR [SI+1]
        CMP BYTE PTR [SI+1], 2
        JG GE_GREATER_Y
        JMP GAME_EVENTS_CLEAR

    GAME_EVENTS_LEFTKEY:
        DEC CURRENT_CHECK_POS
        CMP CURRENT_CHECK_POS, 0
        JL GE_LESS
        JMP GAME_EVENTS_CLEAR
    GAME_EVENTS_RIGHTKEY:
        INC BYTE PTR [SI]
        CMP CURRENT_CHECK_POS, 2
        JG GE_GREATER
        JMP GAME_EVENTS_CLEAR


        GE_GREATER:
            MOV BYTE PTR [SI],2
            JMP GAME_EVENTS_CLEAR
        GE_LESS:
            MOV BYTE PTR [SI],0
            JMP GAME_EVENTS_CLEAR
        GE_GREATER_Y:
            MOV BYTE PTR [SI+1],2
            JMP GAME_EVENTS_CLEAR
        GE_LESS_Y:
            MOV BYTE PTR [SI+1],0

        GAME_EVENTS_CLEAR:
            CALL CLEAR_BOARD_SELECTED ; clear current board "selected"
            CALL CAN_PLAY
            CMP AX , 0
            JE GAME_EVENTS_END
            CALL DRAW_CHECK_POS
            RET

    GAME_EVENTS_END:
        RET

;----------------------------------------------------------------------------

;AX == 1 -> yes can
CAN_PLAY:
    MOV AH, SELECTED_TABLE
    
    CMP AH , 96
    JE CANPLAY_YES

    MOV DL , BYTE PTR CURRENT_CHECK_POS
    MOV DH , BYTE PTR CURRENT_CHECK_POS+1
    CALL GET_CELL_POS

    MOV SI,OFFSET BOARDS
    ADD SI,CX

    MOV AX,0
    CMP BYTE PTR [SI],' ' ;se não estiver vazia simplesmente sai  
    JE CANPLAY_YES

    CMP BYTE PTR [SI],"K"
    JE CANPLAY_YES

    CMP BYTE PTR [SI],"L"
    JE CANPLAY_YES

    JMP CAN_PLAY_END

    CANPLAY_YES:
        MOV AX,1
CAN_PLAY_END:
    RET







DRAW_CHECK_POS:
    MOV AH , SELECTED_TABLE
    MOV DL , CURRENT_CHECK_POS
    MOV DH , CURRENT_CHECK_POS+1

    CMP SELECTED_TABLE,96
    JE DRAW_SELECTED_TABLE

    CMP CURRENT_PLAYER , 0
    JE DRAW_CHECK_K

    CMP CURRENT_PLAYER , 1
    JE DRAW_CHECK_O

    DRAW_CHECK_K:
    MOV AL , "K"
    JMP DRAW_CHECK_WRITE

    DRAW_CHECK_O:
    MOV AL , "L"

DRAW_CHECK_WRITE:
    CALL WRITE_CELL
DRAW_CHECK_END:
    RET


DRAW_SELECTED_TABLE:
    MOV SI, OFFSET BOARD_WIN
    CALL CLEAR_BOARDWIN_SELECTED

    MOV AH,0
    MOV DL , CURRENT_CHECK_POS
    MOV DH , CURRENT_CHECK_POS+1
    CALL GET_CELL_POS
   
    ;CX
    MOV SI,OFFSET BOARD_WIN
    ADD SI,CX

    CMP BYTE PTR [SI] , 0
    JNE DRAW_CHECK_END

    MOV BYTE PTR [SI],4
   
    JMP DRAW_CHECK_END


ONPLAY_CELL:


    MOV AH,SELECTED_TABLE
    MOV DL,BYTE PTR CURRENT_CHECK_POS
    MOV DH,BYTE PTR CURRENT_CHECK_POS+1

    CMP AH , 96
    JE ONPLAY_SELECTTABLE

    CMP CURRENT_PLAYER,1
    JE ONPLAY_CELL_Y 

    ; CMP CURRENT_PLAYER,0
    ;JE ONPLAY_CELL_X 

    ONPLAY_CELL_X:
        MOV AL,"X"
        JMP ONPLAY_CELL_WRITE
    ONPLAY_CELL_Y:   
        MOV AL,"O" 

    ONPLAY_CELL_WRITE:
        CALL WRITE_CELL

    MOV AL, CURRENT_PLAYER
    XOR AL, 1 ; CURRENT_PLAYER = !CURRENT_PLAYER
    MOV CURRENT_PLAYER,AL

    MOV SI , OFFSET BOARDS

    MOV AX,9
    MOV DX,0
    MOV DL,SELECTED_TABLE
    MUL DX
    ADD SI,AX


    ;Se alguem ganhou preenche tabela boardwin com o valor corresponde
    MOV CL,"X"
    MOV BL,1
    CALL CHECK_WIN
    CMP AX , 1
    JE ONPLAY_CELL_SET_BOARDWIN

    MOV CL,"O"
    MOV BL,2
    CALL CHECK_WIN
    CMP AX , 1
    JE ONPLAY_CELL_SET_BOARDWIN

    ;------------------------------------------
ONPLAY_CELL_CHECK_BOARDS:
    MOV SI, OFFSET BOARD_WIN
    MOV CL,1
    CALL CHECK_WIN
    CMP AX , 1
    JE ONPLAY_CELL_ADD_P1SCORE

    MOV SI, OFFSET BOARD_WIN
    MOV CL,2
    CALL CHECK_WIN
    CMP AX , 1
    JE ONPLAY_CELL_ADD_P2SCORE


ONPLAY_CELL_MID:
    MOV AX,0
    MOV AL,CURRENT_CHECK_POS+1
    MOV BX,3
    MUL BX
    ADD AL, CURRENT_CHECK_POS
    MOV SELECTED_TABLE,AL


    MOV SI,OFFSET BOARD_WIN
    MOV DX,0
    MOV DL,SELECTED_TABLE
    ADD SI,DX
    CMP BYTE PTR [SI] ,0 
    JNE SET_SELECTED_TABLE  

     

ONPLAY_CELL_END:
    RET

ONPLAY_COMPUTER:

    ;CMP SELECTED_TABLE,96
    ;JE 

    MOV CX,0
    MOV BX,2

    CALL RANDOM_NUM

    MOV CURRENT_CHECK_POS, AL

    MOV CX,0
    MOV BX,2

    CALL RANDOM_NUM

    MOV CURRENT_CHECK_POS+1, AL
    CALL CAN_PLAY

    CMP AX,1
    JNE ONPLAY_COMPUTER

    CALL CLEAR_BOARD_SELECTED
    CALL ONPLAY_CELL
    JMP GAME_EVENTS_RETURN_COMPUTER

ONPLAY_SELECTTABLE:
    MOV AH,0
    CALL GET_CELL_POS
    MOV SI,OFFSET BOARD_WIN
    ADD SI,CX

    CMP BYTE PTR [SI] , 4
    JE ONPLAY_SELECTTABLE_WRITE

    CMP BYTE PTR [SI] , 0
    JNE ONPLAY_CELL_END

ONPLAY_SELECTTABLE_WRITE:
    MOV BYTE PTR [SI],0 ; remove selection of the table
    MOV SELECTED_TABLE,CL

    JMP ONPLAY_CELL_END


ONPLAY_CELL_ADD_P1SCORE:
    ADD FIRST_PLAYER_SCORE,1
    CALL CLEAR_BOARDS
    CALL CLEAR_BOARD_WIN
    JMP ONPLAY_CELL_END

ONPLAY_CELL_ADD_P2SCORE:
    ADD SECOND_PLAYER_SCORE,1
    CALL CLEAR_BOARDS
    CALL CLEAR_BOARD_WIN
    JMP ONPLAY_CELL_END

ONPLAY_CELL_SET_BOARDWIN:
    MOV SI, OFFSET BOARD_WIN
    MOV DX,0
    MOV DL,SELECTED_TABLE
    ADD SI,DX 
    MOV BYTE PTR [SI],BL
    JMP ONPLAY_CELL_CHECK_BOARDS
;--------------------------------------------------------------------------------------
;Funções relacionada a table

SET_SELECTED_TABLE:
    MOV SELECTED_TABLE,96
    JMP ONPLAY_CELL_END



CHECK_MINI_TABLES:
    
    MOV CX,0
    CHECK_MINI_LOOP:
        ; code here
        MOV AX,9
        MOV DX,0
        MOV DL,SELECTED_TABLE
        MUL DX
        ADD SI,AX
        CALL CHECK_WIN

        MOV SI, OFFSET BOARD_WIN
        MOV DX,0
        MOV DL,SELECTED_TABLE
        ADD SI,DX 
        MOV BYTE PTR [SI],AL
    
        INC CX
        CMP CX, 9
        JNE CHECK_MINI_END
    
CHECK_MINI_END:
    RET


;SI -> board
;CL -> symbol
;RETURN AX == 1 WIN 
CHECK_WIN:
    PUSH BP
    MOV BP,SP
    SUB SP,2
    MOV [BP-2],SI
    PUSH DX
    MOV DL,CL

    MOV CX,0
    CHECKWIN_ROWX:
        CMP BYTE PTR [SI], DL
        JNE CHECK_WIN_ROWX_END

        CMP BYTE PTR [SI+1], DL
        JNE CHECK_WIN_ROWX_END

        CMP BYTE PTR [SI+2], DL
        JNE CHECK_WIN_ROWX_END

        MOV AX,1
        JMP CHECKWIN_END
    CHECK_WIN_ROWX_END:
        ADD SI,3
        ADD CX,1
        CMP CX,3
        JNE CHECKWIN_ROWX


    MOV CX,0
    MOV SI,[BP-2]
    CHECKWIN_COLX:
        CMP BYTE PTR [SI], DL
        JNE CHECKWIN_COLX_END

        CMP BYTE PTR [SI+3], DL
        JNE CHECKWIN_COLX_END

        CMP BYTE PTR [SI+6], DL
        JNE CHECKWIN_COLX_END

        MOV AX,1
        JMP CHECKWIN_END
    CHECKWIN_COLX_END:
        INC SI
        ADD CX,1
        CMP CX,3
        JNE CHECKWIN_COLX
    MOV SI,[BP-2]
    CHECKWIN_DIAGONALS_E:
        CMP BYTE PTR [SI], DL
        JNE CHECKWIN_DIAGONALS_D

        CMP BYTE PTR [SI+4], DL
        JNE CHECKWIN_DIAGONALS_D

        CMP BYTE PTR [SI+8], DL
        JNE CHECKWIN_DIAGONALS_D

        MOV AX,1
        JMP CHECKWIN_END

    CHECKWIN_DIAGONALS_D:
        CMP BYTE PTR [SI+2], DL
        JNE CHECKWIN_DIAGONALS_D_END

        CMP BYTE PTR [SI+4], DL
        JNE CHECKWIN_DIAGONALS_D_END

        CMP BYTE PTR [SI+6], DL
        JNE CHECKWIN_DIAGONALS_D_END

        MOV AX,1
        JMP CHECKWIN_END

CHECKWIN_DIAGONALS_D_END:
    MOV AX,0
CHECKWIN_END:
    POP DX
    ADD SP,2
    MOV SP,BP
    POP BP 
    RET

;AH -> table index
;DH -> cell Y
;DL -> cell X
;CX -> return index = "("table+cellY+cellX")"
GET_CELL_POS:
    PUSH AX
    PUSH DX
    MOV AL, AH
    MOV AH,0
    MOV BX, 9
    MUL BX ;AX = 9 *  table index

    POP DX

    MOV CX,AX ; CX = 9 *  table index
    ADD CL,DL ; CX += cellX

    MOV AX,0
    MOV AL,DH
    MOV BX,3
    MUL BX
    ADD CX,AX ; CX += 3 * cellY
    POP AX
    RET

;AH -> table index
;DH -> cell Y
;DL -> cell X
;AL -> letter
WRITE_CELL:
    CALL GET_CELL_POS
    MOV SI, OFFSET BOARDS
    ADD SI,CX
    MOV BYTE PTR[SI],AL
    RET

CLEAR_BOARD_SELECTED:
    MOV SI, OFFSET BOARDS
    MOV AX, 0
    MOV AL, SELECTED_TABLE
    MOV BX, 9
    MUL BX
    ADD SI,AX

    MOV CX, 9              ; Set loop counter to 9
    MOV AL, " "            ; Set AL register to the space character
CLEAR_BOARD_SELECTED_LOOP:
    MOV AL, BYTE PTR [SI]   ; Load the character at [board + si] into AL
    CMP AL, 'K'                    ; Compare AL with 'K'
    JE CLEAR_BOARD_SELECTED_CHAR                  ; Jump to clear_char if equal
    CMP AL, 'L'                    ; Compare AL with 'L'
    JE CLEAR_BOARD_SELECTED_CHAR                  ; Jump to clear_char if equal
    INC SI                         ; Increment source index
    LOOP CLEAR_BOARD_SELECTED_LOOP                ; Loop until cx (loop counter) becomes 0
    RET    
                            ; Return from the function
CLEAR_BOARD_SELECTED_CHAR:
    MOV BYTE PTR [SI], ' '  ; Store a space character at [board + si]
    INC SI                          ; Increment source index
    LOOP CLEAR_BOARD_SELECTED_LOOP                 ; Loop until cx (loop counter) becomes 0
    RET 



;SI -> board 3x3=9
CLEAR_BOARDWIN_SELECTED:
    MOV CX,0
    CLEAR_BOARDWIN_LOOP:
        CMP BYTE PTR [SI], 4
        JNE CLEAR_BOARDWIN_LOOP_END
        MOV BYTE PTR [SI],0

        CLEAR_BOARDWIN_LOOP_END:
        INC SI
        INC CX
        CMP CX, 9
        JNE CLEAR_BOARDWIN_LOOP
    RET
        


CLEAR_BOARDS:
    MOV SI, OFFSET BOARDS
    MOV CX, 81                      
CLEAR_BOARD_LOOP:
    MOV BYTE PTR [SI], ' '  
    INC SI                        
    loop CLEAR_BOARD_LOOP               
    RET     
CLEAR_CHAR:
  MOV BYTE PTR [SI], al  
  INC SI


CLEAR_BOARD_WIN:
    MOV SI, OFFSET BOARD_WIN
    MOV CX, 9                
CLEAR_BOARD_WIN_LOOP:
    MOV BYTE PTR [SI], 0  
    INC SI                        
    loop CLEAR_BOARD_WIN_LOOP                
    RET  


DRAW_BOARDS:
    PUSH BP
    MOV BP,SP
    SUB SP,4

    MOV AH,03h;Get cursor position
    INT 10h; DH -> row | DL -> col | AX -> 0 | CH -> Start scan line | CL -> End Scan line
    
    MOV [BP-2],DX ; cursor position
    MOV AX,0
    MOV [BP-4],AX  ; table index


    MOV DX,0
    boardY:
        MOV CX,0
        PUSH DX
        startLoop:
            MOV AX ,[BP-4]
            PUSH CX
            CALL DRAW_BOARD

            MOV AX ,[BP-4]
            INC AX
            MOV [BP-4],AX

            MOV AH,03h;Get cursor position
            INT 10h; DH -> row | DL -> col | AX -> 0 | CH -> Start scan line | CL -> End Scan line

            MOV AH,02h;Set cursor position
            ADD DL,4
            INT 10h

            POP CX
            INC CX
            CMP CX, 3
            JNE startLoop

    PUSH DX
    MOV AH,03h;Get cursor position
    INT 10h; DH -> row | DL -> col | AX -> 0 | CH -> Start scan line | CL -> End Scan line
    MOV AX,[BP-2]
    ADD DH,4
    MOV DL,AL
    MOV AH,02h;Set cursor position
    INT 10h
    POP DX

    POP DX
    INC DX
    CMP DX, 3
    JNE boardY   

    ADD SP,4
    MOV SP,BP
    POP BP 
    RET


;AX -> table index
;SI -> pointer to array
DRAW_BOARD:
    PUSH BP
    MOV BP,SP
    SUB SP,4; 

    MOV [BP-4],AX

    MOV AH,03h;Get cursor position
    INT 10h; DH -> row | DL -> col | AX -> 0 | CH -> Start scan line | CL -> End Scan line
    MOV [BP-2],DX

    MOV CX,0 ; row
    rowloop:
        MOV DX,0
        colloop:
            MOV AX,[BP-2]
            PUSH DX ; Save Original DX
            ADD DL,AL ;col
            MOV DH,AH ;row
            ADD DH,CL
            MOV AH,02h;Set cursor position
            INT 10h
            POP DX
      



            MOV AH,09h;write character
            MOV AL,[SI]
            INC SI
            MOV BH,0

            ;MOV BX,07h; light gray color 

            CMP AL , 'K'
            JE SELECT_X

            CMP AL , 'L'
            JE SELECT_O

            CMP AL , 'X'
            JE BOARD_RED

            JMP BOARD_BLUE
            BOARD_RED:
                MOV BX, 0Ch; light red color 
                JMP BOARD_WRITE_CHAR
            BOARD_BLUE:
                MOV BX, 09h; light blue color 
        BOARD_WRITE_CHAR:
            PUSH CX
            MOV CX,01h; num times
            INT 10h


            POP CX

            INC DX
            CMP DX, 3
            JNE colloop
            
        INC CX
        CMP CX, 3
        JNE rowloop


    PUSH SI

    MOV DX,[BP-2]    
    MOV AH,02h;Set cursor position
    INT 10h

    ;Fill mini table if some player won
    MOV SI,OFFSET BOARD_WIN
    ADD SI,[BP-4]

    CMP BYTE PTR [SI], 0
    JE DRAW_BOARD_END


    MOV AX,8 ; multiplier
    ;Desenha o boardwin
    ; cord X
    MOV AL,8
    XOR CX,CX
    MOV CL,DL
    MUL CL ; AX = margin(al) * cursor(cl x)
    MOV CL,AL ; CL = resultado
 
     ;cord Y
    MOV AX,0
    MOV AL,DH 
    MOV DX,8
    MUL DX
    MOV DX,AX


    MOV SI,OFFSET BOARD_WIN
    ADD SI,[BP-4]
    CMP BYTE PTR [SI], 1
    JE DRAW_BOARD_RED

    CMP BYTE PTR [SI], 2
    JE DRAW_BOARD_BLUE

    JMP DRAW_BOARD_GRAY

    DRAW_BOARD_WIN:
    MOV BX,24
    MOV Si,24
    CALL DRAW_FILL_RECT




DRAW_BOARD_END:
    POP SI
    ADD SP,4
    MOV SP,BP
    POP BP 
    RET 
SELECT_X:
    MOV BX,07h; light gray color 
    MOV AL,'X'
    JMP BOARD_WRITE_CHAR

SELECT_O:
    MOV BX,07h; light gray color 
    MOV AL,'O'
    JMP BOARD_WRITE_CHAR 

DRAW_BOARD_RED:
    MOV AX,0Ch; light red color 
    JMP DRAW_BOARD_WIN

DRAW_BOARD_BLUE:
    MOV AX,09h; light blue color 
    JMP DRAW_BOARD_WIN

DRAW_BOARD_GRAY:
    MOV AL,07h; light gray color 
    JMP DRAW_BOARD_WIN

;--------------------------------------------------------------------------------
;Funçoes de utilidade


;CX -> comprimento da string
;SI -> dest
;DI -> src
COPY_STRING:
MOV AL, [DI]
MOV [SI], AL
INC SI
INC DI
LOOP COPY_STRING
RET

;AX -> number
PRINT_NUM:
    MOV DX,0
    MOV BX,10 ; divisor
    MOV CX,0 
    CMP AX, 0
    JGE DIGITS_LOOP ;se numero for positivo ja vai pro loop

    PUSH AX
    MOV AH, 02h
    MOV DL, '-'
    INT 21h
    POP AX



    ;coloca o numeoro negativo para positivo
    NOT AX ;inverte os bits
    ADD AX , 1 ; adiciona 1
    MOV DX,0


    ;consegue os digitos e pusha para stack
    DIGITS_LOOP:
        IDIV BX ;dx onde vai ficar resto tem estar 0 quando se faz divisão
        PUSH DX
        INC CX
        MOV DX,0
        CMP AX, 0
        JG DIGITS_LOOP
    

    PRINT_NUM_LOOP:
        POP DX
        ADD DL ,'0'
    
        MOV AH, 02h
        INT 21h

        DEC CX
        CMP CX, 0
        JG PRINT_NUM_LOOP
    RET


CLEAR_SCREEN:
    MOV AX, 0A000h  ; Set ES to point to the video memory segment
    MOV ES, AX
    MOV DI, 0       ; Set DI to the start of the video memory
    MOV CX, 320*200 ; Set CX to the total number of pixels on the screen
    MOV AL, 0       ; Set AL to the black color index
    REP STOSB       ; Use REP STOSB to set all pixels to black
    RET

;CX -> x
;DX -> y
;AL -> color   
;BX -> width
;SI -> height         
 DRAW_FILL_RECT:
    PUSH BP
    MOV BP,SP
    SUB SP,4; 
    MOV [BP-2],CX ; x
    MOV [BP-4],DX ; y
    ADD BX,CX ; width+x
    ADD SI,DX
    MOV BH,00h ; page number
    widthloop:
         MOV DX, [BP-4]
         MOV AH,0Ch ; draw pixel
         INT 10h
         heightloop:
             MOV AH,0Ch ; draw pixel
             INT 10h
             INC DX
             CMP DX, SI
             JNE heightloop
         INC CX
         CMP CX, BX
         JNE widthloop
    ADD SP,4
    MOV SP,BP
    POP BP 
    RET


;SI -> pointer to string
;AX -> return string lenght
STRLEN:
    PUSH CX
    MOV CX, 0

    ; Loop until null terminator is found
    LOOP_START:
        LODSB ; Load character from string and increment SI
        CMP AL, 0 ; Check for null terminator
        JE LOOP_END ; Exit loop if null terminator is found
        INC CX 
        JMP LOOP_START
    LOOP_END:
        DEC CX ; Exclude null terminator from length
        MOV AX, CX ; Move length into AX register
        POP CX
        RET 

BREAK_LINE:
    MOV AH,03h;Get cursor position
    INT 10h; DH -> row | DL -> col | AX -> 0 | CH -> Start scan line | CL -> End Scan line
    INC DH
    MOV DL,0
    MOV AH,02h;Set cursor position
    INT 10h
    RET 

;to change x,y use "Set cursor position"
;BL -> color
;SI -> pointer to string | string must end with 0
DRAW_STRING:
    MOV AH,03h
    MOV BH,00h
    INT 10h


    DRAW_STRING_LOOP:
        LODSB ; Load character from string and increment SI
        
        MOV AH,02h;Set cursor position | DH -> row | DL -> col
        INT 10h

        MOV AH,09h         ; Draw character
        MOV BH,00h
        MOV CX,01h; num times
        INT 10h
        INC DL
        CMP AL, 0 ; Check for null terminator
        JE DRAW_STRING_LOOP_END ; Exit loop if null terminator is found
        JMP DRAW_STRING_LOOP
    DRAW_STRING_LOOP_END:
        RET

;CX -> Min
;BX -> Max
;Return AX 
RANDOM_NUM:
    PUSH CX
    ;RANGE  (max-min)+1
    SUB BX,CX
    INC BX

    MOV AH, 00H ; Read System Clock Counter
    INT 1AH ;DX Low tick
  
    MOV AX,DX
    XOR DX,DX

    IDIV BX  ; AX / DX || quotient - AX | remainder - DX

    POP CX
    MOV AX,CX ; ax = min
    ADD AX,DX ; ax += ('rand()' % range)
    RET

CODE ENDS
END START
