#!/bin/bash
# -*- ENCODING: UTF-8 -*-

source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"
source "$DS/default/sets.cfg"

# -----------------------------------------------------------------------------
# Rutas
# -----------------------------------------------------------------------------
AI_ADDON_DIR="$DS/addons/AI Topic Builder"
AI_CFG="$DC_a/ai_topic_builder.cfg"

# -----------------------------------------------------------------------------
# Leer configuración del proveedor desde ai_topic_builder.cfg
# Exporta: AI_PROVIDER, AI_API_KEY, AI_ENDPOINT, AI_MODEL
# -----------------------------------------------------------------------------
read_ai_config() {
    if [ ! -f "$AI_CFG" ]; then
        return 1
    fi

    AI_PROVIDER="$(grep -o 'provider="[^"]*' "$AI_CFG" | grep -o '[^"]*$')"
    AI_API_KEY="$(grep -o 'api_key="[^"]*' "$AI_CFG" | grep -o '[^"]*$')"
    AI_ENDPOINT="$(grep -o 'endpoint="[^"]*' "$AI_CFG" | grep -o '[^"]*$')"
    AI_MODEL="$(grep -o 'model="[^"]*' "$AI_CFG" | grep -o '[^"]*$')"

    # Fallbacks por si el .cfg está incompleto
    [ -z "$AI_PROVIDER" ] && AI_PROVIDER="OpenAI"
    case "$AI_PROVIDER" in
        OpenAI)
            [ -z "$AI_ENDPOINT" ] && AI_ENDPOINT="https://api.openai.com/v1/chat/completions"
            [ -z "$AI_MODEL" ] && AI_MODEL="gpt-4o-mini"
            ;;
        Groq)
            [ -z "$AI_ENDPOINT" ] && AI_ENDPOINT="https://api.groq.com/openai/v1/chat/completions"
            [ -z "$AI_MODEL" ] && AI_MODEL="llama-3.3-70b-versatile"
            ;;
        DeepSeek)
            [ -z "$AI_ENDPOINT" ] && AI_ENDPOINT="https://api.deepseek.com/v1/chat/completions"
            [ -z "$AI_MODEL" ] && AI_MODEL="deepseek-chat"
            ;;
        Ollama)
            [ -z "$AI_ENDPOINT" ] && AI_ENDPOINT="http://localhost:11434/v1/chat/completions"
            [ -z "$AI_MODEL" ] && AI_MODEL="llama3.1:8b"
            ;;
        Custom)
            # Deben estar rellenos por el usuario
            ;;
    esac

    # Validaciones mínimas
    if [ -z "$AI_ENDPOINT" ] || [ -z "$AI_MODEL" ]; then
        return 1
    fi

    # Ollama no requiere API key. Los demás sí.
    if [ "$AI_PROVIDER" != "Ollama" ] && [ -z "$AI_API_KEY" ]; then
        return 1
    fi

    export AI_PROVIDER AI_API_KEY AI_ENDPOINT AI_MODEL
    return 0
}

# -----------------------------------------------------------------------------
# Construir el prompt
# -----------------------------------------------------------------------------
build_prompt() {
    local topic="$1" category="$2" type="$3" instructions="$4"
    local base type_file type_txt

    base="$(< "$AI_ADDON_DIR/prompts/base.txt")"
    case "$type" in
        1) type_file="$AI_ADDON_DIR/prompts/type1.txt" ;;
        2) type_file="$AI_ADDON_DIR/prompts/type2.txt" ;;
        3) type_file="$AI_ADDON_DIR/prompts/type3.txt" ;;
        *) return 1 ;;
    esac
    type_txt="$(< "$type_file")"

    base="${base//\{\{TLNG\}\}/$tlng}"
    base="${base//\{\{SLNG\}\}/$slng}"

    printf '%s\n\n%s\n\nUSER REQUEST:\n- Topic: %s\n- Category: %s\n- Type: %s\n- Instructions: %s\n' \
        "$base" "$type_txt" "$topic" "$category" "$type" "$instructions"
}

# -----------------------------------------------------------------------------
# Llamar al proveedor de IA
# -----------------------------------------------------------------------------
call_ai() {
    local prompt="$1"
    local payload response http_code body content

    # Algunos proveedores no soportan response_format: json_object
    local use_json_format="true"
    case "$AI_PROVIDER" in
        Ollama) use_json_format="false" ;;
    esac

    payload="$(python3 -c '
