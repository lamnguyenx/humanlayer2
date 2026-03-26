PRJ="$(cd "$(dirname "$(readlink -f "${SWD}/PROJECT_ROOT.md")")" &>/dev/null && pwd)"

(PROJECT_ROOT.md is a dummy file created in the project root folder and then relatively symlinked to the parent folder of the current script)