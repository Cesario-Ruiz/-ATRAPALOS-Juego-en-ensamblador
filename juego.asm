;                                  -> [PIXEL] <-                                                 ||
;Proyecto: Videojuego.                                                                           ||
;                           -->  [ VERSION FINAL ]  <--                                          ||
;                                                                                                ||
;Integrantes: Luciano Cruz Carlos Ivan, Hernandez Flores Cristian Emanuel, Ruíz De La Cruz César.||
;=================================================================================================°

org 0x100
; se agrego una subrutina para salir...
section .data
    mensaje_inicio db 0x1B, '[32;1;5mATRAPALOS!!! (ESC para SALIR)', 0x1B, '[0m$'   ; Mensaje de Inicio del juego.
    mensaje_fin db 0x1B, '[31;1mJUEGO TERMINADO! Presiona ENTER', 0x1B, '[0m$'  ; Se muestra en algunas partes, para terminarl el juego.
    jugador db 0x01, '$'    ; El jugador es una Carita Feliz :).
    objeto_bueno db 0x1B, '[32m', 0x04, 0x1B, '[0m$'    ; Caracter Ansi para el objeto bueno (Un rombo).
    objeto_malo  db 0x1B, '[31m', 0x03, 0x1B, '[0m$'    ; Caracter Ansi para el objeto malo (Un corazon).
    espacio db ' $'     ; Un espacio en blanco para borrar determinados caracteres.

    posicion_x db 40    ; Poner al jugador en la mitad de la pantalla (en caracteres), la pantalla tiene 80 caracteres en total.
    posicion_y db 19    ; Ponerlo un un caracter arriba del borde azul.
    objeto_x db 0   ; Posicion inicial de los objetos que carean mas adelante...
    objeto_y db 0   ; Posicion inicial de los objetos que caeran mas adelante...
    objeto_tipo db 0    ; ¿Será malo? Se calcula despues...

    borde db 0x1B, '[46;36m'    ; Caracter del borde (Parte de abajo [Es como un cuadrado co puntitos adentro]) , se le pone verde de fonsdo y azul de color principal.
    times 80 db 0xB2    ; Se imprime el caracter como si fuera una cadena. 80 veces!.
    db 0x1B, '[0m$'


    contador_velocidad db 0
    velocidad_objetos db 18     ; A esa velocidad caen los objetos, menos es mas...
    juego_activo db 1   ; Si se vuele cero, game_over.

    puntaje db 0 ; Aqui se actualiza el puntaje, despues..
    texto_puntaje db 'Puntaje: 000$' ; Puntaje

section .text  ; Formalmente aqui empieza la ejecución del codigo.
_start: ; Es aqui donde empieza...

    call limpiar_pantalla ; Primero se limpia la pantalla.
    mov ah, 09h
    mov dx, mensaje_inicio  ; Se muestra el mensaje de inicio.
    int 21h

    ; LLamada a las subrutinias principales, estas dentro de ellas, llaman otras.
    call esperar_enter
    call dibujar_borde
    call actualizar_puntaje
    call iniciar_juego


iniciar_juego:  ; Prepara todo para iniciar.
    mov byte [posicion_x], 40   ; Coordenada en x
    mov byte [posicion_y], 19   ; Coordenada en y
    mov byte [objeto_y], 0
    mov byte [juego_activo], 1

juego_loop: ; Este es el bucle del juego
    cmp byte [juego_activo], 0 ; Si es 0, se acaba el juego, si no continua.
    je fin_juego

    call mostrar_jugador ; Se manda a imprimir al jugador.

    ; Se inicializa la velocidad de los objetos que caen.
    inc byte [contador_velocidad]
    mov al, [contador_velocidad]
    cmp al, [velocidad_objetos]
    jb no_mover_objeto

    mov byte [contador_velocidad], 0
    call generar_objeto
    call actualizar_objetos

no_mover_objeto: ; Como indica, no mueve el objeto, pero manda a llamar si hubo colisiones.
    call leer_teclado
    call verificar_colisiones
    call delay_loop
    jmp juego_loop

fin_juego:  ; Se usa para mostrar el mensaje_fin y salir del juego.
    call limpiar_pantalla
    mov ah, 09h
    mov dx, mensaje_fin
    int 21h
    call esperar_enter
    mov ah, 4Ch
    int 21h

