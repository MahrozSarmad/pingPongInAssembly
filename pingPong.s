[org 100h]
jmp Start

; Data segment
Time_Aux db 0

Ball_X dw 0Ah
Ball_Y dw 0Ah
Ball_Size dw 04h

BallVelocity_X dw 05h      ; Horizontal Velocity
BallVelocity_Y dw 02h      ; Vertical Velocity
Ball_Original_X dw 0A0h    ; Center of screen (160)
Ball_Original_Y dw 64h     ; Middle of screen (100)

; Left Paddle Data
Paddle_Left_X dw 0h       ; Move paddle bit away from edge (20 pixels)
Paddle_Left_Y dw 50h       ; Start paddle in middle-ish (80 pixels)
Paddle_Width dw 05h
Paddle_Height dw 1Fh       ; Increased paddle height for better playability

; Right Paddle Data
Paddle_Right_X dw 13Bh     ; 304 pixels (320-16) from left
Paddle_Right_Y dw 50h      ; Start at same height as left paddle
Player_One_Points db 0
Player_Two_Points db 0

Winner db 0 ; Indicates which player is the Winner(1->Player1 & 2->Player 2)
Game_Active db 1 ; Check Whether game is active or not?(1->Yes, 0-> No)
Exit_Status db 0
Pause_Active db 0 ; Pause state
Currently_Active db 1 ; (0->Main Menu & 1->Game)

Game_Over db 'GAME OVER' ,'$'
Restart_Text db 'Press R to Restart' ,'$'
winner_Text db 'Player 0 Won','$'
Text_Player1_Points db '0','$'  ; text with the player one points
Text_Player2_Points db '0','$'  ; text with the player two points
Main_Menu_Text db 'Press E to Exit to Main Menu' ,'$'
Main_Menu_Title db 'MAIN MENU','$'
Main_Menu_Exit db  'E.EXIT GAME','$'
Welcome_Text db 'Paddle Up, Player Ready!' ,'$'
Play_Button db 'S.Start The Game','$'
Made_By db 'Games By AM Productions' ,'$'
Starting db 'Paddle Up, Player Ready!','$'
; Reset ball to center
Reset_Ball_Position:
    mov ax, [Ball_Original_X]
    mov [Ball_X], ax
    mov ax, [Ball_Original_Y]
    mov [Ball_Y], ax
    ret

; Draw both paddles
Draw_Paddles:
    mov ah, 0Ch            ; Draw pixel
    mov al, 0Fh            ; Color white
    mov bh, 00h            ; Page 0
    push cx
    push dx

    ; Draw Left Paddle
Left_Paddle:
    mov cx, [Paddle_Left_X]
    mov dx, [Paddle_Left_Y]

    mov si, cx
    add si, [Paddle_Width]
    mov di, dx
    add di, [Paddle_Height]

Left_Paddle_Y:
    mov cx, [Paddle_Left_X]
Left_Paddle_X:
    int 10h
    inc cx
    cmp cx, si
    jl Left_Paddle_X

    inc dx
    cmp dx, di
    jl Left_Paddle_Y

    ; Draw Right Paddle
Right_Paddle:
    mov cx, [Paddle_Right_X]
    mov dx, [Paddle_Right_Y]

    mov si, cx
    add si, [Paddle_Width]
    mov di, dx
    add di, [Paddle_Height]

Right_Paddle_Y:
    mov cx, [Paddle_Right_X]
Right_Paddle_X:
    int 10h
    inc cx
    cmp cx, si
    jl Right_Paddle_X

    inc dx
    cmp dx, di
    jl Right_Paddle_Y

    pop dx
    pop cx
    ret

; Check collisions with both paddles
Check_Paddle_Collision:
    ; Check left paddle collision
    mov ax, [Ball_X]
    mov bx, [Paddle_Left_X]
    add bx, [Paddle_Width]

    cmp ax, [Paddle_Left_X]
    jl Check_Right_Paddle
    cmp ax, bx
    jg Check_Right_Paddle

    mov ax, [Ball_Y]
    mov bx, [Paddle_Left_Y]
    add bx, [Paddle_Height]

    cmp ax, [Paddle_Left_Y]
    jl Check_Right_Paddle
    cmp ax, bx
    jg Check_Right_Paddle

    ; Left paddle collision detected
    neg word [BallVelocity_X]
    add word [Ball_X], 5
    jmp No_Collision

Check_Right_Paddle:
    ; Check right paddle collision
    mov ax, [Ball_X]
    mov bx, [Paddle_Right_X]
    add bx, [Paddle_Width]

    cmp ax, [Paddle_Right_X]
    jl No_Collision
    cmp ax, bx
    jg No_Collision

    mov ax, [Ball_Y]
    mov bx, [Paddle_Right_Y]
    add bx, [Paddle_Height]

    cmp ax, [Paddle_Right_Y]
    jl No_Collision
    cmp ax, bx
    jg No_Collision

    ; Right paddle collision detected
    neg word [BallVelocity_X]
    sub word [Ball_X], 5