import json, sys
prompt = sys.stdin.read()
payload = {
    "model": sys.argv[1],
    "messages": [
        {"role": "system", "content": "You are a language learning content generator. Respond only with valid JSON."},
        {"role": "user", "content": prompt}
    ],
    "temperature": 0.7
}
if sys.argv[2] == "true":
    payload["response_format"] = {"type": "json_object"}
print(json.dumps(payload))
' "$AI_MODEL" "$use_json_format" <<< "$prompt")"

    # Authorization solo si hay API key (Ollama no la necesita)
    local auth_args=()
    if [ -n "$AI_API_KEY" ]; then
        auth_args=(-H "Authorization: Bearer $AI_API_KEY")
    fi

    response="$(curl -s -w '\n%{http_code}' \
        -X POST "$AI_ENDPOINT" \
        "${auth_args[@]}" \
        -H "Content-Type: application/json" \
        -d "$payload")"

    http_code="$(tail -n 1 <<< "$response")"
    body="$(sed '$d' <<< "$response")"

    if [ "$http_code" != "200" ]; then
        msg "$(gettext "AI request failed.")\n\n\
$(gettext "Provider"): ${AI_PROVIDER}\n\
$(gettext "Model"): ${AI_MODEL}\n\
HTTP ${http_code}\n\n${body:0:600}" \
            dialog-error "$(gettext "AI Topic Builder")"
        return 1
    fi

    content="$(python3 -c '
import json, sys
data = json.load(sys.stdin)
print(data["choices"][0]["message"]["content"])
' <<< "$body")"

    if [ -z "$content" ]; then
        msg "$(gettext "Empty response from AI.")\n" \
            dialog-error "$(gettext "AI Topic Builder")"
        return 1
    fi

    printf '%s' "$content"
}

# -----------------------------------------------------------------------------
# Validar JSON y extraer campos
# -----------------------------------------------------------------------------
validate_and_extract() {
    local json="$1"
    local output

    if ! python3 -m json.tool <<< "$json" >/dev/null 2>&1; then
        msg "$(gettext "AI returned invalid JSON.")\n\n${json:0:500}" \
            dialog-error "$(gettext "AI Topic Builder")"
        return 1
    fi

    output="$(python3 -c '
import json, sys
data = json.load(sys.stdin)
for s in data.get("sentences", []):
    en = s.get("en", "").replace("\t", " ").replace("\n", " ")
    es = s.get("es", "").replace("\t", " ").replace("\n", " ")
    if en and es:
        print("SENT\t" + en + "\t" + es)
for w in data.get("words", []):
    t = w.get("text", "").replace("\t", " ").replace("\n", " ")
    tr = w.get("translation", "").replace("\t", " ").replace("\n", " ")
    ex = w.get("example", "").replace("\t", " ").replace("\n", " ")
    if t and tr:
        print("WORD\t" + t + "\t" + tr + "\t" + ex)
' <<< "$json")"

    if [ -z "$output" ]; then
        msg "$(gettext "AI returned no usable items.")\n" \
            dialog-error "$(gettext "AI Topic Builder")"
        return 1
    fi

    printf '%s' "$output"
}