mostrar_jugador:    ; Esta, imprime al jugador y lo posiciona a la mitad.
    mov dh, [posicion_y]
    mov dl, [posicion_x]
    call posicionar_cursor ; Con esta, posicionamos el cursor.

    mov ah, 09h
    mov dx, jugador ; Aqui se imprime.
    int 21h
    ret

generar_objeto: ; Subrutina encargada de generar los objetos que caen.
    cmp byte [objeto_y], 0
    jne no_generar

    mov ah, 00h
    int 1Ah         ; Llamada al relor del sistema.
    mov ax, dx
    xor dx, dx
    mov cx, 80      ; Ancho de la pantalla.
    div cx          ; Aunque se divide, lo que importa es el modulo.
    mov [objeto_x], dl

    and dl, 1 ; -> 50 % de provabilidad [0 y 1]
    cmp dl, 0
    jne es_bueno
    mov byte [objeto_tipo], 1 ; Si el modulo es 1, el objeto es Malo -> objeto rojo.
    jmp fin_generar
es_bueno:
    mov byte [objeto_tipo], 0 ; Si el modulo es 0, el objeto es Bueno -> objeto verde.
fin_generar:
    mov byte [objeto_y], 1
no_generar:
    ret

actualizar_objetos: ; Sirve para borrar el caracter, para que paresca que hay movimiento...
    cmp byte [objeto_y], 0
    je fin_actualizar

    mov dh, [objeto_y]
    mov dl, [objeto_x]
    call posicionar_cursor
    mov ah, 09h
    mov dx, espacio
    int 21h

    inc byte [objeto_y]

    cmp byte [objeto_y], 20 ; El objeto desaparece aqui, porque es la posicion del seuelo (la franja azul).
    jb mostrar_objeto

    mov byte [objeto_y], 0
    jmp fin_actualizar

mostrar_objeto: ; Muestra el objeto.
    mov dh, [objeto_y]
    mov dl, [objeto_x]
    call posicionar_cursor

    cmp byte [objeto_tipo], 0
    jne mostrar_malo
    mov dx, objeto_bueno
    jmp dibujar_obj

mostrar_malo:   ; si el objeto es malo se salta a aqui.
    mov dx, objeto_malo

dibujar_obj:    ; Prepara el terreno para imprimir el objeto.
    mov ah, 09h
    int 21h

fin_actualizar:
    ret

; Subrutina para leer el teclado.
leer_teclado:
    mov ah, 01h
    int 16h
    jz fin_lectura

    mov ah, 00h
    int 16h

    cmp al, 1Bh ; Checa si no se ha precionado la tecla escape, si es asi, sale del juego.
    je salir_juego

    cmp ah, 4Bh ; Checa flechita del teclado. Si es precionada, se mueve a la izquierda.
    je mover_izquierda

    cmp ah, 4Dh ; Checa flechita del teclado. Si es precionada, se mueve a la derecha.
    je mover_derecha

    jmp fin_lectura

mover_izquierda: ; Se actualiza la posicion y se mueve a la izquierda, tantas veces sea pulsada la tecla.
    mov dh, [posicion_y]
    mov dl, [posicion_x]
    call posicionar_cursor
    mov ah, 09h
    mov dx, espacio
    int 21h

    cmp byte [posicion_x], 0
    jle fin_lectura
    dec byte [posicion_x]
    jmp fin_lectura

mover_derecha: ; Se actualiza la posicion y se mueve a la izquierda, tantas veces sea pulsada la tecla.
    mov dh, [posicion_y]
    mov dl, [posicion_x]
    call posicionar_cursor
    mov ah, 09h
    mov dx, espacio
    int 21h

    cmp byte [posicion_x], 79
    jge fin_lectura
    inc byte [posicion_x]

fin_lectura: ; Retorna si no hay lectura.
    ret

salir_juego: ; Subrutina para salir del juego.
    mov byte [juego_activo], 0
    call limpiar_pantalla
    mov ah, 09h
    mov dx, mensaje_fin ; Se muestra el mensaje de fin del juego.
    int 21h
    call esperar_enter  ; Espera enter para finalizar.
    mov ah, 4Ch
    int 21h

