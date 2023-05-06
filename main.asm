.8086
.MODEL SMALL
.STACK 2048


DATA SEGMENT
    BOARDS db 9 dup (9 dup ('X')) ; os tabuleiros
    SELECTED_TABLE DB 0 ; indica qual tabela esta selecionada
    CURRENT_PLAYER DB 0 ; indica qual é o player que esta jogar
    BOARD_WIN db 9 dup (0) ; indica tabelas que estão ganhas

    FIRST_PLAYER_NAME DB '0 : Joao',0
    SECOND_PLAYER_NAME DB '0 : Manuel',0
DATA ENDS


CODE SEGMENT PARA 'CODE'
   ASSUME CS:CODE, DS:DATA

   START:
        MOV AX,DATA
        MOV DS,AX

        MOV AH,00h ;setVideoMode
        MOV AL,13h ; https://stanislavs.org/helppc/int_10-0.html
        INT 10h
 
        
        CALL ON_RENDER
        GAME_LOOP:
            JMP GAME_LOOP
      

        MOV AH,4Ch ; end program
        INT 21h

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
    