No_Collision:
    ret

; Update Ball position
Update_Position:
    mov ax, [Ball_X]
    add ax, [BallVelocity_X]
    mov [Ball_X], ax

    mov ax, [Ball_Y]
    add ax, [BallVelocity_Y]
    mov [Ball_Y], ax

    ; Check X boundaries and reset if past right side
    cmp word [Ball_X], 316
    jl Check_Left_X

Give_Points_To_player_one:
    inc byte[Player_One_Points]
    call Reset_Ball_Position
    call Update_Player_One
    cmp byte[Player_One_Points], 6
    je GameOver
    jmp Check_Y

Check_Left_X:
    cmp word [Ball_X], 0
    jg Check_Y

Give_Points_to_Player_two:
    inc byte[Player_Two_Points]
    call Reset_Ball_Position
    call Update_Player_Two
    cmp byte[Player_Two_Points], 6
    je GameOver

Check_Y:
    cmp word [Ball_Y], 196
    jl Check_Top_Y
    neg word [BallVelocity_Y]
    mov word [Ball_Y], 196
    jmp Done_Update

Check_Top_Y:
    cmp word [Ball_Y], 0
    jg Done_Update
    neg word [BallVelocity_Y]
    mov word [Ball_Y], 0
    jmp Done_Update

GameOver:
    cmp byte[Player_One_Points],05h
    jnl Winner1
    jmp Winner2

Winner1:
    mov byte[Winner],01h
    jmp Continue
Winner2:
    mov byte[Winner],02h
    jmp Continue
Continue:
    mov byte[Player_One_Points], 0
    mov byte[Player_Two_Points], 0
    call Update_Player_One
    call Update_Player_Two
    mov byte[Game_Active],00h
    call Reset_Ball_Position
    call Clear_Screen
    call Menu
    jmp Done_Update

Update_Player_One:
    xor ax, ax
    mov al, [Player_One_Points]
    add al, 30h
    mov [Text_Player1_Points], al
    ret

Update_Player_Two:
    xor ax, ax
    mov al, [Player_Two_Points]
    add al, 30h
    mov [Text_Player2_Points], al
    ret

Done_Update:
    ret

; Draw the ball
Draw_Ball:
    mov ah, 0Ch      ; Draw pixel
    mov al, 0Fh      ; Color white
    mov bh, 00h      ; Page 0
    push cx
    push dx

    mov cx, [Ball_X] ; X position
    mov dx, [Ball_Y] ; Y position

    mov si, cx
    add si, 4        ; End X
    mov di, dx
    add di, 4        ; End Y

Draw_Y:
    mov cx, [Ball_X] ; Reset X for each row
Draw_X:
    int 10h          ; Draw pixel
    inc cx
    cmp cx, si
    jl Draw_X

    inc dx
    cmp dx, di
    jl Draw_Y

    pop dx
    pop cx
    ret

Draw_User_Interface:
    ;Points of the Player 1(Left_One)
Left:
    mov ah, 02h    ; set cursor position
    mov bh, 00h    ; page number
    mov dh, 03h    ; row
    mov dl, 06h    ; column
    int 10h

mov si, Text_Player1_Points

print_loop:
    mov al, [si]
    cmp al, '$'    ; check for string terminator
    je Right
    mov ah, 0Eh    ; BIOS teletype output
    mov bl, 0FH    ; color (bright red)
    int 10h
    inc si
    jmp print_loop
Right:
    mov ah, 02h    ; set cursor position
    mov bh, 00h    ; page number
    mov dh, 03h    ; row
    mov dl, 20h    ; column
    int 10h

mov si, Text_Player2_Points

Print_loop:
    mov al, [si]
    cmp al, '$'    ; check for string terminator
    je Done
    mov ah, 0Eh    ; BIOS teletype output
    mov bl, 0Fh    ; color (bright red)
    int 10h
    inc si
    jmp Print_loop
Done:
    ret

; Handle both paddle movements
Move_Paddles:
    mov ah, 01h              ; Check if key is pressed
    int 16h
    jz Done_Move_Paddles     ; If no key, skip movement

    mov ah, 00h              ; Get the key
    int 16h

    ; Pause game when 'P' or 'p' is pressed
    cmp al, 'P'
    je Toggle_Pause
    cmp al, 'p'
    je Toggle_Pause

    ; Skip paddle movement if game is paused
    cmp byte[Pause_Active], 1
    je Done_Move_Paddles

    ; Left Paddle Controls
    cmp ah, 11h             ; 'W' key for left paddle up
    je Move_Left_Paddle_Up
    cmp ah, 1Fh             ; 'S' key for left paddle down
    je Move_Left_Paddle_Down

    ; Right Paddle Controls
    cmp ah, 48h             ; Up arrow for right paddle up
    je Move_Right_Paddle_Up
    cmp ah, 50h             ; Down arrow for right paddle down
    je Move_Right_Paddle_Down

    jmp Done_Move_Paddles