verificar_colisiones: ; Verifica las coliciones.
    cmp byte [objeto_y], 0  ; Si es igual, no hay colisiones.
    je fin_colision

    mov al, [objeto_y]  ; Obtine la posicion del objeto y la compara.
    cmp al, [posicion_y]    ; Obtiene la posicion del objeto y la compara.
    jne fin_colision

    mov al, [objeto_x]  ; Obtine la posicion del objeto y la compara.
    cmp al, [posicion_x]    ; Obtine la posicion del objeto y la compara.
    jne fin_colision

    cmp byte [objeto_tipo], 0   ; Si es igual, entonces es un objeto bueno (rombo verde)
    je objeto_bueno_colision

objeto_malo_colision: ; Si es malo (corazon rojo)
    mov al, [puntaje] ; Se trae el puntaje actual
    cmp al, 0   ; Se compara com 0.
    je game_over   ; Si vuele a ser 0, se acaba el juego...

    ; Se divide el puntaje entre 2 (El rojo quita el 50% del puntaje)
    mov ah, 0
    shr ax, 1     ; ax = ax / 2, solo al importa porque puntaje es byte
    mov [puntaje], al

    cmp byte [puntaje], 0
    je game_over    ; Si vuele a ser 0, se acaba el juego...

    call actualizar_puntaje
    mov byte [objeto_y], 0
    jmp fin_colision

cero_puntaje:
    mov byte [puntaje], 0
actualizar_puntaje_colision:
    mov byte [objeto_y], 0
    call actualizar_puntaje
    jmp fin_colision

objeto_bueno_colision: ; Se en carga de hacer sonar y de actualizar el puntaje, si se atrapa un objeto bueno.
    mov ax, 800
    mov cx, 2
    call tocar_tono ;; Solo hace un "puck" -> no da para mas el sonido :c

    mov byte [objeto_y], 0
    inc byte [puntaje]
    call actualizar_puntaje ; Actualiza el puntaje
fin_colision:
    ret

game_over: ; game over...
    mov byte [juego_activo], 0 ; Como el juego es cero, game_over
    call limpiar_pantalla   ; Se limpia la pantalla.
    mov ah, 09h
    mov dx, mensaje_fin ; Se imprime el mensaje de final del juego.
    int 21h
    call esperar_enter  ; Espera enter.
    mov ah, 4Ch
    int 21h

dibujar_borde: ; Esta subrutina, imprime el borde en su posicion.
    mov dh, 20  ; Y
    mov dl, 0   ; X
    call posicionar_cursor  ; Se pone el cursor en las coordenadas anteriores.

    mov ah, 09h
    mov dx, borde
    int 21h
    ret

delay_loop:
    mov cx, 0x4FFF
pausa:
    loop pausa
    ret

limpiar_pantalla:   ; Simple subrutina para limpiar la pantalla.
    mov ax, 0003h
    int 10h
    ret

esperar_enter:  ; Esta esperra la tecla ENTER
    mov ah, 00h
    int 16h
    cmp al, 0Dh
    jne esperar_enter
    ret

posicionar_cursor:  ; Esta es la subrutina que interactua con la BIOS para posicionar el cursor.
    mov ah, 02h
    mov bh, 0
    int 10h
    ret

actualizar_puntaje: ; Se encarga de actualizar el puntaje.
    ; AL = decenas
    ; AH = unidades
    mov dh, 0
    mov dl, 0
    call posicionar_cursor

    mov al, [puntaje]
    xor ah, ah
    mov bl, 10
    div bl

    add al, '0'
    mov [texto_puntaje+9], al
    add ah, '0'
    mov [texto_puntaje+10], ah

    mov ah, 09h
    mov dx, texto_puntaje
    int 21h
    ret


    ;;;;; Todo esto hace sonar el "puck".

    tocar_tono:
    push ax
    push bx
    push dx

    ; Calcular divisor: divisor = 1193180 / frecuencia (AX)
    mov dx, 0x0012
    mov ax, 0x3B6C      ; 1193180 decimal = 0x123B6C (DX:AX)
    xchg ax, bx
    xchg dx, cx         ; Ahora DX:AX=1193180 y BX=frecuencia

    div bx              ; DX:AX / BX, resultado en AX

    mov al, 0B6h
    out 43h, al

    mov bx, ax
    mov al, bl
    out 42h, al
    mov al, bh
    out 42h, al

    in al, 61h
    or al, 3
    out 61h, al

    mov cx, 5000

delay_bucle: ; Necesario, si no se queda sonando en bucle el "puck"
    loop delay_bucle

    in al, 61h
    and al, 0FCh
    out 61h, al

    pop dx
    pop bx
    pop ax
    ret