# -----------------------------------------------------------------------------
# Validar restricciones de los items
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Validar restricciones de los items
# -----------------------------------------------------------------------------
validate_items() {
    local items="$1"
    local type="$2"
    local line kind a b c

    # Recopilar sentences y words
    local sentences=""
    local words_list=""
    while IFS=$'\t' read -r kind a b c; do
        [ -z "$kind" ] && continue
        if [ "$kind" = "SENT" ]; then
            sentences="${sentences}${a}"$'\n'
            # Validaciones de sentence
            if [ ${#a} -gt $sentence_chars ]; then
                msg "$(gettext "A sentence exceeds the maximum length.")\n\n${a:0:80}..." \
                    dialog-warning "$(gettext "AI Topic Builder")"
                return 1
            fi
            if [ "$(echo -e "$a" | wc -l)" -gt $sentence_lines ]; then
                msg "$(gettext "A sentence exceeds the maximum number of lines.")\n\n${a:0:80}..." \
                    dialog-warning "$(gettext "AI Topic Builder")"
                return 1
            fi
            if [ "$Level" = "0" ] && [ "$(wc -w <<< "$a")" -gt $sentence_words_level0 ]; then
                msg "$(gettext "A sentence exceeds the maximum number of words for your level.")\n\n${a:0:80}..." \
                    dialog-warning "$(gettext "AI Topic Builder")"
                return 1
            fi
        elif [ "$kind" = "WORD" ]; then
            words_list="${words_list}${a}"$'\n'
            if [ ${#a} -gt 60 ]; then
                msg "$(gettext "A word is too long.")\n\n${a:0:80}..." \
                    dialog-warning "$(gettext "AI Topic Builder")"
                return 1
            fi
        fi
    done <<< "$items"

    # Validación específica de Type 3: cada word debe aparecer en alguna sentence
	if [ "$type" = "3" ]; then
		local w escaped
		while IFS= read -r w; do
			[ -z "$w" ] && continue
			escaped="$(sed 's/[][\.*^$(){}?+|/]/\\&/g' <<< "$w")"
			if ! grep -qiE "(^|[^[:alnum:]])${escaped}([^[:alnum:]]|$)" <<< "$sentences"; then
				msg "$(gettext "Type 3 validation failed.")\n\n\
	$(gettext "The word does not appear in any generated sentence:")\n\n<b>${w}</b>\n\n\
	$(gettext "Try regenerating the topic.")" \
					dialog-warning "$(gettext "AI Topic Builder")"
				return 1
			fi
		done <<< "$words_list"
	fi

    return 0
}

# -----------------------------------------------------------------------------
# Generar note.md en texto plano
# -----------------------------------------------------------------------------
write_note_md() {
    local topic="$1" instructions="$2" items="$3"
    local note_file="$DC_tlt/note.md"
    local kind a b c
    local n_sent=0 n_word=0

    {
        # Título
        printf '%s\n\n' "$topic"

        # Instrucciones
        if [ -n "$instructions" ]; then
            printf '%s\n\n' "$instructions"
        fi

        # Contar items
        while IFS=$'\t' read -r kind a b c; do
            [ -z "$kind" ] && continue
            if [ "$kind" = "SENT" ]; then
                ((n_sent++))
            elif [ "$kind" = "WORD" ]; then
                ((n_word++))
            fi
        done <<< "$items"

        # Sentences (solo idioma target, sin traducción)
        if [ "$n_sent" -gt 0 ]; then
            while IFS=$'\t' read -r kind a b c; do
                [ "$kind" = "SENT" ] || continue
                printf '%s\n' "$a"
            done <<< "$items"
            printf '\n'
        fi

        # Words (solo texto y traducción, sin ejemplo)
        if [ "$n_word" -gt 0 ]; then
            while IFS=$'\t' read -r kind a b c; do
                [ "$kind" = "WORD" ] || continue
                printf '%s\n' "$a"
            done <<< "$items"
        fi

    } > "$note_file"
}


# -----------------------------------------------------------------------------
# Flujo principal
# -----------------------------------------------------------------------------
start_flow() {

    internet

    # Leer configuración del proveedor
    if ! read_ai_config; then
        msg "$(gettext "AI provider not configured.")\n\n\
$(gettext "Please open the AI Topic Builder preferences and configure the provider.")\n" \
            dialog-warning "$(gettext "AI Topic Builder")"
        return 1
    fi

    # Construir lista de categorías
    local cat_list=""
    for c in "${Categories[@]}"; do
        cat_list="${cat_list}!${c}"
    done

    # Formulario
    local form
    form="$(yad --form \
        --title="$(gettext "AI Topic Builder")" \
        --name=Idiomind --class=Idiomind \
        --window-icon=idiomind --center --on-top \
        --width=520 --height=320 --borders=12 \
        --separator='|' \
        --field="$(gettext "Topic")" "" \
        --field="$(gettext "Category"):CB" "$cat_list" \
        --field="$(gettext "Type"):CB" "!1 - $(gettext "Words only")!2 - $(gettext "Sentences only")!3 - $(gettext "Hybrid (sentences + words)")" \
        --field="$(gettext "Instructions"):TXT" \
        --button="$(gettext "Generate")!gtk-apply":0 \
        --button="$(gettext "Cancel")":1)"
    local ret=$?

    [ $ret -ne 0 ] && return 1

    local topic category type_raw type instructions
    topic="$(cut -d '|' -f1 <<< "$form")"
    topic="$(sed 's/^\s*./\U&\E/' <<< "$topic")"
    category="$(cut -d '|' -f2 <<< "$form")"
    type_raw="$(cut -d '|' -f3 <<< "$form")"
    instructions="$(cut -d '|' -f4 <<< "$form")"

    # Extraer solo el primer dígito del campo Type
    type="${type_raw:0:1}"

    if [ -z "$topic" ]; then
        msg "$(gettext "Topic name is required.")\n" \
            dialog-warning "$(gettext "AI Topic Builder")"
        return 1
    fi
    if [ -z "$category" ]; then
        msg "$(gettext "Category is required.")\n" \
            dialog-warning "$(gettext "AI Topic Builder")"
        return 1
    fi
    if [ -z "$type" ]; then
        msg "$(gettext "Type is required.")\n" \
            dialog-warning "$(gettext "AI Topic Builder")"
        return 1
    fi

    # Construir prompt
    local prompt
    prompt="$(build_prompt "$topic" "$category" "$type" "$instructions")"

    # Barra de progreso
    local lock="$DT/ai_tb_progress_$$"
    touch "$lock"

    (
        echo "#"
        echo "# $(gettext "Contacting AI provider...")"
        while [ -f "$lock" ]; do
            sleep 1
            echo "#"
        done
    ) | yad --progress --pulsate --auto-close \
        --title="$(gettext "AI Topic Builder")" \
        --name=Idiomind --class=Idiomind \
        --window-icon=idiomind --center --on-top \
        --width=380 --height=100 --borders=12 \
        --no-buttons --skip-taskbar &
    local progress_pid=$!

    local json
    json="$(call_ai "$prompt")"
    local ai_ret=$?

    # Cerrar la barra
    rm -f "$lock"
    wait "$progress_pid" 2>/dev/null


    if [ $ai_ret -ne 0 ] || [ -z "$json" ]; then
        return 1
    fi

    # Validar y extraer
    local items
    items="$(validate_and_extract "$json")"
    if [ $? -ne 0 ] || [ -z "$items" ]; then
        return 1
    fi

    # Validar restricciones
    validate_items "$items" "$type"
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Crear topic
    "$DS/add.sh" new-topic 1 1 "$topic"

    if [ ! -d "$DM_tl/${topic}/.conf" ]; then
        msg "$(gettext "Failed to create topic.")\n" \
            dialog-error "$(gettext "AI Topic Builder")"
        return 1
    fi

    DC_tlt="$DM_tl/${topic}/.conf"
    tpc_db 9 id ctgy "$category"
    # Asignar autor = proveedor + modelo (saneado)
    local autor_safe="${AI_PROVIDER} - ${AI_MODEL//\//.}"
    # Truncar a 30 caracteres por el límite del exportador
    autor_safe="${autor_safe:0:30}"
    tpc_db 9 id autr "$autor_safe"
    
        # Persistir las instrucciones del usuario en note.md
    # Persistir las instrucciones del usuario en note.md
    if [ -n "$instructions" ]; then
        {
            printf '# %s\n\n' "$topic"
            printf '%s\n' "$instructions"
        } > "$DC_tlt/note.md"
    fi

    # Preparar entorno
    export tpe="$topic"
    export DT_r="$DT/$(base64 <<< $((RANDOM%100000)) | head -c 32)"
    check_dir "$DT_r"
    cd "$HOME" && cd "$DT_r"
    
    write_note_md "$topic" "$instructions" "$items"

    # Crear items
    local kind a b c n_sent=0 n_word=0
    while IFS=$'\t' read -r kind a b c; do
        [ -z "$kind" ] && continue

        if [ "$kind" = "SENT" ]; then
            export trgt="$a"
            export srce="$b"
            "$DS/add.sh" new_item "$tpe" '__cmd__' "$trgt" 2
            ((n_sent++))
        elif [ "$kind" = "WORD" ]; then
            export trgt="$a"
            export srce="$b"
            export exmp="$c"
            "$DS/add.sh" new_item "$tpe" '__cmd__' "$trgt" 1
            ((n_word++))
        fi
    done <<< "$items"
    
    cleanups "$DT_r"

    # Refrescar
    "$DS/ifs/tls.sh" check_index "$topic" >/dev/null 2>&1
    "$DS/ifs/tls.sh" colorize 1 >/dev/null 2>&1

    # Confirmación
    notify-send -i idiomind "$topic" \
        "$(gettext "Topic created"): ${n_sent} $(gettext "sentences"), ${n_word} $(gettext "words")" \
        -t 3000

    return 0
}

case "$1" in
    start)
    start_flow ;;
esac