Toggle_Pause:
    not byte[Pause_Active]   ; Toggle between 0 and 1
    and byte[Pause_Active], 1 ; Ensure only 0 or 1
    jmp Done_Move_Paddles

Move_Left_Paddle_Up:
    cmp word [Paddle_Left_Y], 0
    jle Done_Move_Paddles
    sub word [Paddle_Left_Y], 5
    jmp Done_Move_Paddles

Move_Left_Paddle_Down:
    mov ax, [Paddle_Left_Y]
    add ax, [Paddle_Height]
    cmp ax, 200
    jge Done_Move_Paddles
    add word [Paddle_Left_Y], 5
    jmp Done_Move_Paddles

Move_Right_Paddle_Up:
    cmp word [Paddle_Right_Y], 0
    jle Done_Move_Paddles
    sub word [Paddle_Right_Y], 5
    jmp Done_Move_Paddles

Move_Right_Paddle_Down:
    mov ax, [Paddle_Right_Y]
    add ax, [Paddle_Height]
    cmp ax, 200
    jge Done_Move_Paddles
    add word [Paddle_Right_Y], 5

Done_Move_Paddles:
    ret

; Clear screen procedure
Clear_Screen:
    mov ax, 0A000h       ; Set ES to point to video memory
    mov es, ax
    xor di, di           ; Start at the beginning of video memory
    mov al, 1           ; Color (black or dark gray)
    mov cx, 320 * 200    ; Total number of pixels in 320x200 resolution
    rep stosb            ; Fill all pixels with the specified color
    ret

ClearScreen:
    mov ah, 00h      ; Set video mode
    mov al, 13h      ; Mode 13h again to clear
    int 10h
    ret


Menu:
   Call Clear_Screen

   ; Show the Game over Menu
    mov ah, 02h    ; set cursor position
    mov bh, 00h    ; page number
    mov dh, 03h    ; row
    mov dl, 0Fh    ; column
    int 10h

mov si, Game_Over

PRint_loop:
    mov al, [si]
    cmp al, '$'    ; check for string terminator
    je R
    mov ah, 0Eh    ; BIOS teletype output
    mov bl, 1Fh    ; color (bright red)
    int 10h
    inc si
    jmp PRint_loop
R:
    call Decide_Winner

    ; Show the Winner
     mov ah,02h  ;set the cursor position
     mov bh ,00h ; set page number
     mov dh ,05h ; se row
     mov dl ,0Eh ; set column
     int 10h

    mov si, winner_Text

PRint_Loop:
    mov al, [si]
    cmp al, '$'    ; check for string terminator
    je L
    mov ah, 0Eh    ; BIOS teletype output
    mov bl, 0Fh    ; color (bright red)
    int 10h
    inc si
    jmp PRint_Loop
L:
     mov ah,02h  ;set the cursor position
     mov bh ,00h ; set page number
     mov dh ,07h ; se row
     mov dl ,0Bh ; set column
     int 10h

    mov si, Restart_Text

PRint_LOop:
    mov al, [si]
    cmp al, '$'    ; check for string terminator
    je U
    mov ah, 0Eh    ; BIOS teletype output
    mov bl, 0Fh    ; color (bright red)
    int 10h
    inc si
    jmp PRint_LOop

U:

     mov ah,02h  ;set the cursor position
     mov bh ,00h ; set page number
     mov dh ,09h ; se row
     mov dl ,08h ; set column
     int 10h

    mov si, Main_Menu_Text

Print_Loop:
    mov al, [si]
    cmp al, '$'    ; check for string terminator
    je D
    mov ah, 0Eh    ; BIOS teletype output
    mov bl, 0Fh    ; color (bright red)
    int 10h
    inc si
    jmp Print_Loop
D:
    ; waits for the key Press
    mov ah ,00h
    int 16h

    cmp al,'R'
    je Restart
    cmp al,'r'
    je Restart

    cmp al,'E'
    je Exit
    cmp al,'e'
    je Exit
	jmp D
Exit:
     mov byte[Game_Active],00h
     mov byte[Currently_Active],00h
     ret
Restart:
    mov byte[Game_Active],01h
    ret

Decide_Winner:
    mov Al ,[Winner]
    add al,30h
    mov [winner_Text+7],al
    ret

