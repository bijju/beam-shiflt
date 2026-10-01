#!/bin/bash
# usage: tools/ui_shots/shoot.sh <WxH> <outdir> [only=a,b]
# Renders from a COPY of the project with an isolated user:// so the driver can never touch the real save.
cd "$(dirname "$0")/../.."
SRC="$(pwd -W)"; DST="$(cygpath -w "${TEMP:-/tmp}")\bs_shots"
MSYS2_ARG_CONV_EXCL="*" robocopy "$SRC" "$DST" /MIR /XD android builds .git .claude /NFL /NDL /NJH /NJS /NP > /dev/null
sed -i 's|^config/name="BeamShift"$|config/name="BeamShift"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="BeamShiftShotsTmp"|' "$(cygpath -u "$DST")/project.godot"
rm -rf "$APPDATA/BeamShiftShotsTmp"
/d/Godot_v4.7.1-stable_win64.exe --path "$DST" --resolution "$1" res://tools/ui_shots/ui_shots.tscn -- out="$2" $3 2>&1 | grep -i "error" | grep -v "BUG: Unref\|leaked\|PagedAlloc" | head -8
