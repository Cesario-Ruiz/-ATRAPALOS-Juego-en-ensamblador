;                                  -> [PIXEL] <-                                                 ||
;Proyecto: Videojuego.                                                                           ||
;Integrantes: Luciano Cruz Carlos Ivan, Hernandez Flores Cristian Emanuel, Ruíz De La Cruz César.||
;=================================================================================================°

org 0x100 ; Especial de DOSbox.
section .data
    mensaje_advertencia db 0x1B, '[32;1;5mATRAPALOS!!!', 0x1B, '[0m$'  ; Mensaje con escape ANSI
    jugador db 0x01, '$'
    posicion_del_jugador_x db 40
    posicion_del_jugador_y db 19
    borde_del_escenario db 0x1B, '[46;36m', 0xB2, 0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0xB2, 0xB2,  0xB2, 0x1B,'[0m$'

section .text
_start:

    call limpiar_la_pantalla
    mov ah, 09h
    mov dx, mensaje_advertencia
    int 21h

    call preciona_enter

    call imprimir_esceneario    ; Llamada a subrutina.

    call bucle_del_juego    ;Llamada a subrutina.

    call preciona_enter

    ; Finaliza la ejecución, de mientras*... <-
    mov ah, 4Ch
    int 21h


imprimir_esceneario: ; Limpia la pantalla y empieza a imprimir el escenario (#)
    mov dh, 20 ; Fila
    mov dl, 0  ; Columna -> ojo con...
    call posicionar_cursor

    mov ah, 09h
    mov dx, borde_del_escenario
    int 21h
    ret

bucle_del_juego:  ; Como el juego no tiene fin, se ejecuta en bucle.

    call mover_jugador
    ret

limpiar_la_pantalla:
    mov ax, 0003h
    int 10h
    ret

preciona_enter:
    mov ah, 00h
    int 16h
    cmp al, 0Dh
    jne preciona_enter
    ret

posicionar_cursor: ; Retiene el cursor en una posicion que se especifica antes...
    mov ah, 02h
    mov bh, 0
    int 10h
    ret

mover_jugador:

    ret
