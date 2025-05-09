#!/usr/bin/env bash
# jASH v0.1a : Javascript in BASH PoC : https://github.com/elemantalcode/jash

# Toggle verbose tracing here:
DEBUG=false          # set to true for noise; and debugging of course

declare -A js_vars 

# helpers
dbg() { $DEBUG && printf 'DEBUG: %s\n' "$*" >&2; }
escape_for_sed_replacement() { sed -e 's/[&/\\]/\\&/g' <<< "$1"; }

# Evaluation function
evaluate_expression() {
    local expr="$1"; dbg "evaluate_expression INPUT: '$expr'"

    # strip trailing ; and outer whitespace
    expr="${expr%%;}"
    expr="${expr#"${expr%%[![:space:]]*}"}"
    expr="${expr%"${expr##*[![:space:]]}"}"
    [[ -z $expr ]] && { dbg "…empty, returns ''"; echo ""; return 0; }

    # ---------- 1. substitute variables (skip *_body blobs) ----------
    local out="$expr"
    for k in "${!js_vars[@]}"; do
        [[ $k == *_body ]] && continue
        local repl; repl=$(escape_for_sed_replacement "${js_vars[$k]}")
        out=$(printf '%s' "$out" | sed -E "s/\b$k\b/$repl/g")
    done
    dbg "after var‑substitution: '$out'"; expr="$out"

    # ---------- 2. strings and concatenation ----------
    if [[ $expr == *\"* || $expr == *\'* ]]; then
        dbg "string context"
        if [[ $expr == *+* ]]; then
            local assembled="" tmp="$expr"
            while [[ $tmp == *+* ]]; do
                local part="${tmp%%+*}" tmp="${tmp#*+}"
                part="${part#"${part%%[![:space:]]*}"}"
                part="${part%"${part##*[![:space:]]}"}"
                part="${part//[\"\' ]/}"
                assembled+="$part"
            done
            tmp="${tmp//[\"\' ]/}"
            echo "$assembled$tmp"; return 0
        fi
        echo "${expr//[\"\' ]/}"; return 0
    fi

    # ---------- 3. arithmetic / comparison ----------
    local arith="${expr//[[:space:]]/}"
    local re_non_numeric='[^0-9+\-*/%<>=()&|]'
    if [[ $arith =~ $re_non_numeric ]] && [[ ! $arith =~ ^[0-9]+$ ]]; then
        dbg "non‑numeric, return raw"; echo "$expr"; return 0
    fi
    [[ -z $arith ]] && { echo 0; return 0; }

    local result
    if result=$(($arith)) 2>/dev/null; then
        dbg "numeric result: $result"; echo "$result"
    else
        dbg "arithmetic error, return 0"; echo 0
    fi
}

# Parser function
parse_block() {         # helper: read until matching } into a variable
    local brace=1 line body=""
    while IFS= read -r line; do
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
        [[ $trimmed == *"{"* ]] && ((brace++))
        if [[ $trimmed == *"}"* ]]; then
            ((brace--)); ((brace==0)) && break
        fi
        body+="$line"$'\n'
    done
    printf '%s' "${body%$'\n'}"
}

parse_line() {
    local line="$1"
    line="${line#"${line%%[![:space:]]*}"}"; line="${line%"${line##*[![:space:]]}"}"
    [[ -z $line || $line == \} || $line =~ ^// ]] && return 0

    # var / let
    if [[ $line =~ ^(var|let)[[:space:]]+([_a-zA-Z][_a-zA-Z0-9]*)[[:space:]]*=[[:space:]]*(.*) ]]; then
        local v="${BASH_REMATCH[2]}" rhs="${BASH_REMATCH[3]%%;}"
        js_vars["$v"]="$(evaluate_expression "$rhs")"; dbg "set $v='${js_vars[$v]}'"; return 0
    fi
    # console.log - apparently, it is common
    if [[ $line =~ ^console\.log[[:space:]]*\((.*)\) ]]; then
        echo "$(evaluate_expression "${BASH_REMATCH[1]%%;}")"; return 0
    fi
    # if–else
    if [[ $line =~ ^if[[:space:]]*\((.*)\)[[:space:]]*\{$ ]]; then
        local cond="$(evaluate_expression "${BASH_REMATCH[1]}")"
        local if_body else_body exec_if=0
        [[ $cond == 1 ]] && exec_if=1
        if_body="$(parse_block)"         # read until matching }
        IFS= read -r maybe_else || true
        if [[ $maybe_else =~ ^[[:space:]]*else[[:space:]]*\{$ ]]; then
            else_body="$(parse_block)"
        fi
        if ((exec_if)); then
            IFS=$'\n'; for l in $if_body; do parse_line "$l"; done; IFS=$' \t\n'
        else
            IFS=$'\n'; for l in $else_body; do parse_line "$l"; done; IFS=$' \t\n'
        fi
        return 0
    fi
    # function declaration
    if [[ $line =~ ^function[[:space:]]+([_a-zA-Z][_a-zA-Z0-9]*)[[:space:]]*\(\)[[:space:]]*\{$ ]]; then
        local fn="${BASH_REMATCH[1]}"
        js_vars["$fn"]="func"; js_vars["${fn}_body"]="$(parse_block)"; dbg "func $fn stored"; return 0
    fi
    # function call
    if [[ $line =~ ^([_a-zA-Z][_a-zA-Z0-9]*)[[:space:]]*\(\) ]]; then
        local fn="${BASH_REMATCH[1]%%;}"
        [[ ${js_vars[$fn]} == func ]] || { echo "Error: $fn not a function" >&2; return 0; }
        IFS=$'\n'; for l in ${js_vars["${fn}_body"]}; do parse_line "$l"; done; IFS=$' \t\n'; return 0
    fi
    dbg "Unknown statement: $line"
}

main() {
    local file="${1:-/dev/stdin}"
    [[ -f $file || $file == /dev/stdin ]] || { echo "File $file not found" >&2; exit 1; }
    while IFS= read -r l || [[ -n $l ]]; do parse_line "$l"; done <"$file"
}

main "$@"

