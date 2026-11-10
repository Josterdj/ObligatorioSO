#!/bin/bash
ARCHIVO_USUARIOS="usuarios.csv"
ARCHIVO_FLOTA="flota.csv"

if [ ! -f "$ARCHIVO_USUARIOS" ]; then
    echo "admin,admin" > "$ARCHIVO_USUARIOS"
fi
if [ ! -f "$ARCHIVO_FLOTA" ]; then
    echo "ID,Categoria,Modelo,Bateria,Disponible" > "$ARCHIVO_FLOTA"
fi

registrar_usuario() {
    local usuario=""
    local clave=""
    local usuario_guardado=""
    local clave_guardada=""

    read -r -p "Ingresá un usuario: " usuario
    read -r -s -p "Ingresá una contraseña: " clave
    echo ""

    if [[ -z "${usuario//[[:space:]]/}" ||
          -z "${clave//[[:space:]]/}" ]]; then
        echo "Error: el usuario y la contraseña no pueden estar en blanco."
        return
    fi

    if [[ "$usuario" == *","* || "$clave" == *","* ]]; then
        echo "Error: el usuario y la contraseña no pueden contener comas."
        return
    fi

    while IFS=, read -r usuario_guardado clave_guardada; do
        if [[ "$usuario" == "$usuario_guardado" ]]; then
            echo "Error: ese usuario ya existe."
            return
        fi
    done < "$ARCHIVO_USUARIOS"

    echo "$usuario,$clave" >> "$ARCHIVO_USUARIOS"
    echo "Usuario registrado correctamente."
}
ingresar_dron() {
    local opcion_categoria=""
    local categoria=""
    local prefijo=""
    local modelo=""
    local bateria=""
    local disponible=""

    local id_guardado=""
    local resto=""
    local numero=""
    local mayor=0
    local nuevo_id=""

    echo ""
    echo "=== INGRESAR DRON ==="
    echo "1. Scout"
    echo "2. Cargo"
    echo "3. Heavy"
    echo "4. Cooler"
    echo "5. Racer"

    read -r -p "Elegí una categoría: " opcion_categoria

    case "$opcion_categoria" in
        1)
            categoria="Scout"
            prefijo="SCO"
            ;;
        2)
            categoria="Cargo"
            prefijo="CAR"
            ;;
        3)
            categoria="Heavy"
            prefijo="HEA"
            ;;
        4)
            categoria="Cooler"
            prefijo="COO"
            ;;
        5)
            categoria="Racer"
            prefijo="RAC"
            ;;
        *)
            echo "Error: categoría inválida."
            return
            ;;
    esac

    read -r -p "Modelo: " modelo

    if [[ -z "${modelo//[[:space:]]/}" || "$modelo" == *","* ]]; then
        echo "Error: el modelo no puede estar en blanco ni contener comas."
        return
    fi

    read -r -p "Batería (0 a 100, sin el símbolo %): " bateria

    if [[ ! "$bateria" =~ ^[0-9]{1,3}$ ]]; then
        echo "Error: ingresá un número entero entre 0 y 100."
        return
    fi

    bateria=$((10#$bateria))

    if (( bateria > 100 )); then
        echo "Error: la batería no puede superar 100."
        return
    fi

    read -r -p "¿Está disponible? (Si/No): " disponible

    case "$disponible" in
        Si|si|SI|Sí|sí|SÍ)
            disponible="Si"
            ;;
        No|no|NO)
            disponible="No"
            ;;
        *)
            echo "Error: ingresá Si o No."
            return
            ;;
    esac

    while IFS=, read -r id_guardado resto; do
        if [[ "$id_guardado" == "$prefijo-"* ]]; then
            numero="${id_guardado#*-}"
            numero=$((10#$numero))

            if (( numero > mayor )); then
                mayor=$numero
            fi
        fi
    done < "$ARCHIVO_FLOTA"

    printf -v nuevo_id "%s-%03d" "$prefijo" "$((mayor + 1))"

    printf '%s,%s,%s,%s,%s\n' \
        "$nuevo_id" "$categoria" "$modelo" "$bateria" "$disponible" \
        >> "$ARCHIVO_FLOTA"

    echo "Dron ingresado: $nuevo_id - $categoria - $modelo - $bateria% - Disponible: $disponible"
}

menu_principal() {
    local usuario_actual="$1"
    local opcion=""

    while true; do
        echo ""
        echo "=== MENÚ PRINCIPAL ==="
        echo "Usuario: $usuario_actual"
        echo "1. Ingresar dron"
        echo "2. Asignar dron a reparto"
        echo "3. Actualizar dron"
        echo "4. Reporte de flota"
        echo "5. Cerrar sesión"
        echo "6. Salir del sistema"

        read -r -p "Elegí una opción: " opcion

        case "$opcion" in
            1)
                echo "Acá vamos a ingresar un dron."
                ;;
            2)
                echo "Acá vamos a asignar un dron."
                ;;
            3)
                echo "Acá vamos a actualizar un dron."
                ;;
            4)
                echo "Acá vamos a mostrar el reporte."
                ;;
            5)
                echo "Sesión cerrada."
                return
                ;;
            6)
                echo "Hasta luego."
                exit 0
                ;;
            *)
                echo "Opción inválida."
                ;;
        esac
    done
}

iniciar_sesion() {
    local usuario=""
    local clave=""
    local usuario_guardado=""
    local clave_guardada=""

    read -r -p "Usuario: " usuario
    read -r -s -p "Contraseña: " clave
    echo ""

    while IFS=, read -r -u 3 usuario_guardado clave_guardada; do
        if [[ "$usuario" == "$usuario_guardado" &&
              "$clave" == "$clave_guardada" ]]; then
            echo "Bienvenido, $usuario."

            menu_principal "$usuario"
            return
        fi
    done 3< "$ARCHIVO_USUARIOS"

    echo "Error: usuario o contraseña incorrectos."
}

menu_sesion() {
    local opcion=""

    while true; do
        echo ""
        echo "=== DON DRONES ==="
        echo "1. Registrarse"
        echo "2. Iniciar sesión"
        echo "3. Salir"

        read -r -p "Elegí una opción: " opcion

        case "$opcion" in
            1)
                registrar_usuario
                ;;
            2)
                iniciar_sesion
                ;;
            3)
                echo "Hasta luego."
                exit 0
                ;;
            *)
                echo "Opción inválida. Elegí 1, 2 o 3."
                ;;
        esac
    done
}

menu_sesion