Draw_Main_Menu:
   call Clear_Screen

    mov ah,02h  ;set the cursor position
     mov bh ,00h ; set page number
     mov dh ,03h ; se row
     mov dl ,0Fh ; set column
     int 10h

    mov ah ,09h ;write string to the standard output
    lea dx,[Main_Menu_Title]
    int 21h   ;print the string


     mov ah,02h  ;set the cursor position
     mov bh ,00h ; set page number
     mov dh ,05h ; se row
     mov dl ,0Eh ; set column
     int 10h

    mov ah ,09h ;write string to the standard output
    lea dx,[Main_Menu_Exit]
    int 21h   ;print the string

    mov ah,00h
    int 16h

    cmp al,'E'
    je Exiting
    cmp al,'e'
    je Exiting
	jmp Draw_Main_Menu

Exiting:
    mov byte[Exit_Status],01h
    ret

; Program entry point
Start:
    mov ax, 0013h    ; Set video mode 13h (320x200)
    int 10h
	call Clear_Screen



	mov ah,02h  ;set the cursor position
    mov bh ,00h ; set page number
    mov dh ,04h ; se row
    mov dl ,7h ; set column
    int 10h

	mov si ,Starting
Printt:
   mov al,[si]
   cmp al,'$'
   je R0
   mov ah, 0Eh    ; BIOS teletype output
   mov bl, 0Fh    ; color (bright red)
   int 10h
   inc si
   jmp Printt
R0
	mov ah,02h  ;set the cursor position
    mov bh ,00h ; set page number
    mov dh ,0Dh ; se row
    mov dl ,0Eh ; set column
    int 10h

	mov si ,Main_Menu_Exit
Print:
   mov al,[si]
   cmp al,'$'
   je R1
   mov ah, 0Eh    ; BIOS teletype output
   mov bl, 0Fh    ; color (bright red)
   int 10h
   inc si
   jmp Print
R1:

  mov ah,02h  ;set the cursor position
    mov bh ,00h ; set page number
    mov dh ,17h ; se row
    mov dl ,09h ; set column
    int 10h

	mov si ,Made_By
print:
   mov al,[si]
   cmp al,'$'
   je R2
   mov ah, 0Eh    ; BIOS teletype output
   mov bl, 0Fh    ; color (bright red)
   int 10h
   inc si
   jmp print
R2:
    mov ah,02h  ;set the cursor position
    mov bh ,00h ; set page number
    mov dh ,0Bh ; se row
    mov dl ,0Ch ; set column
    int 10h

	mov si ,Play_Button
Prints:
   mov al,[si]
   cmp al,'$'
   je R3
   mov ah, 0Eh    ; BIOS teletype output
   mov bl, 0Fh    ; color (bright red)
   int 10h
   inc si
   jmp Prints


R3:
   mov ah ,00h
   int 16h
   cmp al ,'S'
   je Main_Loop
   cmp al ,'s'
   je Main_Loop

  ; cmp al ,'E'
   ;je End_Program
   cmp al ,'e'
   je End_Program
  jmp Start
; Main game loop
Main_Loop:
    cmp byte[Exit_Status],01h
    je End_Program
    cmp byte[Currently_Active],00h
    je Show_Main_Menu

    cmp byte[Game_Active],00h
    je Display_Game_Over

    call Move_Paddles

    ; If game is paused, skip updates and just keep drawing current state
    cmp byte[Pause_Active], 1
    je Draw        ; Skip updates if paused, just keep drawing current frame

    ; Check time
    mov ah, 2Ch
    int 21h

    cmp dl, [Time_Aux]
    je Main_Loop

    mov [Time_Aux], dl

    call Clear_Screen
    call Check_Paddle_Collision
    call Update_Position

Draw:
    call Draw_Ball
    call Draw_Paddles
    call Draw_User_Interface

    ; Check if game is paused and draw pause indicator
    cmp byte[Pause_Active], 1
    jne Skip_Pause_Text

    ; Set cursor position for pause text
    mov ah, 02h
    mov bh, 00h
    mov dh, 12    ; Row
    mov dl, 17   ; Column
    int 10h

    ; Display "PAUSED"
    mov ah, 0Eh
    mov bl, 0Fh
    mov al, 'P'
    int 10h
    mov al, 'A'
    int 10h
    mov al, 'U'
    int 10h
    mov al, 'S'
    int 10h
    mov al, 'E'
    int 10h
    mov al, 'D'
    int 10h

Skip_Pause_Text:
    jmp Main_Loop

Display_Game_Over:
     call Menu
     jmp Main_Loop

Show_Main_Menu:
        call Draw_Main_Menu
        jmp Main_Loop

End_Program:
   call Clear_Screen
    mov ax, 0003h    ; Set video mode back to text mode
    int 10h
    mov ax, 4C00h    ; Exit to DOS
    int 21h