# How to format a shell script

1. Only chain commands with `&& \` when they work towards the same goal. Place `&& \` at the **end** of lines, not the beginning
2. Use blank `\` lines to separate major logical sections within a command chain
3. Indent subsequent commands +1 after context changes (like `cd`)
4. Align pipes `|` and redirections vertically with +1 indentation
5. Identify the "leading" vs "tail" parts of commands. The leading part (command + essential flags) stays on one line and is unbreakable. The tail part (arguments, packages, files) can be broken into multiple lines with +1 indentation
6. **For commands with many arguments, group related arguments strategically on the same line** based on their logical purpose (e.g., codec + bitrate + samplerate). Balance between vertical space (readability) and horizontal grouping (context)
7. Align similar elements vertically (redirections, operators, values). This creates columns that make patterns obvious and easier to scan
8. Maintain consistent indentation hierarchy throughout entire chain. **All lines after `\` must be indented** as they're part of the same command scope
9. For inline scripts (e.g., in `bash -c` or `python3 -c`), keep the script content at indent 0 to avoid whitespace issues. If the script spans multiple lines, ensure no leading spaces unless intentional.

## Example:

```bash

# RULE 1: Only chain commands with `&& \` when they work towards the same goal. Place `&& \` at the **end** of lines, not the beginning
apt-get update && \
apt-get install -y build-essential

git clone https://github.com/project/myapp.git /opt/myapp

# RULE 2: Use blank `\` lines to separate major logical sections within a command chain
cd /opt/myapp/backend && \
    ./autogen.sh && \
    \
    ./configure \
        --prefix=/usr/local \
        --enable-optimization \
        --with-ssl && \
    \
    make -j$(nproc) && \
    make install

# RULE 3: Indent subsequent commands +1 after context changes (like `cd`)
cd /opt/myapp && \
    git checkout release-2.0 && \
    git submodule update --init --recursive

# RULE 4: Align pipes `|` and redirections vertically with +1 indentation
cd /opt/myapp && \
    find . -name "*.log" \
        | xargs grep "ERROR" \
        | sort \
        | uniq -c \
        > /var/log/build-errors.txt

ls -lh /opt/myapp/build/ \
    | awk '{print $5, $9}' \
    | column -t \
    > /var/log/build-artifacts.txt

# RULE 5: Identify the "leading" vs "tail" parts of commands. The leading part (command + essential flags) stays on one line and is unbreakable. The tail part (arguments, packages, files) can be broken into multiple lines with +1 indentation
apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    libssl-dev \
    pkg-config \
    python3 \
    python3-pip

pip install --no-cache-dir \
    -r requirements.txt \
    -r requirements-dev.txt

# RULE 6: For commands with many arguments, group related arguments strategically on the same line
ffmpeg \
    -hwaccel cuda -analyzeduration 10000000 -probesize 50000000 \
    -thread_queue_size 4096 -i input.mp4 \
    -thread_queue_size 2048 -i audio.mp3 \
    \
    -map 0:v:0 -map 0:a:0 -map 1:a:0 \
    \
    -c:v libx265 -preset veryslow -crf 18 \
    -profile:v main10 -pix_fmt yuv420p10le \
    -b:v 8M -maxrate 12M -bufsize 16M \
    \
    -c:a:0 libfdk_aac -b:a:0 128k -ar:a:0 48000 \
    -c:a:1 libopus -b:a:1 96k -ar:a:1 48000 \
    \
    -metadata title="Video" -metadata artist="Author" \
    -f mp4 -y output.mp4

# RULE 7: Align similar elements vertically (redirections, operators, values). This creates columns that make patterns obvious and easier to scan
mkdir -p /root/.pip && \
pip_conf="/root/.pip/pip.conf" && \
echo "[global]"                                 >  ${pip_conf} && \
echo "trusted-host = pypi.org"                  >> ${pip_conf} && \
echo "               pypi.python.org"           >> ${pip_conf} && \
echo "               files.pythonhosted.org"    >> ${pip_conf}

# RULE 8: Maintain consistent indentation hierarchy throughout entire chain. All lines after `\` must be indented
rsync -haP /opt/myapp/dist/ /var/www/myapp/ && \
chown -R www-data:www-data /var/www/myapp && \
chmod -R 755 /var/www/myapp

cd /opt && \
    rm -rf /opt/myapp/.git && \
    rm -rf /tmp/*

# RULE 9: For inline scripts, keep indent 0
bash -c "
echo 'Updating system time'
ntpdate pool.ntp.org
echo 'Time updated'
"

python3 -c "
import sys
print('Python version:', sys.version)
for i in range(3):
    print(f'Count: {i}')
"
```