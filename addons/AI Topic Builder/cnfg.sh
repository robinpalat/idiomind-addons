#!/bin/bash
# -*- ENCODING: UTF-8 -*-

DC_a="$HOME/.config/idiomind/addons"
fileconf="$DC_a/ai_topic_builder.cfg"
name="AI Topic Builder"

[ ! -f "$fileconf" ] && touch "$fileconf"

# --- Leer configuración actual ---
current_provider="$(grep -o 'provider="[^"]*' "$fileconf" | grep -o '[^"]*$')"
current_api_key="$(grep -o 'api_key="[^"]*' "$fileconf" | grep -o '[^"]*$')"
current_endpoint="$(grep -o 'endpoint="[^"]*' "$fileconf" | grep -o '[^"]*$')"
current_model="$(grep -o 'model="[^"]*' "$fileconf" | grep -o '[^"]*$')"

# --- Valores por defecto ---
[ -z "$current_provider" ] && current_provider="OpenAI"

# --- Definición de proveedores ---
# Cada proveedor tiene: endpoint y modelo por defecto.
# El usuario puede sobrescribirlos manualmente.
provider_list="!OpenAI!Groq!DeepSeek!Ollama!Custom"

# Preseleccionar el proveedor actual en la lista
provider_cb="${current_provider}"
for p in OpenAI Groq DeepSeek Ollama Custom; do
    if [ "$p" != "$current_provider" ]; then
        provider_cb="${provider_cb}!${p}"
    fi
done

# --- Etiqueta ---
label="<b>$(gettext "AI Topic Builder")</b>\n\n\
$(gettext "Configure the AI provider used to generate topics.")\n\n\
$(gettext "Select a provider, enter your API key, and optionally override the endpoint and model.")\n"

# --- Formulario ---
c=$(yad --form --title="$(gettext "$name")" \
    --name=Idiomind --class=Idiomind \
    --text="$label" \
    --window-icon=$DS/images/logo.png \
    --align=right --center \
    --on-top --skip-taskbar --scroll \
    --width=520 --height=380 --borders=12 \
    --always-print-result --editable --print-all \
    --field="$(gettext "Provider"):CB" "$provider_cb" \
    --field="$(gettext "API key")":H "$current_api_key" \
    --field="$(gettext "Endpoint (optional)")" "$current_endpoint" \
    --field="$(gettext "Model (optional)")" "$current_model" \
    --button="$(gettext "Save")!gtk-apply":0 \
    --button="$(gettext "Close")":1)
ret=$?

if [ $ret = 0 ]; then
    provider="$(cut -d '|' -f1 <<< "$c")"
    api_key="$(cut -d '|' -f2 <<< "$c")"
    endpoint="$(cut -d '|' -f3 <<< "$c")"
    model="$(cut -d '|' -f4 <<< "$c")"

    # Si el endpoint o el modelo están vacíos, aplicar defaults del proveedor
    case "$provider" in
        OpenAI)
            [ -z "$endpoint" ] && endpoint="https://api.openai.com/v1/chat/completions"
            [ -z "$model" ] && model="gpt-4o-mini"
            ;;
        Groq)
            [ -z "$endpoint" ] && endpoint="https://api.groq.com/openai/v1/chat/completions"
            [ -z "$model" ] && model="llama-3.3-70b-versatile"
            ;;
        DeepSeek)
            [ -z "$endpoint" ] && endpoint="https://api.deepseek.com/v1/chat/completions"
            [ -z "$model" ] && model="deepseek-chat"
            ;;
        Ollama)
            [ -z "$endpoint" ] && endpoint="http://localhost:11434/v1/chat/completions"
            [ -z "$model" ] && model="llama3.1:8b"
            ;;
        Custom)
            # No aplicar defaults: el usuario debe rellenar ambos
            ;;
    esac

    {
        echo "provider=\"${provider}\""
        echo "api_key=\"${api_key}\""
        echo "endpoint=\"${endpoint}\""
        echo "model=\"${model}\""
    } > "$fileconf"
fi

exit 0
