.8086
.MODEL SMALL
.STACK 2048

;Ultimat tic tac toe
;1 - Player vs Player
;2 - Player vs Computer




DATA SEGMENT
    IS_RUNNING DB 1
    CURRENT_GAMEMODE DB 0 ; o modo de jogo atual | 0 -> player vs player | 1 -> player vs computer

    BOARDS db 9 dup (9 dup (' ')) ; os tabuleiros
    SELECTED_TABLE DB 0 ; indica qual tabela esta selecionada
    CURRENT_PLAYER DB 0 ; indica qual é o player que esta jogar
    CURRENT_CHECK_POS DB 0 ; indica a posição do X ao jogar
    BOARD_WIN db 9 dup (0) ; indica tabelas que estão ganhas

    FIRST_PLAYER_NAME DB 32 dup(0)
    SECOND_PLAYER_NAME DB 32 dup(0)
    SEPARATOR_NAME DB ' : ',0

    FIRST_PLAYER_SCORE DW 1337
    SECOND_PLAYER_SCORE DW 1338


    CURRENT_SCREEN_INDEX DB 0

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


DATA ENDS


CODE SEGMENT PARA 'CODE'
   ASSUME CS:CODE, DS:DATA

   

   START:
        MOV AX,DATA
        MOV DS,AX

        MOV AH,00h ;setVideoMode
        MOV AL,13h ; https://stanislavs.org/helppc/int_10-0.html
        INT 10h
 

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
        
        ;replace last letter with null terminator
        MOV AX,0
        ADD AL,[FIRST_PLAYER_NAME+1]
        MOV SI,OFFSET FIRST_PLAYER_NAME
        ADD SI,2
        ADD SI,AX
        MOV CX,0
        MOV [SI],CX

        CALL BREAK_LINE

        MOV BL,09h; light blue color 
        MOV SI,OFFSET INPUT_SECONDNAME
        CALL DRAW_STRING


        MOV AH, 0Ah ; read string
        LEA DX, SECOND_PLAYER_NAME ; SECOND_PLAYER_NAME+0 -> size array | SECOND_PLAYER_NAME+1 -> entered characters
        MOV SECOND_PLAYER_NAME,32 ; size array
        INT 21h
        CALL BREAK_LINE

        ;replace last letter with null terminator
        MOV AX,0
        ADD AL,[SECOND_PLAYER_NAME+1]
        MOV SI,OFFSET SECOND_PLAYER_NAME
        ADD SI,2
        ADD SI,AX
        MOV CX,0
        MOV [SI],CX








        ;TODO : falta perguntar os nomes
        JMP GAMEMODE_EVENTS_END
    GAMEMODE_PVC: ;  player vs computer
        MOV CURRENT_GAMEMODE,1
        MOV CURRENT_SCREEN_INDEX,2
        ;TODO : falta perguntar os nomes
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
        JMP STARTMENU_EVENTS_END
    STARTMENU_CONTINUE:
        MOV CURRENT_SCREEN_INDEX,1;muda para o menu gamemode
        JMP STARTMENU_EVENTS_END
    STARTMENU_EXIT:
        MOV IS_RUNNING,0
        JMP STARTMENU_EVENTS_END

STARTMENU_EVENTS_END:
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

    CMP AL , 'w'
    JE UP_KEY

    CMP AL, 'W'     
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


;------------------------------------------------------------------------------------------------------


GAME_RENDER:
    MOV AH,02h;Set cursor position
    MOV DH,8h;row
    MOV DL,10h;col
    INT 10h

    MOV BL,09h; light blue color 
    MOV SI, offset FIRST_PLAYER_NAME+2
    CALL DRAW_STRING

    MOV SI, offset SEPARATOR_NAME ; " : "
    CALL DRAW_STRING

    MOV AX , FIRST_PLAYER_SCORE
    CALL PRINT_NUM


    MOV AH,02h;Set cursor position
    MOV DH,6h;row
    MOV DL,10h;col
    INT 10h

    MOV BL,0Ch; light red color 
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

GAME_EVENTS:
    MOV AH, 01h;read char
    INT 21h;al 




    GAME_EVENTS_END:
        RET

;--------------------------------------------------------------------------------------


DRAW_BOARDS:
    PUSH BP
    MOV BP,SP
    SUB SP,2;

    MOV AH,03h;Get cursor position
    INT 10h; DH -> row | DL -> col | AX -> 0 | CH -> Start scan line | CL -> End Scan line
    MOV [BP-2],DX

    MOV DX,0
    boardY:
        MOV CX,0
        PUSH DX
        startLoop:
            PUSH CX
            CALL DRAW_BOARD

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

    ADD SP,2
    MOV SP,BP
    POP BP 
    RET
;SI -> pointer to array
DRAW_BOARD:
    PUSH BP
    MOV BP,SP
    SUB SP,2; 

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
            MOV BX,04h; red color
            MOV BH,0
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


    MOV DX,[BP-2]    
    MOV AH,02h;Set cursor position
    INT 10h

    ADD SP,2
    MOV SP,BP
    POP BP 
    RET 





;--------------------------------------------------------------------------------
;Funçoes de utilidade


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
CODE ENDS
END START
    