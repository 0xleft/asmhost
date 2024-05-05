set -e

echo "Installing asmhost..."

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

if ! [ -x "$(command -v wget)" ]; then
  echo "Error: wget is not installed. Please install."
  exit 1
fi

wget https://github.com/0xleft/asmhost/releases/latest/download/asmhost -O /usr/bin/asmhost
chmod +x /usr/bin/asmhost
echo "Asmhost installed in /usr/bin/asmhost"