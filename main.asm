.8086
.MODEL SMALL
.STACK 2048



;Ultimat tic tac toe
;1 - Player vs Player
;2 - Player vs Computer




DATA SEGMENT
    BOARDS db 9 dup (9 dup ('X')) ; os tabuleiros
    SELECTED_TABLE DB 0 ; indica qual tabela esta selecionada
    CURRENT_PLAYER DB 0 ; indica qual é o player que esta jogar
    BOARD_WIN db 9 dup (0) ; indica tabelas que estão ganhas

    FIRST_PLAYER_NAME DB '0 : Joao',0
    SECOND_PLAYER_NAME DB '0 : Manuel',0



    CURRENT_SCREEN_INDEX DB 'text',"$"

    CURRENT_ITEM_INDEX DB 0
    MENU_SELECTED DB '-> ',0
    MENU_TITLE DB 'Ultimate TicTacToe',0

    MENU_HELP DB 'Use w ou s para navegar pelo menu',0
    MENU_HELP2 DB 'Use enter para confirmar selecao',0

    STARTMENU_ITEMS:
        DB 'Novo Jogo',0
        DB 'Continuar Jogo',0
        DB 'Sair do jogo',0
    STARTMENU_SIZE DB 3

    MODE_MENU_ITEMS:
        DB 'Jogador vs Jogador',0
        DB 'Jogador vs Computador',0
        DB 'Voltar para o menu',0
    MODE_MENU_SIZE DB 3


DATA ENDS


CODE SEGMENT PARA 'CODE'
   ASSUME CS:CODE, DS:DATA

   START:
        MOV AX,DATA
        MOV DS,AX

        MOV AH,00h ;setVideoMode
        MOV AL,13h ; https://stanislavs.org/helppc/int_10-0.html
        INT 10h
 
        ;CALL ON_RENDER
        ;CALL ON_GAME_RENDER
        

        GAME_LOOP:
            MOV AX, 0A000h  ; Set ES to point to the video memory segment
            MOV ES, AX
            MOV DI, 0       ; Set DI to the start of the video memory
            MOV CX, 320*200 ; Set CX to the total number of pixels on the screen
            MOV AL, 0       ; Set AL to the black color index
            REP STOSB       ; Use REP STOSB to set all pixels to black
            


            CALL MENU_RENDER
            JMP GAME_LOOP
      

        MOV AH,4Ch ; end program
        INT 21h







;Draw menu with items
;SI -> pointer items
;AX -> size items
MENU_RENDER:
    MOV AH,02h;Set cursor position
    MOV DH,0h;row
    MOV DL,0h;col
    INT 10h
    
    MOV BL,07h; light gray color 
    MOV SI,OFFSET MENU_TITLE
    CALL DRAW_STRING
    CALL BREAK_LINE
    CALL BREAK_LINE

    MOV CX,0
    MOV SI, OFFSET STARTMENU_ITEMS
    MOV BL,0Fh; white color
    ITEM_LOOP:
        PUSH CX
        
        CMP CL,CURRENT_ITEM_INDEX
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
        CMP CL, STARTMENU_SIZE
        JNE ITEM_LOOP


    CALL BREAK_LINE
    MOV BL,07h; light gray color 
    MOV SI,OFFSET MENU_HELP
    CALL DRAW_STRING
    CALL BREAK_LINE

    MOV SI,OFFSET MENU_HELP2
    CALL DRAW_STRING

    CALL MENU_EVENTS
    RET

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
    JE DOWN_KEY

    JMP MENU_EVENTS_END
    DOWN_KEY:
        MOV DL,STARTMENU_SIZE
        DEC DL 
        CMP CURRENT_ITEM_INDEX, DL
        JE MENU_EVENTS_END ; se chegou ao limite vai pro fim

        INC CURRENT_ITEM_INDEX
        JMP MENU_EVENTS_END

    UP_KEY:
        CMP CURRENT_ITEM_INDEX,0
        JE MENU_EVENTS_END

        DEC CURRENT_ITEM_INDEX
        JMP MENU_EVENTS_END
MENU_EVENTS_END:
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
ON_RENDER:
    MOV AH,02h;Set cursor position
    MOV DH,8h;row
    MOV DL,10h;col
    INT 10h

    MOV BL,09h; light blue color 
    MOV SI, offset FIRST_PLAYER_NAME
    CALL DRAW_STRING

    MOV AH,02h;Set cursor position
    MOV DH,6h;row
    MOV DL,10h;col
    INT 10h

    MOV BL,0Ch; light red color 
    MOV SI, offset SECOND_PLAYER_NAME
    CALL DRAW_STRING

    
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
    SUB SP,2; "Alloc" six bytes in stack

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
    